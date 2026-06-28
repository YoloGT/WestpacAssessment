//
//  GitHubRepositoryMockData.swift
//  WestpacAssessment
//
//  Created by Gao Ting on 26/06/2026.
//

import Foundation

enum GitHubRepositoryMockData {
    static let firstPageURL = URL(string: "https://api.github.com/repositories")!
    static let secondPageURL = URL(string: "https://api.github.com/repositories?since=28")!

    static let firstPageJSON = """
    [
      {
        "id": 1,
        "node_id": "MDEwOlJlcG9zaXRvcnkx",
        "name": "grit",
        "full_name": "mojombo/grit",
        "private": false,
        "owner": {
          "login": "mojombo",
          "id": 1,
          "node_id": "MDQ6VXNlcjE=",
          "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/mojombo/grit",
        "description": "**Grit is no longer maintained. Check out libgit2/rugged.** Grit gives you object oriented read/write access to Git repositories via Ruby.",
        "fork": false,
        "url": "https://api.github.com/repos/mojombo/grit",
        "languages_url": "https://api.github.com/repos/mojombo/grit/languages",
        "stargazers_count": 2100,
        "language": "Ruby"
      },
      {
        "id": 26,
        "node_id": "MDEwOlJlcG9zaXRvcnkyNg==",
        "name": "merb-core",
        "full_name": "wycats/merb-core",
        "private": false,
        "owner": {
          "login": "wycats",
          "id": 4,
          "node_id": "MDQ6VXNlcjQ=",
          "avatar_url": "https://avatars.githubusercontent.com/u/4?v=4",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/wycats/merb-core",
        "description": "Merb Core: All you need. None you don't.",
        "fork": false,
        "url": "https://api.github.com/repos/wycats/merb-core",
        "languages_url": "https://api.github.com/repos/wycats/merb-core/languages",
        "stargazers_count": 790,
        "language": "Ruby"
      },
      {
        "id": 27,
        "node_id": "MDEwOlJlcG9zaXRvcnkyNw==",
        "name": "rubinius",
        "full_name": "rubinius/rubinius",
        "private": false,
        "owner": {
          "login": "rubinius",
          "id": 317747,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjMxNzc0Nw==",
          "avatar_url": "https://avatars.githubusercontent.com/u/317747?v=4",
          "type": "Organization",
          "site_admin": false
        },
        "html_url": "https://github.com/rubinius/rubinius",
        "description": "The Rubinius Language Platform",
        "fork": false,
        "url": "https://api.github.com/repos/rubinius/rubinius",
        "languages_url": "https://api.github.com/repos/rubinius/rubinius/languages",
        "stargazers_count": 5500,
        "language": "C++"
      },
      {
        "id": 28,
        "node_id": "MDEwOlJlcG9zaXRvcnkyOA==",
        "name": "god",
        "full_name": "mojombo/god",
        "private": false,
        "owner": {
          "login": "mojombo",
          "id": 1,
          "node_id": "MDQ6VXNlcjE=",
          "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/mojombo/god",
        "description": "Ruby process monitor.",
        "fork": true,
        "url": "https://api.github.com/repos/mojombo/god",
        "languages_url": "https://api.github.com/repos/mojombo/god/languages",
        "stargazers_count": 1050,
        "language": "Ruby"
      }
    ]
    """

    static let secondPageJSON = """
    [
      {
        "id": 29,
        "name": "github-services",
        "full_name": "github/github-services",
        "owner": {
          "login": "github",
          "avatar_url": "https://avatars.githubusercontent.com/u/9919?v=4",
          "type": "Organization"
        },
        "html_url": "https://github.com/github/github-services",
        "description": "Service hooks for GitHub repositories.",
        "fork": false,
        "url": "https://api.github.com/repos/github/github-services",
        "languages_url": "https://api.github.com/repos/github/github-services/languages",
        "stargazers_count": 1400,
        "language": "Ruby"
      }
    ]
    """

    static var firstPageRepositories: [GitHubRepository] {
        decodeRepositories(from: firstPageJSON)
    }

    static var secondPageRepositories: [GitHubRepository] {
        decodeRepositories(from: secondPageJSON)
    }

    static var allRepositories: [GitHubRepository] {
        firstPageRepositories + secondPageRepositories
    }

    static func detailedRepository(for url: URL) -> GitHubRepository? {
        guard let repository = allRepositories.first(where: { $0.apiURL == url }) else { return nil }

        let metadata = repositoryMetadata[repository.id] ?? RepositoryExtraMetadata(stars: 0, language: repository.language)
        return GitHubRepository(
            id: repository.id,
            name: repository.name,
            fullName: repository.fullName,
            owner: repository.owner,
            description: repository.description,
            isFork: repository.isFork,
            apiURL: repository.apiURL,
            htmlURL: repository.htmlURL,
            stargazersCount: metadata.stars,
            language: metadata.language,
            languagesURL: repository.languagesURL
        )
    }

    static func languages(for url: URL) -> RepositoryLanguages {
        guard
            let repository = allRepositories.first(where: { $0.languagesURL == url }),
            let languages = repositoryLanguages[repository.id]
        else {
            return .empty
        }

        return languages
    }

    private static func decodeRepositories(from json: String) -> [GitHubRepository] {
        do {
            return try JSONDecoder().decode([GitHubRepository].self, from: Data(json.utf8))
        } catch {
            assertionFailure("Mock repository JSON must stay decodable: \(error)")
            return []
        }
    }

    private static let repositoryMetadata: [Int: RepositoryExtraMetadata] = [
        1: RepositoryExtraMetadata(stars: 2_100, language: "Ruby"),
        26: RepositoryExtraMetadata(stars: 790, language: "Ruby"),
        27: RepositoryExtraMetadata(stars: 5_500, language: "Ruby"),
        28: RepositoryExtraMetadata(stars: 1_050, language: "Ruby"),
        29: RepositoryExtraMetadata(stars: 1_400, language: "Ruby")
    ]

    private static let repositoryLanguages: [Int: RepositoryLanguages] = [
        1: RepositoryLanguages(primary: "Ruby", all: ["Ruby", "C"]),
        26: RepositoryLanguages(primary: "Ruby", all: ["Ruby", "JavaScript"]),
        27: RepositoryLanguages(primary: "C++", all: ["C++", "Ruby", "C"]),
        28: RepositoryLanguages(primary: "Ruby", all: ["Ruby"]),
        29: RepositoryLanguages(primary: "Ruby", all: ["Ruby", "Shell"])
    ]
}

private struct RepositoryExtraMetadata {
    let stars: Int
    let language: String?
}
