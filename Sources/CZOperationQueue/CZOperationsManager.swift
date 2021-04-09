//
//  CZOperationsManager.swift
//
//  Created by Cheng Zhang on 8/9/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

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
        return executingOperationsLock.readLock{ $0 } ?? []
    }

    override init() {
        super.init()
    }

    var operations: [Operation] {
        return subOperationQueuesLock.readLock({ (subOperationQueues) -> [Operation]? in
            [Operation](CZOperationsManager.priorityOrder.flatMap{ subOperationQueues[$0] }.joined())
        }) ?? []
    }

    var reachedMaxConcurrentCount: Bool {
        return executingOperationsLock.readLock({[weak self] in
            guard let `self` = self else {return false}
            return $0.count >= self.maxConcurrentOperationCount
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
        subOperationQueuesLock.writeLock {
            if $0[operation.queuePriority] == nil {
                $0[operation.queuePriority] = []
            }
            $0[operation.queuePriority]!.append(operation)
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
                subOperationQueues[priority]!.forEach{[weak self] in
                    $0.cancel()
                    self?.removeFinishedObserver(from: $0)
                }
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
            let operation = object as? Operation,
            newValue != oldValue,
            context == &kOpObserverContext,
            config.kOpFinishedKeyPath == keyPath else {
                return
        }
        let isInExecutingQueue = self.executingOperationsLock.readLock{ $0.contains(operation) } ?? false

        if !isInExecutingQueue {
            assertionFailure("Error - attemped to cancel operation that isn't in executing queue.")
            return
        }

        self.executingOperationsLock.writeLock{ $0.remove(operation) }
        removeFinishedObserver(from: operation)

        if let delegate = delegate {
            delegate.operation(operation, isFinished: true)
        }
    }
    func removeFinishedObserver(from operation: Operation) {
        operation.removeObserver(self, forKeyPath: config.kOpFinishedKeyPath)
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ object: Element) {
        if let i = index(of: object) {
            remove(at: i)
        }
    }
}
