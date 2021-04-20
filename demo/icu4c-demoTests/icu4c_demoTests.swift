//
//  icu4c_demoTests.swift
//  icu4c-demoTests
//
//  Created by Alexander Pototskiy on 20.04.21.
//

import XCTest
@testable import icu4c_demo

class icu4c_demoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        XCTAssertEqual(icuToUpper("test_string"), "TEST_STRING", "wrong")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
