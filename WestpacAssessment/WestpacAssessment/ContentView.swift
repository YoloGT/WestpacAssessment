//
//  ContentView.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: RepositoryListViewModel

    init(viewModel: RepositoryListViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? Self.makeViewModel())
    }

    var body: some View {
        RepositoryListView(viewModel: viewModel)
    }

    private static func makeViewModel() -> RepositoryListViewModel {
        let processInfo = ProcessInfo.processInfo
        let defaults = UserDefaults.standard
        let bookmarkKey = processInfo.arguments.contains("--mock-github") ? "mockBookmarkedRepositoryIDs" : "bookmarkedRepositoryIDs"

        if processInfo.environment["UITEST_RESET_BOOKMARKS"] == "1" {
            defaults.removeObject(forKey: bookmarkKey)
        }

        let client: GitHubRepositoryServing
        if processInfo.arguments.contains("--mock-github") {
            client = MockGitHubRepositoryClient(
                scenario: MockGitHubRepositoryClient.Scenario(rawValue: processInfo.environment["MOCK_GITHUB_SCENARIO"])
            )
        } else {
            client = GitHubAPIClient()
        }

        return RepositoryListViewModel(
            client: client,
            bookmarkStore: BookmarkStore(defaults: defaults, key: bookmarkKey)
        )
    }
}
