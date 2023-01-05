//
//  File.swift
//  
//
//  Created by Michael Long on 1/3/23.
//

import Foundation
import XCTest
@testable import Factory

extension XCTestCase {

    func expectFatalError(expectedMessage: String, testcase: @escaping () -> Void) {
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String = ""

        triggerFatalError = { (message, _, _) in
            assertionMessage = message()
            DispatchQueue.main.async {
                expectation.fulfill()
            }
            Thread.exit()
            Swift.fatalError("will never be executed since thread exits")
        }

        Thread(block: testcase).start()

        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertEqual(expectedMessage, assertionMessage)
            triggerFatalError = Swift.fatalError
        }
    }
    
}
