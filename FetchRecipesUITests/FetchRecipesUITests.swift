//
//  FetchRecipesUITests.swift
//  FetchRecipesUITests
//
//  Created by SeanHuang on 1/17/25.
//

import XCTest

final class FetchRecipesUITests: XCTestCase {
    var app : XCUIApplication!
    static var launched = false
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        //app.activate()
//        if (!Self.launched) {
//            app = XCUIApplication()
//            app.launch()
//            Self.launched = true
//        }


        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMockService() throws {
        app.launchArguments = ["--mock"]
        app.launch()
        // UI tests must launch the application that they test.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }
    
    func testProductionService() async throws {
        app.launchArguments = ["--production"]
        
    }
    
    @MainActor
    func testMalformedService() throws {
        app.launchArguments = ["--malformed"]
        app.launch()
        // UI tests must launch the application that they test.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }
    @MainActor
    func testLargeMockService() throws {
        app.launchArguments = ["--2000_mock"]
        app.launch()
        // UI tests must launch the application that they test.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
