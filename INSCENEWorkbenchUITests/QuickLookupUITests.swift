import XCTest

final class QuickLookupUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testChineseAndEnglishQueriesOpenTheSameStableShortcut() {
        let chineseApp = launchLookup()
        search("波纹删除", in: chineseApp)
        XCTAssertTrue(chineseApp.buttons["lookup.result.delete-ripple"].waitForExistence(timeout: 2))
        chineseApp.terminate()

        let englishApp = launchLookup(language: "en")
        search("ripple delete", in: englishApp)
        XCTAssertTrue(englishApp.buttons["lookup.result.delete-ripple"].waitForExistence(timeout: 2))
    }

    func testMacWindowsSwitchUpdatesClickableKeycapsAndDetail() {
        let app = launchLookup()
        search("波纹删除", in: app)

        app.buttons["lookup.result.delete-ripple"].tap()
        XCTAssertTrue(app.staticTexts["lookup.shortcut.detail"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["lookup.keycaps.delete-ripple"].label.contains("Delete"))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["lookup.platform.windows"].tap()
        app.buttons["lookup.result.delete-ripple"].tap()
        XCTAssertTrue(app.buttons["lookup.keycaps.delete-ripple"].label.contains("Backspace"))
    }

    func testTypeFilterKeepsRecipeAndOpensNativeDetail() {
        let app = launchLookup()
        search("肤色", in: app)

        app.buttons["lookup.filter.recipe"].tap()

        XCTAssertTrue(app.buttons["lookup.result.recipe-skin"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["lookup.result.color-skin"].exists)
        app.buttons["lookup.result.recipe-skin"].tap()
        XCTAssertTrue(app.staticTexts["lookup.record.detail"].waitForExistence(timeout: 2))
    }

    func testGenericDetailRelatedShortcutUsesClickableKeycapsAndTypedNavigation() {
        let app = launchLookup()
        search("肤色", in: app)
        app.buttons["lookup.filter.recipe"].tap()
        app.buttons["lookup.result.recipe-skin"].tap()
        XCTAssertTrue(app.staticTexts["lookup.record.detail"].waitForExistence(timeout: 2))

        let related = app.buttons["lookup.related.highlight-toggle"]
        XCTAssertTrue(related.waitForExistence(timeout: 2))
        XCTAssertTrue(related.label.contains("高亮显示模式"))
        related.tap()

        XCTAssertTrue(app.staticTexts["lookup.shortcut.detail"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["lookup.keycaps.highlight-toggle"].exists)
    }

    private func launchLookup(language: String = "zhHans") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting", "-resetLocalData", "-skipOnboarding", "-startQuickLookup",
            "-lookupLanguage", language
        ]
        app.launchEnvironment["INSCENE_UI_TEST_SUITE"] = "QuickLookupUITests.\(UUID().uuidString)"
        app.launch()
        return app
    }

    private func search(_ query: String, in app: XCUIApplication) {
        let field = app.textFields["lookup.search"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText(query)
    }
}
