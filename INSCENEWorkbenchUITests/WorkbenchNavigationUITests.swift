import XCTest

final class WorkbenchNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWorkbenchShowsToolFirstHierarchyWithoutPhotography() {
        let app = launchWorkbench()

        XCTAssertFalse(app.images["workbench.hero.cover"].exists)
        XCTAssertTrue(app.images["brand.symbol"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["workbench.settings"].exists)
        XCTAssertTrue(app.textFields["workbench.search"].exists)
        XCTAssertTrue(app.buttons["quick.deleteSegment"].exists)
        XCTAssertTrue(app.buttons["quick.skinCorrection"].exists)
        XCTAssertTrue(app.buttons["quick.exportSettings"].exists)
        XCTAssertTrue(app.buttons["quick.emergency"].exists)
    }

    func testWorkbenchResumesCurrentStageAndOpensDeliveryChecklist() {
        let app = launchWorkbench(seedProject: true)

        let continueButton = app.buttons["workbench.continue"]
        scrollToElement(continueButton, in: app)
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["workbench.stage.detail"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let checklist = app.buttons["project.deliveryChecklist"]
        scrollToElement(checklist, in: app)
        checklist.tap()
        XCTAssertTrue(app.staticTexts["workbench.delivery.detail"].waitForExistence(timeout: 2))
    }

    func testImmediateToolOpensTypedNativeDetail() {
        let app = launchWorkbench()

        app.buttons["quick.deleteSegment"].tap()

        XCTAssertTrue(app.staticTexts["workbench.quick.detail"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Shift + Delete"].exists)
    }

    func testSettingsGearOpensSettings() {
        let app = launchWorkbench()

        app.buttons["workbench.settings"].tap()

        XCTAssertTrue(app.images["brand.horizontal"].waitForExistence(timeout: 2))
    }

    private func launchWorkbench(seedProject: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetLocalData", "-skipOnboarding"]
        if seedProject {
            app.launchArguments.append("-seedWorkbenchSession")
        }
        app.launch()
        return app
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.exists {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
    }
}
