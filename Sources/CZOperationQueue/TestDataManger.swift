//
//  TestDataManager.swift
//
//  Created by Cheng Zhang on 7/11/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

class TestDataManager: CustomStringConvertible {
    static let shared = TestDataManager()
    typealias Output = [Int]
    var output = Output()
    let lock: CZMutexLock<Output> = CZMutexLock(Output())
    let mutexLock = DispatchSemaphore(value: 0)
    init(){}

    func append(_ index: Int) {
        lock.writeLock {
            $0.append(index)
            print("output: \($0)")
        }
    }
    func removeAll() {
        lock.writeLock { (output) -> Output? in
            output.removeAll()
            return output
        }
    }

    func index(of obj: Int) -> Int? {
        return lock.readLock { (output) -> Int? in
            return output.index(of: obj)
        }
    }

    public var description: String {
        return lock.readLock { (output) -> String? in
             return "output: \(output)"
        } ?? ""
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
        _execute()
    }

    // Should cancel execution code if it's concurrent
    override func cancel() {
        super.cancel()
    }

    fileprivate func _execute() {
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

