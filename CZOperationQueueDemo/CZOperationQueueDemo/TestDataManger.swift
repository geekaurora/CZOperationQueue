//
//  TestDataManager.swift
//  TestNSOperationQueue
//
//  Created by Cheng Zhang on 7/11/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

class TestDataManager: CustomStringConvertible {
    static let shared = TestDataManager()
    typealias Output = [Int]
    var output: Output
    let lock: CZMutexLock<Output>

    init() {
        output = []
        lock = CZMutexLock(output)
    }

    func append(_ index: Int) {
        lock.writeLock { (output) -> Output? in
            output.append(index)
            print("output: \(output)")
            return nil
        }
    }
    func removeAll() {
        lock.writeLock { (output) -> Output? in
            output.removeAll()
            return nil
        }
    }

    func index(of obj: Int) -> Int? {
        guard let output = lock.readLock({ output in
            return output
        }) else {
            return nil
        }
        return output.index(of: obj)
    }

    public var description: String {
        let output = lock.readLock { $0 } ?? []
        return "output: \(output)"
    }
}

class TestOperation: Operation {
    fileprivate var testDataManager: TestDataManager
    let sleepInterval: TimeInterval
    let jobIndex: Int

    init(_ jobIndex: Int, sleepInterval: TimeInterval = 1, testDataManager: TestDataManager) {
        self.jobIndex = jobIndex
        self.sleepInterval = sleepInterval
        self.testDataManager = testDataManager
        super.init()
    }

    override func main () {
        guard !isCancelled else {
            print("jobIndex \(jobIndex): was cancelled!")
            return
        }
        print("jobIndex \(jobIndex): started!")
        Thread.sleep(forTimeInterval: sleepInterval)
        testDataManager.append(jobIndex)
        print("jobIndex \(jobIndex): finished!")
    }

//    override var description: String {
//        return "Operation: jobIndex = \(jobIndex); isFinished: \(isFinished)"
//    }
}

