//
//  RepositoryListView.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import SwiftUI

struct RepositoryListView: View {
    @ObservedObject var viewModel: RepositoryListViewModel

    var body: some View {
        NavigationStack {
            repositoryList
                .navigationTitle("GitHub Repos")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            ForEach(RepositoryAPISource.allCases) { source in
                                Button {
                                    Task { await viewModel.switchAPISource(to: source) }
                                } label: {
                                    if viewModel.apiSource == source {
                                        Label(source.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(source.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Label(viewModel.apiSource.rawValue, systemImage: viewModel.apiSource.systemImage)
                        }
                        .accessibilityLabel("API Source")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(RepositoryGrouping.allCases) { grouping in
                                Button {
                                    viewModel.grouping = grouping
                                } label: {
                                    if viewModel.grouping == grouping {
                                        Label(grouping.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(grouping.rawValue)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Group repositories")
                    }
                }
                .task {
                    await viewModel.loadInitialRepositories()
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .alert("Something went wrong", isPresented: Binding(
                    get: { viewModel.errorMessage != nil && !viewModel.repositories.isEmpty },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { viewModel.errorMessage = nil }
                    Button("Retry") {
                        Task { await viewModel.refresh() }
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    private var repositoryList: some View {
        List {
            if !viewModel.repositories.isEmpty {
                ForEach(viewModel.sections) { section in
                    Section(section.title) {
                        ForEach(section.repositories) { repository in
                            NavigationLink {
                                RepositoryDetailView(
                                    repository: repository,
                                    languages: viewModel.languages(for: repository),
                                    viewModel: viewModel
                                )
                            } label: {
                                RepositoryRowView(
                                    repository: repository,
                                    languages: viewModel.languages(for: repository),
                                    isBookmarked: viewModel.isBookmarked(repository)
                                )
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.toggleBookmark(repository)
                                } label: {
                                    Label(
                                        viewModel.isBookmarked(repository) ? "Remove Favorite" : "Favorite",
                                        systemImage: viewModel.isBookmarked(repository) ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                }

                if viewModel.canLoadMore {
                    HStack {
                        Spacer()
                        ProgressView("Loading more")
                            .accessibilityIdentifier("repository-list-loading-more")

                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .task {
                        await viewModel.loadNextPage()
                    }
                }
            }
        }
        .overlay {
            if viewModel.isInitialLoading && viewModel.repositories.isEmpty {
                ContentUnavailableView {
                    ProgressView()
                } description: {
                    Text("Loading public repositories")
                }
            } else if viewModel.repositories.isEmpty {
                EmptyRepositoryView(errorMessage: viewModel.errorMessage) {
                    Task { await viewModel.refresh() }
                }
            }
        }
    }
}

private struct EmptyRepositoryView: View {
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Repositories", systemImage: "tray")
        } description: {
            Text(errorMessage ?? "Pull to refresh or try again.")
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
