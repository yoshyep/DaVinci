import XCTest

final class AccessibilitySmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Four Tabs

    func testFourTabsAreAccessible() {
        let app = launchApp()

        XCTAssertTrue(app.tabBars.buttons["工作台"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars.buttons["速查"].exists)
        XCTAssertTrue(app.tabBars.buttons["工作流"].exists)
        XCTAssertTrue(app.tabBars.buttons["资料库"].exists)

        for button in app.tabBars.buttons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "Tab button has empty accessibility label")
        }
    }

    func testLibraryTabOpensAndShowsContent() {
        let app = launchApp()

        app.tabBars.buttons["资料库"].tap()
        XCTAssertTrue(app.textFields["library.search"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["library.filter.all"].exists)
        XCTAssertTrue(app.buttons["library.filter.stages"].exists)
        XCTAssertTrue(app.buttons["library.filter.playbooks"].exists)
        XCTAssertTrue(app.buttons["library.filter.shortcuts"].exists)
    }

    // MARK: - Settings Accessibility

    func testSettingsControlsAreAccessible() {
        let app = launchApp()

        app.buttons["workbench.settings"].tap()
        XCTAssertTrue(app.images["brand.horizontal"].waitForExistence(timeout: 2))

        let exportButton = app.buttons["settings.export"]
        scrollToElement(exportButton, in: app)
        XCTAssertTrue(exportButton.exists)
        XCTAssertFalse(exportButton.label.isEmpty)

        XCTAssertTrue(app.buttons["settings.import"].exists)
        XCTAssertTrue(app.buttons["settings.clearHistory"].exists)
        XCTAssertTrue(app.buttons["settings.resetProgress"].exists)
        XCTAssertTrue(app.buttons["settings.deleteAll"].exists)
    }

    func testSettingsLanguageSwitchButtonsAreAccessible() {
        let app = launchApp()

        app.buttons["workbench.settings"].tap()

        let zhButton = app.buttons["settings.language.zhHans"]
        let enButton = app.buttons["settings.language.english"]
        XCTAssertTrue(zhButton.waitForExistence(timeout: 2))
        XCTAssertTrue(enButton.exists)
        XCTAssertFalse(zhButton.label.isEmpty)
        XCTAssertFalse(enButton.label.isEmpty)
    }

    // MARK: - Workbench Quick Tools

    func testWorkbenchImmediateToolsAreAccessible() {
        let app = launchApp()

        let tools: [(String, String)] = [
            ("quick.deleteSegment", "波纹删除"),
            ("quick.skinCorrection", "肤色校正"),
            ("quick.exportSettings", "导出设置"),
            ("quick.emergency", "故障急救")
        ]

        for (identifier, _) in tools {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Tool \(identifier) does not exist")
            XCTAssertFalse(button.label.isEmpty, "Tool \(identifier) has empty label")
        }
    }

    // MARK: - Workflow with Project

    func testWorkflowProjectControlsAreAccessible() {
        let app = launchApp(seedProject: true)

        app.tabBars.buttons["工作流"].tap()

        let projectRow = app.staticTexts["Interview Cut"]
        XCTAssertTrue(projectRow.waitForExistence(timeout: 2), "Seeded project 'Interview Cut' should appear in the workflows list")
        projectRow.tap()

        let stageButton = app.buttons["workflows.project.stage.1"]
        XCTAssertTrue(stageButton.waitForExistence(timeout: 2), "Stage 1 button should exist in the project session view")
        XCTAssertFalse(stageButton.label.isEmpty, "Stage 1 button has empty label")
    }

    // MARK: - Shortcut Detail

    func testShortcutDetailControlsAreAccessible() {
        let app = launchApp()

        app.buttons["workbench.quickLookup"].tap()
        XCTAssertTrue(app.textFields["lookup.search"].waitForExistence(timeout: 2))

        app.textFields["lookup.search"].tap()
        app.textFields["lookup.search"].typeText("delete")
        if app.keyboards.buttons["Search"].exists {
            app.keyboards.buttons["Search"].tap()
        }

        let firstResult = app.buttons["lookup.result.delete-ripple"]
        XCTAssertTrue(firstResult.waitForExistence(timeout: 5), "Search result should appear")
        XCTAssertFalse(firstResult.label.isEmpty, "Search result has empty label")
    }

    // MARK: - Library Content Detail

    func testLibraryContentDetailControlsAreAccessible() {
        let app = launchApp()

        app.tabBars.buttons["资料库"].tap()
        XCTAssertTrue(app.textFields["library.search"].waitForExistence(timeout: 2))

        // Verify filter buttons are accessible
        XCTAssertTrue(app.buttons["library.filter.all"].exists)
        XCTAssertTrue(app.buttons["library.filter.stages"].exists)
        XCTAssertTrue(app.buttons["library.filter.playbooks"].exists)
        XCTAssertTrue(app.buttons["library.filter.shortcuts"].exists)
        XCTAssertFalse(app.buttons["library.filter.stages"].label.isEmpty)

        // Tap stages filter and verify content appears
        app.buttons["library.filter.stages"].tap()

        let firstItem = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.item.'")
        ).firstMatch
        XCTAssertTrue(firstItem.waitForExistence(timeout: 3), "A library content item should appear after filtering by stages")
        XCTAssertFalse(firstItem.label.isEmpty, "Library item has empty accessibility label")
    }

    // MARK: - Settings Import/Export Buttons

    func testImportExportButtonsAreEnabled() {
        let app = launchApp()

        app.buttons["workbench.settings"].tap()

        let exportButton = app.buttons["settings.export"]
        scrollToElement(exportButton, in: app)
        XCTAssertTrue(exportButton.exists)
        XCTAssertTrue(exportButton.isEnabled, "Export button should be enabled")

        XCTAssertTrue(app.buttons["settings.import"].isEnabled, "Import button should be enabled")
    }

    // MARK: - Destructive Action Confirmation

    func testDeleteAllShowsConfirmation() {
        let app = launchApp()

        app.buttons["workbench.settings"].tap()

        let deleteButton = app.buttons["settings.deleteAll"]
        scrollToElement(deleteButton, in: app)
        deleteButton.tap()

        XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 2), "Confirmation alert should appear")
        XCTAssertEqual(app.alerts.buttons.count, 2, "Alert should have Cancel and Delete buttons")
    }

    // MARK: - Helpers

    private func launchApp(
        seedProject: Bool = false,
        skipOnboarding: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var args: [String] = ["-uiTesting", "-resetLocalData"]
        if skipOnboarding { args.append("-skipOnboarding") }
        if seedProject { args.append("-seedWorkbenchSession") }
        app.launchArguments = args
        app.launchEnvironment["INSCENE_UI_TEST_SUITE"] = "AccessibilitySmokeUITests.\(UUID().uuidString)"
        app.launch()
        return app
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 where !element.exists {
            app.swipeUp()
        }
        if !element.exists {
            for _ in 0..<3 {
                app.swipeDown()
                if element.exists { break }
            }
        }
    }
}
