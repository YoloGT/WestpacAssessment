//
//  RepositoryDetailView.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import SwiftUI

struct RepositoryDetailView: View {
    let repository: GitHubRepository
    let languages: RepositoryLanguages
    @ObservedObject var viewModel: RepositoryListViewModel

    private var isBookmarked: Bool {
        viewModel.isBookmarked(repository)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(repository.fullName)
                        .font(.title2.bold())
                        .accessibilityIdentifier("repository-detail-full-name")

                    Text(repository.description ?? "No description provided.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("repository-detail-description")

                    HStack {
                        Button {
                            viewModel.toggleBookmark(repository)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isBookmarked ? "star.fill" : "star")
                                    .symbolRenderingMode(.monochrome)

                                Text(isBookmarked ? "Remove Favorite" : "Favorite")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("repository-detail-favorite-button")

                        Spacer(minLength: 0)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Repository") {
                LabeledContent("Owner", value: repository.owner.login)
                    .accessibilityIdentifier("repository-detail-owner")
                LabeledContent("Owner type", value: repository.owner.type.displayName)
                    .accessibilityIdentifier("repository-detail-owner-type")
                LabeledContent("Fork status", value: repository.isFork ? "Fork" : "Source repository")
                    .accessibilityIdentifier("repository-detail-fork-status")
                LabeledContent("Stars", value: "\(repository.stargazersCount)")
                    .accessibilityIdentifier("repository-detail-stars")

                if !languages.all.isEmpty {
                    LabeledContent("Languages", value: languages.all.joined(separator: ", "))
                        .accessibilityIdentifier("repository-detail-languages")
                }

                Link(destination: repository.htmlURL) {
                    Label("Open on GitHub", systemImage: "safari")
                }
                .accessibilityIdentifier("repository-detail-open-github-link")
            }
        }
        .navigationTitle(repository.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
