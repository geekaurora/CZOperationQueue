//
//  NSOperationQueueTester.swift
//  TestNSOperationQueue
//
//  Created by Cheng Zhang on 7/11/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

class NSOperationQueueTester {
    private lazy var testDataManager = TestDataManager.shared
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "SampleOperationQueue"
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    private var gpOperationQueue: GPOperationQueue?

    func test() {
        testDataManager.removeAll()
        let operations = (0...10).map {TestOperation($0, testDataManager: testDataManager)}
        operations[6].queuePriority = .veryHigh
        operations[0].queuePriority = .veryLow
        //operations[8].addDependency(operations[0])
        operationQueue.addOperations(operations, waitUntilFinished: true)

        // Verify results
        let index6 = testDataManager.index(of: 6)!
        let index0 = testDataManager.index(of: 0)!
        let index8 = testDataManager.index(of: 8)!
//        assert(index6 < index0, "Task6 should complete before Task0, as it has priority `veryHigh`")
//        assert(index0 < index8, "Task0 should complete before Task8, as Task8 dependes on Task0")
        print("TestDataManager: \(testDataManager)")
    }
}
