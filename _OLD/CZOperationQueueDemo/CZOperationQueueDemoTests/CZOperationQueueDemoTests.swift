//
//  CZOperationQueueDemoTests.swift
//  CZOperationQueueDemoTests
//
//  Created by Cheng Zhang on 8/8/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import XCTest
@testable import CZOperationQueueDemo

class CZOperationQueueDemoTests: XCTestCase {
    private var testDataManager: TestDataManager!
    private var gpOperationQueue: CZOperationQueue?

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGroup() {
        (0...10).forEach{_ in testBasic() }
    }

    /// Test priority, dependency
    func testBasic() {
        testDataManager = TestDataManager()
        gpOperationQueue = CZOperationQueue()
        gpOperationQueue?.maxConcurrentOperationCount = 3

        let sleepInterval: TimeInterval = 0.01
        let operations = (0...10).map {TestOperation($0, sleepInterval: sleepInterval, testDataManager: testDataManager)}
        // Set priorities
        operations[0].queuePriority = .veryLow
        operations[1].queuePriority = .low
        operations[6].queuePriority = .veryHigh
        // Set dependencies
        operations[8].addDependency(operations[0])
        gpOperationQueue?.addOperations(operations, waitUntilFinished: true)

        // Test cases
        let index0 = testDataManager.index(of: 0)!
        let index1 = testDataManager.index(of: 1)!
        let index6 = testDataManager.index(of: 6)!
        let index8 = testDataManager.index(of: 8)!
        XCTAssertTrue(index6 < index0, "Task6 should finish before Task0, as priorityOfTask6(veryHigh) > priorityOfTask0(veryLow)")
        //XCTAssertTrue(index1 < index0, "Task1 should finish before Task0, as priorityOfTask1(low) > priorityOfTask0(veryLow)")
        XCTAssertTrue(index0 < index8, "Task0 should finish before Task8, as Task8 dependes on Task0")
    }
    
}
