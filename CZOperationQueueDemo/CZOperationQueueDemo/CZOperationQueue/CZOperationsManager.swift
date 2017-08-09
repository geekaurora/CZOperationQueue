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
    fileprivate lazy var executingOperationsLock: CZMutexLock<[Operation]> = CZMutexLock([Operation]())
    fileprivate static let priorityOrder: [Operation.QueuePriority] = [.veryHigh, .high, .normal, .low, .veryLow]
    fileprivate let maxConcurrentOperationCount: Int
    weak var delegate: CZOperationsManagerDelegate?
    deinit { removeObserver(self, forKeyPath: config.kOpFinishedKeyPath) }

    required init(maxConcurrentOperationCount: Int) {
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        super.init()
    }

    var operations: [Operation] {
        return subOperationQueuesLock.readLock({ (subOperationQueues) -> [Operation]? in
            [Operation](CZOperationsManager.priorityOrder.flatMap{ subOperationQueues[$0] }.joined())
        }) ?? []
    }

    var reachedMaxConcurrentCount: Bool {
        return executingOperationsLock.readLock({[weak self] (executingOps) -> Bool? in
            guard let `self` = self else {return false}
            return executingOps.count >= self.maxConcurrentOperationCount
        }) ?? false
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
                if let op =  subOperationQueues[priority]?.first(where: {$0.canStart}) {
                    subOperationQueues[priority]!.remove(op)
                    self.executingOperationsLock.writeLock({ (executingOps) -> [Operation]? in
                        executingOps.append(op)
                        return executingOps
                    })
                    dequeueClosure(op, &(subOperationQueues[priority]!))
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
            let object = object as? Operation,
            newValue != oldValue,
            context == &kOpObserverContext,
            config.kOpFinishedKeyPath == keyPath else {
                return
        }
        self.executingOperationsLock.writeLock({ (executingOps) -> [Operation]? in
            executingOps.remove(object)
            return executingOps
        })

        if let delegate = delegate {
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
