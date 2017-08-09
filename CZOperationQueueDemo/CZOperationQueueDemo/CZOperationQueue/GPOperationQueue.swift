//
//  GPOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

open class GPOperationQueue: NSObject {
    var maxConcurrentOperationCount: Int = .max {
        didSet {
            operationsManager.maxConcurrentOperationCount = maxConcurrentOperationCount
        }
    }
    fileprivate var operationsManager: CZOperationsManager
    fileprivate let jobQueue: DispatchQueue
    var operations: [Operation] {
        return operationsManager.operations
    }

    override init() {
        operationsManager = CZOperationsManager()
        jobQueue = DispatchQueue(label: config.label, attributes:  [.concurrent])
        super.init()
        operationsManager.delegate = self
    }

    open func addOperation(_ op: Operation) {
        _addOperation(op)
    }

    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        ops.forEach { _addOperation($0, byAddOperations: true) }
        _runNextOperations()
    }

    open func cancelAllOperations() {
        operationsManager.cancelAllOperations()
    }
}

extension GPOperationQueue: CZOperationsManagerDelegate {
    func operation(_ op: Operation, isFinished: Bool) {
        if isFinished {
            _runNextOperations()
        }
    }
}

fileprivate extension GPOperationQueue {
    fileprivate struct config {
        static let maxConcurrentOperationCount: Int = .max
        static let label = "com.tony.underlyingQueue"
    }

    func _addOperation(_ op: Operation, byAddOperations: Bool = false) {
        operationsManager.append(op)
        if (!byAddOperations) {
            _runNextOperations()
        }
    }

    func _runNextOperations() {
        print("\(#function): current operation count: \(operationsManager.operations.count); canExecuteNewOp: \(operationsManager.canExecuteNewOperation)")
        
        while (operationsManager.canExecuteNewOperation) {
            operationsManager.dequeueFirstReadyOp { (op, subqueue) in
                if let op = op as? TestOperation {
                    print("dequeued op: \(op.jobIndex)")
                }
                self.jobQueue.async {
                    if (op.canStart) {
                        op.start()
                    }
                }
            }
        }
    }
}

extension Operation {
    var canStart: Bool {
        if (hasUncompleteDependency) {
            if let op = self as? TestOperation {
                print("hasUncompleteDependency op: \(op.jobIndex)")
            }
        }
        return !isCancelled &&
               isReady &&
               !isExecuting &&
               !hasUncompleteDependency
    }
    var hasUncompleteDependency: Bool {
        if let op = self as? TestOperation, op.jobIndex == 8 {
            print("hasUncompleteDependency op: \(op.jobIndex); dependencies: \(op.dependencies)")
        }
        return dependencies.contains(where: {!$0.isFinished })
    }
}
