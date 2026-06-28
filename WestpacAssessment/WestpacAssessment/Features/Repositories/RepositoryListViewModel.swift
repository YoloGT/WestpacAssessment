//
//  RepositoryListViewModel.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Combine
import Foundation

@MainActor
final class RepositoryListViewModel: ObservableObject {
    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var sections: [RepositorySection] = []
    @Published private(set) var isInitialLoading = false
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var apiSource: RepositoryAPISource
    @Published var grouping: RepositoryGrouping = .ownerType {
        didSet { rebuildSections() }
    }
    @Published var errorMessage: String?

    private var client: GitHubRepositoryServing
    let bookmarkStore: BookmarkStore
    private var nextURL: URL?
    private var hasLoadedInitialPage = false
    private var languageByRepositoryID: [Int: RepositoryLanguages] = [:]
    private var metadataTasks: Set<Int> = []

    init(
        client: GitHubRepositoryServing? = nil,
        apiSource: RepositoryAPISource = .gitHub,
        bookmarkStore: BookmarkStore
    ) {
        self.apiSource = apiSource
        self.client = client ?? apiSource.makeClient()
        self.bookmarkStore = bookmarkStore
    }

    func switchAPISource(to source: RepositoryAPISource) async {
        guard source != apiSource else { return }
        apiSource = source
        client = source.makeClient()
        await refresh()
    }

    var canLoadMore: Bool {
        nextURL != nil
    }

    func loadInitialRepositories() async {
        guard !hasLoadedInitialPage else { return }
        hasLoadedInitialPage = true
        isInitialLoading = true
        defer { isInitialLoading = false }

        await loadPage(from: nil)
    }

    func refresh() async {
        hasLoadedInitialPage = true
        repositories = []
        sections = []
        nextURL = nil
        languageByRepositoryID = [:]
        metadataTasks = []
        isInitialLoading = true
        defer { isInitialLoading = false }

        await loadPage(from: nil)
    }

    func loadNextPage() async {
        guard let nextURL, !isLoadingNextPage else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }
        await loadPage(from: nextURL)
    }

    func toggleBookmark(_ repository: GitHubRepository) {
        bookmarkStore.toggle(repository)
        objectWillChange.send()
    }

    func isBookmarked(_ repository: GitHubRepository) -> Bool {
        bookmarkStore.isBookmarked(repository)
    }

    func languages(for repository: GitHubRepository) -> RepositoryLanguages {
        languageByRepositoryID[repository.id] ?? RepositoryLanguages(
            primary: repository.language,
            all: repository.language.map { [$0] } ?? []
        )
    }

    private func loadPage(from url: URL?) async {
        do {
            errorMessage = nil
            let page = try await client.fetchRepositories(from: url)
            repositories.append(contentsOf: page.repositories)
            nextURL = page.nextURL
            rebuildSections()
            await prefetchRepositoryMetadata(for: page.repositories)
        } catch {
            if let apiError = error as? GitHubAPIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Could not connect to GitHub. Check your connection and try again."
            }
        }
    }

    private func prefetchRepositoryMetadata(for repositories: [GitHubRepository]) async {
        await withTaskGroup(of: RepositoryMetadata?.self) { group in
            for repository in repositories.prefix(12) where metadataTasks.insert(repository.id).inserted {
                group.addTask { [client] in
                    async let details = try? client.fetchRepositoryDetails(from: repository.apiURL)
                    async let languages = try? client.fetchLanguages(from: repository.languagesURL)
                    return await RepositoryMetadata(
                        repositoryID: repository.id,
                        details: details,
                        languages: languages
                    )
                }
            }

            for await result in group {
                guard let result else { continue }
                if let details = result.details,
                   let index = self.repositories.firstIndex(where: { $0.id == result.repositoryID }) {
                    self.repositories[index] = self.repositories[index].mergingMetadata(from: details)
                }

                if let languages = result.languages {
                    languageByRepositoryID[result.repositoryID] = languages
                }
            }
        }
        rebuildSections()
    }

    private func rebuildSections() {
        sections = Self.group(repositories, by: grouping, languages: languageByRepositoryID)
    }

    static func group(
        _ repositories: [GitHubRepository],
        by grouping: RepositoryGrouping,
        languages: [Int: RepositoryLanguages]
    ) -> [RepositorySection] {
        let grouped: [String: [GitHubRepository]]

        switch grouping {
        case .ownerType:
            grouped = Dictionary(grouping: repositories) { $0.owner.type.displayName }
            return sortedSections(grouped)
        case .forkStatus:
            grouped = Dictionary(grouping: repositories) { $0.isFork ? "Forks" : "Source repositories" }
            return sortedSections(grouped, preferredOrder: ["Source repositories", "Forks"])
        case .language:
            grouped = Dictionary(grouping: repositories) { repository in
                languages[repository.id]?.primary ?? repository.language ?? "Unknown language"
            }
            return sortedSections(grouped)
        case .stars:
            grouped = Dictionary(grouping: repositories) { StarBand(count: $0.stargazersCount).rawValue }
            return sortedSections(grouped, preferredOrder: StarBand.displayOrder.map(\.rawValue))
        }
    }

    private static func sortedSections(
        _ grouped: [String: [GitHubRepository]],
        preferredOrder: [String] = []
    ) -> [RepositorySection] {
        grouped
            .map { title, repositories in
                RepositorySection(title: title, repositories: repositories.sorted { $0.fullName < $1.fullName })
            }
            .sorted { lhs, rhs in
                let lhsIndex = preferredOrder.firstIndex(of: lhs.title) ?? Int.max
                let rhsIndex = preferredOrder.firstIndex(of: rhs.title) ?? Int.max
                if lhsIndex == rhsIndex {
                    return lhs.title < rhs.title
                }
                return lhsIndex < rhsIndex
            }
    }
}

private struct RepositoryMetadata {
    let repositoryID: Int
    let details: GitHubRepository?
    let languages: RepositoryLanguages?
}

enum RepositoryAPISource: String, CaseIterable, Identifiable {
    case gitHub = "GitHub"
    case wireMock = "WireMock"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .gitHub:
            "network"
        case .wireMock:
            "server.rack"
        }
    }

    func makeClient() -> GitHubRepositoryServing {
        switch self {
        case .gitHub:
            GitHubAPIClient()
        case .wireMock:
            GitHubAPIClient(repositoriesURL: URL(string: "http://127.0.0.1:8080/repositories")!)
        }
    }
}
