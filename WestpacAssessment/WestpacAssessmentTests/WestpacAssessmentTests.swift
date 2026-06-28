//
//  WestpacAssessmentTests.swift
//  WestpacAssessmentTests
//
//  Created by Gao Ting on 26/06/2026.
//

import XCTest
@testable import WestpacAssessment

@MainActor
final class WestpacAssessmentTests: XCTestCase {
    func testRepositoryDecodesPublicRepositoriesResponseWithoutOptionalDetailFields() throws {
        let json = """
        {
          "id": 1,
          "name": "grit",
          "full_name": "mojombo/grit",
          "owner": {
            "login": "mojombo",
            "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4",
            "type": "User"
          },
          "html_url": "https://github.com/mojombo/grit",
          "description": "Grit gives you object oriented access to Git repositories.",
          "fork": false,
          "url": "https://api.github.com/repos/mojombo/grit",
          "languages_url": "https://api.github.com/repos/mojombo/grit/languages"
        }
        """

        let repository = try JSONDecoder().decode(GitHubRepository.self, from: Data(json.utf8))

        XCTAssertEqual(repository.fullName, "mojombo/grit")
        XCTAssertEqual(repository.apiURL.absoluteString, "https://api.github.com/repos/mojombo/grit")
        XCTAssertEqual(repository.stargazersCount, 0)
        XCTAssertNil(repository.language)
    }

    func testLinkParserReturnsNextURL() throws {
        let header = """
        <https://api.github.com/repositories?since=369>; rel="next", <https://api.github.com/repositories{?since}>; rel="first"
        """

        let url = GitHubLinkParser.nextURL(from: header)

        XCTAssertEqual(url?.absoluteString, "https://api.github.com/repositories?since=369")
    }

    func testMockDataDecodesFromPublicRepositoriesResponseExample() {
        let repositories = GitHubRepositoryMockData.firstPageRepositories

        XCTAssertEqual(repositories.map(\.fullName), [
            "mojombo/grit",
            "wycats/merb-core",
            "rubinius/rubinius",
            "mojombo/god"
        ])
        XCTAssertEqual(repositories.first?.owner.type, .user)
        XCTAssertEqual(repositories.first?.languagesURL.absoluteString, "https://api.github.com/repos/mojombo/grit/languages")
    }

    func testMockClientReturnsPagedRepositoriesAndMetadata() async throws {
        let client = MockGitHubRepositoryClient()

        let firstPage = try await client.fetchRepositories(from: nil)
        let secondPage = try await client.fetchRepositories(from: firstPage.nextURL)
        let details = try await client.fetchRepositoryDetails(from: firstPage.repositories[0].apiURL)
        let languages = try await client.fetchLanguages(from: firstPage.repositories[0].languagesURL)

        XCTAssertEqual(firstPage.repositories.count, 4)
        XCTAssertEqual(firstPage.nextURL, GitHubRepositoryMockData.secondPageURL)
        XCTAssertEqual(secondPage.repositories.map(\.fullName), ["github/github-services"])
        XCTAssertEqual(details.stargazersCount, 2_100)
        XCTAssertEqual(languages.all, ["Ruby", "C"])
    }

    func testMockClientSupportsErrorStates() async {
        let client = MockGitHubRepositoryClient(scenario: .rateLimited)

        do {
            _ = try await client.fetchRepositories(from: nil)
            XCTFail("Expected rate limit error")
        } catch GitHubAPIError.rateLimited {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected rate limit error, got \(error)")
        }
    }

    func testGroupingByForkStatusUsesStableOrder() {
        let source = makeRepository(id: 1, fullName: "apple/source", isFork: false)
        let fork = makeRepository(id: 2, fullName: "apple/fork", isFork: true)

        let sections = RepositoryListViewModel.group([fork, source], by: .forkStatus, languages: [:])

        XCTAssertEqual(sections.map(\.title), ["Source repositories", "Forks"])
        XCTAssertEqual(sections.first?.repositories, [source])
    }

    func testGroupingByOwnerTypeCreatesExpectedSections() {
        let userRepository = makeRepository(id: 1, fullName: "octocat/hello", ownerType: .user)
        let organizationRepository = makeRepository(id: 2, fullName: "apple/swift", ownerType: .organization)

        let sections = RepositoryListViewModel.group(
            [organizationRepository, userRepository],
            by: .ownerType,
            languages: [:]
        )

        XCTAssertEqual(sections.map(\.title), ["Organizations", "Users"])
        XCTAssertEqual(sections.first?.repositories, [organizationRepository])
        XCTAssertEqual(sections.last?.repositories, [userRepository])
    }

    func testGroupingByLanguagePrefersFetchedLanguageMetadata() {
        let swiftRepository = makeRepository(id: 1, fullName: "apple/swift", language: "Swift")
        let metadataRepository = makeRepository(id: 2, fullName: "rubinius/rubinius", language: "Ruby")
        let unknownRepository = makeRepository(id: 3, fullName: "octocat/unknown", language: nil)

        let sections = RepositoryListViewModel.group(
            [unknownRepository, metadataRepository, swiftRepository],
            by: .language,
            languages: [
                metadataRepository.id: RepositoryLanguages(primary: "C++", all: ["C++", "Ruby"])
            ]
        )

        XCTAssertEqual(sections.map(\.title), ["C++", "Swift", "Unknown language"])
        XCTAssertEqual(sections.first?.repositories, [metadataRepository])
    }

    func testGroupingByStarsUsesBandOrder() {
        let zero = makeRepository(id: 1, fullName: "example/zero", stars: 0)
        let low = makeRepository(id: 2, fullName: "example/low", stars: 20)
        let medium = makeRepository(id: 3, fullName: "example/medium", stars: 200)
        let high = makeRepository(id: 4, fullName: "example/high", stars: 2_000)
        let veryHigh = makeRepository(id: 5, fullName: "example/very-high", stars: 20_000)

        let sections = RepositoryListViewModel.group(
            [zero, low, medium, high, veryHigh],
            by: .stars,
            languages: [:]
        )

        XCTAssertEqual(sections.map(\.title), [
            "10k+ stars",
            "1k-9.9k stars",
            "100-999 stars",
            "1-99 stars",
            "0 stars"
        ])
    }

    func testBookmarkStorePersistsIDs() {
        let suiteName = "BookmarkStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = makeRepository(id: 42)

        let store = BookmarkStore(defaults: defaults, key: "bookmarks")
        store.toggle(repository)

        XCTAssertTrue(store.isBookmarked(repository))
        XCTAssertEqual(BookmarkStore(defaults: defaults, key: "bookmarks").bookmarkedIDs, [42])
    }

    private func makeRepository(
        id: Int,
        fullName: String = "octocat/Hello-World",
        isFork: Bool = false,
        stars: Int = 5,
        language: String? = "Swift",
        ownerType: OwnerType = .user
    ) -> GitHubRepository {
        GitHubRepository(
            id: id,
            name: String(fullName.split(separator: "/").last ?? "repo"),
            fullName: fullName,
            owner: RepositoryOwner(
                login: String(fullName.split(separator: "/").first ?? "octocat"),
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!,
                type: ownerType
            ),
            description: "Test repository",
            isFork: isFork,
            apiURL: URL(string: "https://api.github.com/repos/\(fullName)")!,
            htmlURL: URL(string: "https://github.com/\(fullName)")!,
            stargazersCount: stars,
            language: language,
            languagesURL: URL(string: "https://api.github.com/repos/\(fullName)/languages")!
        )
    }
}
