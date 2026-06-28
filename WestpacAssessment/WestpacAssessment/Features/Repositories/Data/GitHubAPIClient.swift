//
//  GitHubAPIClient.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Foundation

protocol GitHubRepositoryServing {
    func fetchRepositories(from url: URL?) async throws -> RepositoryPage
    func fetchRepositoryDetails(from url: URL) async throws -> GitHubRepository
    func fetchLanguages(from url: URL) async throws -> RepositoryLanguages
}

struct RepositoryPage: Equatable {
    let repositories: [GitHubRepository]
    let nextURL: URL?
}

enum GitHubAPIError: LocalizedError, Equatable {
    case invalidResponse
    case rateLimited(resetDate: Date?)
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "GitHub returned an invalid response."
        case .rateLimited(let resetDate):
            if let resetDate {
                "GitHub rate limit reached. Try again after \(resetDate.formatted(date: .omitted, time: .shortened))."
            } else {
                "GitHub rate limit reached. Please try again later."
            }
        case .httpStatus(let status):
            "GitHub returned HTTP \(status). Please try again."
        case .decodingFailed:
            "The response from GitHub could not be read."
        }
    }
}

final class GitHubAPIClient: GitHubRepositoryServing {
    private let session: URLSession
    private let decoder: JSONDecoder
    private var repositoryCache: [URL: GitHubRepository] = [:]
    private var languageCache: [URL: RepositoryLanguages] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchRepositories(from url: URL? = nil) async throws -> RepositoryPage {
        let requestURL = url ?? URL(string: "https://api.github.com/repositories")!
        var request = URLRequest(url: requestURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WestpacAssessment", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validate(response: response)

        do {
            let repositories = try decoder.decode([GitHubRepository].self, from: data)
            let nextURL = GitHubLinkParser.nextURL(from: httpResponse.value(forHTTPHeaderField: "Link"))
            return RepositoryPage(repositories: repositories, nextURL: nextURL)
        } catch {
            throw GitHubAPIError.decodingFailed
        }
    }

    func fetchRepositoryDetails(from url: URL) async throws -> GitHubRepository {
        if let cached = repositoryCache[url] {
            return cached
        }

        let data = try await fetchData(from: url)

        do {
            let repository = try decoder.decode(GitHubRepository.self, from: data)
            repositoryCache[url] = repository
            return repository
        } catch {
            throw GitHubAPIError.decodingFailed
        }
    }

    func fetchLanguages(from url: URL) async throws -> RepositoryLanguages {
        if let cached = languageCache[url] {
            return cached
        }

        let data = try await fetchData(from: url)

        do {
            let values = try decoder.decode([String: Int].self, from: data)
            let languages = values
                .sorted { lhs, rhs in
                    if lhs.value == rhs.value {
                        return lhs.key < rhs.key
                    }
                    return lhs.value > rhs.value
                }
                .map(\.key)
            let result = RepositoryLanguages(primary: languages.first, all: languages)
            languageCache[url] = result
            return result
        } catch {
            throw GitHubAPIError.decodingFailed
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WestpacAssessment", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        _ = try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return httpResponse
        case 403:
            let resetDate = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset")
                .flatMap(TimeInterval.init)
                .map(Date.init(timeIntervalSince1970:))
            throw GitHubAPIError.rateLimited(resetDate: resetDate)
        default:
            throw GitHubAPIError.httpStatus(httpResponse.statusCode)
        }
    }
}

enum GitHubLinkParser {
    static func nextURL(from header: String?) -> URL? {
        guard let header else { return nil }

        return header
            .split(separator: ",")
            .compactMap { component -> URL? in
                let parts = component.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                guard
                    let urlPart = parts.first,
                    parts.contains(where: { $0 == "rel=\"next\"" }),
                    urlPart.hasPrefix("<"),
                    urlPart.hasSuffix(">")
                else {
                    return nil
                }

                let rawURL = urlPart.dropFirst().dropLast()
                return URL(string: String(rawURL))
            }
            .first
    }
}
