//
//  GPOperationQueueTester.swift
//  TestNSOperationQueue
//
//  Created by Cheng Zhang on 7/11/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

class GPOperationQueueTester {
    private lazy var testDataManager = TestDataManager.shared
    private var gpOperationQueue: GPOperationQueue?

    func test() {
        testDataManager.removeAll()
        gpOperationQueue = GPOperationQueue()
        gpOperationQueue?.maxConcurrentOperationCount = 3
        
        let operations = (0...10).map {TestOperation($0, testDataManager: testDataManager)}
        operations[0].queuePriority = .veryLow
        operations[1].queuePriority = .low
        operations[6].queuePriority = .veryHigh
        operations[8].addDependency(operations[0])

        gpOperationQueue?.addOperations(operations, waitUntilFinished: true)

//        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {[weak self] in
//            guard let `self` = self else { return }
//            self.gpOperationQueue?.cancelAllOperations()
//        }

//        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {[weak self] in
//            guard let `self` = self else { return }
//            let operation = TestOperation(11, testDataManager: self.testDataManager)
//            operation.queuePriority = .veryHigh
//            self.gpOperationQueue?.addOperation(operation)
//        }

        print("TestDataManager: \(testDataManager)")
    }

}


