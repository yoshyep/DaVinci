import XCTest

final class SettingsLocalizationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFourTabsAndLiveLanguageSwitch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetLocalData", "-skipOnboarding"]
        app.launch()

        XCTAssertEqual(app.tabBars.buttons.count, 4)
        app.buttons["workbench.settings"].tap()
        app.buttons["settings.language.english"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars.buttons["Workbench"].exists)
        XCTAssertTrue(app.staticTexts["Settings use only local storage."].exists)
    }

    func testFirstLaunchCollectsOnlyLocalDefaults() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetLocalData"]
        app.launch()

        XCTAssertTrue(app.staticTexts["onboarding.title"].waitForExistence(timeout: 2))
        app.buttons["onboarding.language.english"].tap()
        app.buttons["onboarding.platform.mac"].tap()
        app.buttons["onboarding.level.quick"].tap()
        app.buttons["onboarding.finish"].tap()

        XCTAssertTrue(app.tabBars.buttons["Workbench"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.tabBars.buttons.count, 4)
    }
}
