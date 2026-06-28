//
//  RepositoryBookmarking.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Foundation

extension BookmarkStore {
    func isBookmarked(_ repository: GitHubRepository) -> Bool {
        isBookmarked(id: repository.id)
    }

    func toggle(_ repository: GitHubRepository) {
        toggle(id: repository.id)
    }
}
