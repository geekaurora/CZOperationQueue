//
//  CZOperationsManager.swift
//  CZOperationQueueDemo
//
//  Created by Cheng Zhang on 8/9/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

protocol CZOperationsManagerDelegate: class {
    func operation(_ op: Operation, isFinished: Bool)
}

/// Thread-safe operations manager
class CZOperationsManager: NSObject {
    typealias DequeueClosure = (Operation, inout [Operation]) -> Void
    typealias SubOperationQueues = [Operation.QueuePriority: [Operation]]
    fileprivate lazy var subOperationQueuesLock: CZMutexLock<SubOperationQueues> = CZMutexLock(SubOperationQueues())
    fileprivate static let priorityOrder: [Operation.QueuePriority] = [.veryHigh, .high, .normal, .low, .veryLow]
    weak var delegate: CZOperationsManagerDelegate?

    deinit { removeObserver(self, forKeyPath: config.kOpFinishedKeyPath) }

    override init() {
        super.init()
    }
    var operations: [Operation] {
        return subOperationQueuesLock.readLock({ (subOperationQueues) -> [Operation]? in
            [Operation](CZOperationsManager.priorityOrder.flatMap{ subOperationQueues[$0] }.joined())
        }) ?? []
    }
    
    var isEmpty: Bool {
        return operations.isEmpty
    }

    func append(_ operation: Operation) {
        operation.addObserver(self, forKeyPath: config.kOpFinishedKeyPath, options: [.new, .old], context: &kOpObserverContext)
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

private var kOpObserverContext: Int = 0
fileprivate extension CZOperationsManager {
    fileprivate struct config {
        static let maxConcurrentOperationCount = 128
        static let label = "com.tony.underlyingQueue"
        static let kOpFinishedKeyPath = "isFinished"
    }
}

extension CZOperationsManager {
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[.newKey] as? Bool,
            let oldValue = change?[.oldKey] as? Bool,
            newValue != oldValue,
            context == &kOpObserverContext,
            config.kOpFinishedKeyPath == keyPath else {
                return
        }
        if let object = object as? Operation,
           let delegate = delegate {
            delegate.operation(object, isFinished: true)
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
