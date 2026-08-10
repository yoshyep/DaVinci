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
        XCTAssertFalse(app.textFields["workbench.search"].exists)
        XCTAssertTrue(app.buttons["workbench.quickLookup"].exists)
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
        XCTAssertEqual(app.staticTexts["workbench.delivery.progress"].label, "1/2")
        XCTAssertTrue(app.images["workbench.delivery.delivery-picture.completed"].exists)
        XCTAssertTrue(app.images["workbench.delivery.delivery-audio.pending"].exists)
        XCTAssertTrue(app.staticTexts["画面检查"].exists)
        XCTAssertTrue(app.staticTexts["音频检查"].exists)
    }

    func testCompletedProjectShowsCompletionAndReviewInsteadOfTemplates() {
        let app = launchWorkbench(seedCompletedProject: true)

        XCTAssertTrue(app.staticTexts["Finished Documentary"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["workbench.project.completed"].exists)
        XCTAssertEqual(app.staticTexts["workbench.project.progress"].label, "10/10")
        XCTAssertTrue(app.buttons["workbench.reviewDelivery"].exists)
        XCTAssertFalse(app.staticTexts["workbench.startWorkflow"].exists)
        XCTAssertFalse(app.buttons["workbench.template.template-interview-edit"].exists)
    }

    func testDeliveryChecklistSpeaksDistinctLocalizedCompletionStates() {
        let app = launchWorkbench(seedProject: true)

        openDeliveryChecklist(in: app)
        assertChecklistAccessibilityValues(
            in: app,
            completed: "已完成",
            pending: "待完成"
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["workbench.settings"].tap()
        app.buttons["settings.language.english"].tap()
        app.buttons["Done"].tap()

        openDeliveryChecklist(in: app)
        assertChecklistAccessibilityValues(
            in: app,
            completed: "Completed",
            pending: "Pending"
        )
    }

    func testQuickLookupEntrySelectsQuickLookupTabWithoutAcceptingDiscardedText() {
        let app = launchWorkbench()

        XCTAssertFalse(app.textFields["workbench.search"].exists)
        app.buttons["workbench.quickLookup"].tap()

        XCTAssertTrue(app.tabBars.buttons["速查"].isSelected)
        XCTAssertTrue(app.staticTexts["在本机查找动作、快捷键和故障处理。"].waitForExistence(timeout: 2))
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

    private func launchWorkbench(
        seedProject: Bool = false,
        seedCompletedProject: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetLocalData", "-skipOnboarding"]
        app.launchEnvironment["INSCENE_UI_TEST_SUITE"] = "WorkbenchNavigationUITests.\(UUID().uuidString)"
        if seedProject {
            app.launchArguments.append("-seedWorkbenchSession")
        }
        if seedCompletedProject {
            app.launchArguments.append("-seedCompletedWorkbenchSession")
        }
        app.launch()
        return app
    }

    private func openDeliveryChecklist(in app: XCUIApplication) {
        let checklist = app.buttons["project.deliveryChecklist"]
        scrollToElement(checklist, in: app)
        checklist.tap()
        XCTAssertTrue(app.staticTexts["workbench.delivery.detail"].waitForExistence(timeout: 2))
    }

    private func assertChecklistAccessibilityValues(
        in app: XCUIApplication,
        completed: String,
        pending: String
    ) {
        let picture = app.descendants(matching: .any)["workbench.delivery.row.delivery-picture"]
        let audio = app.descendants(matching: .any)["workbench.delivery.row.delivery-audio"]
        XCTAssertTrue(picture.exists)
        XCTAssertTrue(audio.exists)
        XCTAssertEqual(picture.value as? String, completed)
        XCTAssertEqual(audio.value as? String, pending)
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.exists {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
    }
}
