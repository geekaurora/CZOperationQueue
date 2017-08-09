//
//  CZOperationsManager.swift
//  CZOperationQueueDemo
//
//  Created by Cheng Zhang on 8/9/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

class CZOperationsManager: NSObject {
    typealias DequeueClosure = (Operation, inout [Operation]) -> Void
    typealias SubOperationQueues = [Operation.QueuePriority: [Operation]]
    fileprivate lazy var subOperationQueuesLock: CZMutexLock<SubOperationQueues> = CZMutexLock(SubOperationQueues())
    fileprivate static let priorityOrder: [Operation.QueuePriority] = [.veryHigh, .high, .normal, .low, .veryLow]
    override init() {
        super.init()
    }

    func append(_ operation: Operation) {
        subOperationQueuesLock.writeLock { (subOperationQueues) -> SubOperationQueues? in
            if subOperationQueues[operation.queuePriority] == nil {
                subOperationQueues[operation.queuePriority] = []
            }
            subOperationQueues[operation.queuePriority]!.append(operation)
            return subOperationQueues
        }
    }

    func dequeueFirstReadyOp(dequeueClosure: @escaping DequeueClosure) {
        subOperationQueuesLock.writeLock { (subOperationQueues) -> SubOperationQueues? in
            for priority in CZOperationsManager.priorityOrder {
                // Shouldn't assign? - Copy: var subqueue = subOperationQueues[priority]
                guard subOperationQueues[priority] != nil else { continue }
                if let operation =  subOperationQueues[priority]?.first(where: {$0.canStart}) {
                    dequeueClosure(operation, &(subOperationQueues[priority]!))
                    break
                }
            }
            return subOperationQueues
        }
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ object: Element) {
        if let i = index(of: object) {
            remove(at: i)
        }
    }
}
