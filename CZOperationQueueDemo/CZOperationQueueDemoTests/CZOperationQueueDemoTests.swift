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
    fileprivate lazy var testDataManager = TestDataManager.shared
    fileprivate var gpOperationQueue: GPOperationQueue?

    override func setUp() {
        super.setUp()
        testDataManager.removeAll()
        gpOperationQueue = GPOperationQueue()
        gpOperationQueue?.maxConcurrentOperationCount = 3
    }

    override func tearDown() {
        super.tearDown()
        gpOperationQueue = nil
    }
    
    func testBasic() {
        let operations = (0...10).map {TestOperation($0, testDataManager: testDataManager)}
        // Priority
        operations[0].queuePriority = .veryLow
        operations[1].queuePriority = .low
        operations[6].queuePriority = .veryHigh
        // Dependency
        operations[8].addDependency(operations[0])
        gpOperationQueue?.addOperations(operations, waitUntilFinished: true)

        let index0 = testDataManager.index(of: 0)!
        let index1 = testDataManager.index(of: 1)!
        let index6 = testDataManager.index(of: 6)!
        let index8 = testDataManager.index(of: 8)!
        XCTAssertTrue(index6 < index0, "Task6 should complete before Task0, as priorityOfTask6(veryHigh) > priorityOfTask0(veryLow)")
        XCTAssertTrue(index1 < index0, "Task1 should complete before Task0, as priorityOfTask1(low) > priorityOfTask0(veryLow)")
        XCTAssertTrue(index0 < index8, "Task0 should complete before Task8, as Task8 dependes on Task0")
    }
    
}
