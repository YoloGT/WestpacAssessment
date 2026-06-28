//
//  MockGitHubRepositoryClient.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Foundation

final class MockGitHubRepositoryClient: GitHubRepositoryServing {
    enum Scenario: String {
        case populated
        case empty
        case rateLimited
        case networkError

        init(rawValue: String?) {
            self = rawValue.flatMap(Scenario.init(rawValue:)) ?? .populated
        }
    }

    private let scenario: Scenario

    init(scenario: Scenario = .populated) {
        self.scenario = scenario
    }

    func fetchRepositories(from url: URL?) async throws -> RepositoryPage {
        try await Task.sleep(for: .milliseconds(50))

        switch scenario {
        case .populated:
            if url == GitHubRepositoryMockData.secondPageURL {
                return RepositoryPage(repositories: GitHubRepositoryMockData.secondPageRepositories, nextURL: nil)
            }

            return RepositoryPage(
                repositories: GitHubRepositoryMockData.firstPageRepositories,
                nextURL: GitHubRepositoryMockData.secondPageURL
            )
        case .empty:
            return RepositoryPage(repositories: [], nextURL: nil)
        case .rateLimited:
            throw GitHubAPIError.rateLimited(resetDate: Date(timeIntervalSince1970: 1_782_639_600))
        case .networkError:
            throw URLError(.notConnectedToInternet)
        }
    }

    func fetchRepositoryDetails(from url: URL) async throws -> GitHubRepository {
        guard let repository = GitHubRepositoryMockData.detailedRepository(for: url) else {
            throw GitHubAPIError.httpStatus(404)
        }

        return repository
    }

    func fetchLanguages(from url: URL) async throws -> RepositoryLanguages {
        GitHubRepositoryMockData.languages(for: url)
    }
}
