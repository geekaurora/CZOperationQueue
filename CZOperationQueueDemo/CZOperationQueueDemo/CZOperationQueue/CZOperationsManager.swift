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
    fileprivate(set) var subOperationQueues: [Operation.QueuePriority: [Operation]]
    fileprivate static let priorityOrder: [Operation.QueuePriority] = [.veryHigh, .high, .normal, .low, .veryLow]
    override init() {
        subOperationQueues = [:]
        super.init()
    }

    func append(_ operation: Operation) {
        if subOperationQueues[operation.queuePriority] == nil {
            subOperationQueues[operation.queuePriority] = []
        }
        subOperationQueues[operation.queuePriority]!.append(operation)
    }

    func dequeueFirstReadyOp(dequeueClosure: DequeueClosure) {
        for priority in CZOperationsManager.priorityOrder {
            // Shouldn't assign? - Copy: var subqueue = subOperationQueues[priority]
            guard subOperationQueues[priority] != nil else { continue }
            if let operation =  subOperationQueues[priority]?.first(where: {$0.canStart}) {
                dequeueClosure(operation, &(subOperationQueues[priority]!))
                break
            }
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
