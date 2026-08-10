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

    func testLocalDataActionsAreClearlyUnavailableInBothLanguages() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetLocalData", "-skipOnboarding"]
        app.launch()
        app.buttons["workbench.settings"].tap()

        assertLocalDataActionsAreUnavailable(
            in: app,
            labels: ["导出本地数据", "导入本地数据", "清除最近记录", "重置项目进度", "删除全部本地数据"],
            status: "本地数据工具实现后可用。",
            confirmationTitle: "删除全部本地数据？"
        )

        scrollToElement(app.buttons["settings.language.english"], in: app, direction: .down)
        app.buttons["settings.language.english"].tap()

        assertLocalDataActionsAreUnavailable(
            in: app,
            labels: [
                "Export Local Data",
                "Import Local Data",
                "Clear Recent History",
                "Reset Project Progress",
                "Delete All Local Data"
            ],
            status: "Available when local data tools are implemented.",
            confirmationTitle: "Delete all local data?"
        )
    }

    private enum ScrollDirection { case up, down }

    private func assertLocalDataActionsAreUnavailable(
        in app: XCUIApplication,
        labels: [String],
        status: String,
        confirmationTitle: String
    ) {
        let firstAction = app.buttons[labels[0]]
        scrollToElement(firstAction, in: app, direction: .up)

        for label in labels {
            let action = app.buttons[label]
            XCTAssertTrue(action.exists, "Missing local-data action: \(label)")
            XCTAssertFalse(action.isEnabled, "Local-data action must remain disabled until Task 8: \(label)")
        }

        XCTAssertTrue(app.staticTexts[status].exists)
        XCTAssertFalse(app.staticTexts[confirmationTitle].exists)
    }

    private func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        direction: ScrollDirection
    ) {
        for _ in 0..<10 where !element.exists {
            switch direction {
            case .up: app.swipeUp()
            case .down: app.swipeDown()
            }
        }
        XCTAssertTrue(element.exists)
    }
}
