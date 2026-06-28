//
//  WestpacAssessmentUITests.swift
//  WestpacAssessmentUITests
//
//  Created by Gao Ting on 26/06/2026.
//

import XCTest

final class WestpacAssessmentUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMockRepositoriesRenderAndCanBeBookmarked() throws {
        let app = makeMockApp()
        openGritDetail(in: app)

        app.buttons["repository-detail-favorite-button"].tap()
        XCTAssertTrue(app.buttons["Remove Favorite"].waitForExistence(timeout: 2))
        app.navigationBars["grit"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.images["repository-row-favorite-1"].waitForExistence(timeout: 2))

        app.cells.containing(.staticText, identifier: "mojombo/grit").firstMatch.tap()
        app.buttons["repository-detail-favorite-button"].tap()
        XCTAssertTrue(app.buttons["Favorite"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDetailScreenShowsMockRepositorySummary() throws {
        let app = makeMockApp()
        openGritDetail(in: app)

        XCTAssertTrue(app.staticTexts["repository-detail-full-name"].exists)
        XCTAssertEqual(app.staticTexts["repository-detail-full-name"].label, "mojombo/grit")
        XCTAssertTrue(app.staticTexts["repository-detail-description"].label.contains("Grit is no longer maintained"))
        XCTAssertTrue(app.buttons["repository-detail-favorite-button"].exists)
        XCTAssertTrue(app.buttons["Favorite"].exists)
    }

    @MainActor
    func testDetailScreenShowsMockRepositoryMetadata() throws {
        let app = makeMockApp()
        openGritDetail(in: app)

        assertElement("repository-detail-owner", in: app, contains: "mojombo")
        assertElement("repository-detail-owner-type", in: app, contains: "Users")
        assertElement("repository-detail-fork-status", in: app, contains: "Source repository")
        assertElement("repository-detail-stars", in: app, contains: "2100")
        assertElement("repository-detail-languages", in: app, contains: "Ruby")
    }

    @MainActor
    func testDetailScreenHasGitHubLink() throws {
        let app = makeMockApp()
        openGritDetail(in: app)

        XCTAssertTrue(app.descendants(matching: .any)["repository-detail-open-github-link"].exists)
    }

    @MainActor
    func testGroupingByForkStatusShowsForkSections() throws {
        let app = makeMockApp()
        openMockRepositoryList(in: app)

        selectGrouping("Fork", in: app)

        XCTAssertTrue(app.staticTexts["Source repositories"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Forks"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testGroupingByLanguageShowsLanguageSections() throws {
        let app = makeMockApp()
        openMockRepositoryList(in: app)

        selectGrouping("Language", in: app)

        XCTAssertTrue(app.staticTexts["C++"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Ruby"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testGroupingByStarsShowsStarBandSections() throws {
        let app = makeMockApp()
        openMockRepositoryList(in: app)

        selectGrouping("Stars", in: app)

        XCTAssertTrue(app.staticTexts["1k-9.9k stars"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["100-999 stars"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testMockEmptyStateRendersWithoutNetwork() throws {
        let app = makeMockApp(scenario: "empty")
        app.launch()

        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No Repositories"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Retry"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = makeMockApp()
            app.launch()
        }
    }

    private func makeMockApp(scenario: String = "populated") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--mock-github"]
        app.launchEnvironment = [
            "MOCK_GITHUB_SCENARIO": scenario,
            "UITEST_RESET_BOOKMARKS": "1"
        ]
        return app
    }

    @MainActor
    private func openGritDetail(in app: XCUIApplication) {
        openMockRepositoryList(in: app)

        app.cells.containing(.staticText, identifier: "mojombo/grit").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["grit"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func openMockRepositoryList(in app: XCUIApplication) {
        app.launch()

        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["mojombo/grit"].waitForExistence(timeout: 5))
    }

    private func selectGrouping(_ grouping: String, in app: XCUIApplication) {
        app.buttons["Group repositories"].tap()
        app.buttons[grouping].tap()
    }

    private func assertElement(_ identifier: String, in app: XCUIApplication, contains text: String) {
        let element = app.descendants(matching: .any)[identifier]

        XCTAssertTrue(element.waitForExistence(timeout: 2))
        XCTAssertTrue(element.label.contains(text), "Expected \(identifier) label to contain \(text), got \(element.label)")
    }
}
