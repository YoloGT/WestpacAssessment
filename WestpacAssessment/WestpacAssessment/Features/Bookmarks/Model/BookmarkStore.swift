//
//  BookmarkStore.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Combine
import Foundation

protocol Bookmarking {
    var bookmarkedIDs: Set<Int> { get }
    func isBookmarked(id: Int) -> Bool
    func toggle(id: Int)
}

final class BookmarkStore: ObservableObject, Bookmarking {
    @Published private(set) var bookmarkedIDs: Set<Int>

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "bookmarkedRepositoryIDs") {
        self.defaults = defaults
        self.key = key
        self.bookmarkedIDs = Set(defaults.array(forKey: key) as? [Int] ?? [])
    }

    func isBookmarked(id: Int) -> Bool {
        bookmarkedIDs.contains(id)
    }

    func toggle(id: Int) {
        if bookmarkedIDs.contains(id) {
            bookmarkedIDs.remove(id)
        } else {
            bookmarkedIDs.insert(id)
        }
        defaults.set(Array(bookmarkedIDs).sorted(), forKey: key)
    }
}
