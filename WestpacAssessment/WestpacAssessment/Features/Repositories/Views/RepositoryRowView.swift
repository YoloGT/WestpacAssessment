//
//  RepositoryRowView.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import SwiftUI

struct RepositoryRowView: View {
    let repository: GitHubRepository
    let languages: RepositoryLanguages
    let isBookmarked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(repository.fullName)
                    .font(.headline)
                    .lineLimit(2)

                if isBookmarked {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favorited")
                        .accessibilityIdentifier("repository-row-favorite-\(repository.id)")
                }
            }

            if let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Label(repository.owner.type.rawValue, systemImage: "person.crop.circle")
                Label(repository.isFork ? "Fork" : "Source", systemImage: repository.isFork ? "tuningfork" : "doc.text")
                Label("\(repository.stargazersCount)", systemImage: "star")

                if let primary = languages.primary {
                    Label(primary, systemImage: "curlybraces")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .padding(.vertical, 4)
    }
}
