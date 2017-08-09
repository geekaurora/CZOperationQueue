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
    var maxConcurrentOperationCount: Int = .max
    weak var delegate: CZOperationsManagerDelegate?
    fileprivate var executingOperations: [Operation] {
        return executingOperationsLock.readLock({ (operations) -> [Operation]? in
            return operations
        }) ?? []
    }
    deinit { removeObserver(self, forKeyPath: config.kOpFinishedKeyPath) }

    override init() {
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

    var hasReadyOperation: Bool {
        return operations.contains(where: {$0.canStart})
    }
    var canExecuteNewOperation: Bool {
        return hasReadyOperation && !reachedMaxConcurrentCount
    }
    var allOperationsFinished: Bool {
        return operations.isEmpty && executingOperations.isEmpty
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
                // Shouldn't assign to new variable? - Copy: var subqueue = subOperationQueues[priority]
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

    func cancelAllOperations() {
        subOperationQueuesLock.writeLock { (subOperationQueues) -> SubOperationQueues? in
            var canceledCount = 0
            for priority in CZOperationsManager.priorityOrder {
                guard subOperationQueues[priority] != nil else { continue }
                canceledCount += subOperationQueues[priority]!.count
                subOperationQueues[priority]!.forEach{ $0.cancel()}
                subOperationQueues[priority]!.removeAll()
            }
            //print("\(#function): canceled \(canceledCount) operations.")
            return subOperationQueues
        }
    }
}

private var kOpObserverContext: Int = 0
fileprivate extension CZOperationsManager {
    fileprivate struct config {
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
        let isInExecutingQueue = self.executingOperationsLock.readLock({ (executingOps) -> Bool? in
            executingOps.contains(object)
        }) ?? false
        if !isInExecutingQueue {
            assertionFailure("Error - attemped to cancel operation that isn't in executing queue.")
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
