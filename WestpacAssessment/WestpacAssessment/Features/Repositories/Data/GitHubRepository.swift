//
//  GitHubRepository.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Foundation

struct GitHubRepository: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let fullName: String
    let owner: RepositoryOwner
    let description: String?
    let isFork: Bool
    let apiURL: URL
    let htmlURL: URL
    let stargazersCount: Int
    let language: String?
    let languagesURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case description
        case isFork = "fork"
        case apiURL = "url"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case language
        case languagesURL = "languages_url"
    }

    init(
        id: Int,
        name: String,
        fullName: String,
        owner: RepositoryOwner,
        description: String?,
        isFork: Bool,
        apiURL: URL,
        htmlURL: URL,
        stargazersCount: Int = 0,
        language: String? = nil,
        languagesURL: URL
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.owner = owner
        self.description = description
        self.isFork = isFork
        self.apiURL = apiURL
        self.htmlURL = htmlURL
        self.stargazersCount = stargazersCount
        self.language = language
        self.languagesURL = languagesURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        fullName = try container.decode(String.self, forKey: .fullName)
        owner = try container.decode(RepositoryOwner.self, forKey: .owner)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isFork = try container.decode(Bool.self, forKey: .isFork)
        apiURL = try container.decode(URL.self, forKey: .apiURL)
        htmlURL = try container.decode(URL.self, forKey: .htmlURL)
        stargazersCount = try container.decodeIfPresent(Int.self, forKey: .stargazersCount) ?? 0
        language = try container.decodeIfPresent(String.self, forKey: .language)
        languagesURL = try container.decode(URL.self, forKey: .languagesURL)
    }

    func mergingMetadata(from detailedRepository: GitHubRepository) -> GitHubRepository {
        GitHubRepository(
            id: id,
            name: name,
            fullName: fullName,
            owner: owner,
            description: detailedRepository.description ?? description,
            isFork: isFork,
            apiURL: apiURL,
            htmlURL: htmlURL,
            stargazersCount: detailedRepository.stargazersCount,
            language: detailedRepository.language ?? language,
            languagesURL: languagesURL
        )
    }
}

struct RepositoryOwner: Decodable, Equatable {
    let login: String
    let avatarURL: URL
    let type: OwnerType

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case type
    }
}

enum OwnerType: String, Decodable, CaseIterable {
    case user = "User"
    case organization = "Organization"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = OwnerType(rawValue: value) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .user:
            "Users"
        case .organization:
            "Organizations"
        case .unknown:
            "Other Owners"
        }
    }
}

struct RepositoryLanguages: Equatable {
    let primary: String?
    let all: [String]

    static let empty = RepositoryLanguages(primary: nil, all: [])
}

enum RepositoryGrouping: String, CaseIterable, Identifiable {
    case ownerType = "Owner"
    case forkStatus = "Fork"
    case language = "Language"
    case stars = "Stars"

    var id: String { rawValue }
}

struct RepositorySection: Identifiable, Equatable {
    let title: String
    let repositories: [GitHubRepository]

    var id: String { title }
}

enum StarBand: String {
    case zero = "0 stars"
    case low = "1-99 stars"
    case medium = "100-999 stars"
    case high = "1k-9.9k stars"
    case veryHigh = "10k+ stars"

    init(count: Int) {
        switch count {
        case 0:
            self = .zero
        case 1..<100:
            self = .low
        case 100..<1_000:
            self = .medium
        case 1_000..<10_000:
            self = .high
        default:
            self = .veryHigh
        }
    }

    static let displayOrder: [StarBand] = [.veryHigh, .high, .medium, .low, .zero]
}
