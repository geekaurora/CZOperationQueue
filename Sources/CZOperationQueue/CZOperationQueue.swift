//
//  CZOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation

open class CZOperationQueue: NSObject {

    private var operationsManager: CZOperationsManager
    private let jobQueue: DispatchQueue
    private let waitingSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    var operations: [Operation] {
        return operationsManager.operations
    }
    var operationCount: Int {
        return operations.count
    }
    var isSuspended: Bool {
        return false
    }
    var name: String?

    public init(maxConcurrentOperationCount: Int = .max) {
      operationsManager = CZOperationsManager(maxConcurrentOperationCount: maxConcurrentOperationCount)
        jobQueue = DispatchQueue(label: config.label, attributes:  [.concurrent])
        super.init()
        operationsManager.delegate = self
    }

    open func addOperation(_ operation: Operation) {
        _addOperation(operation)
    }

    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        ops.forEach { _addOperation($0, byAddOperations: true) }
        _runNextOperations()

        // Sync execute: block current thread to wait until all operations finished
        waitingSemaphore.wait()
    }

    open func cancelAllOperations() {
        operationsManager.cancelAllOperations()
    }
}

extension CZOperationQueue: CZOperationsManagerDelegate {
    func operation(_ operation: Operation, isFinished: Bool) {
        if isFinished {
            if operationsManager.allOperationsFinished {
                _notifyOperationsFinished()
            } else {
                _runNextOperations()
            }
        }
    }
}

private extension CZOperationQueue {
    private struct config {
        static let maxConcurrentOperationCount: Int = .max
        static let label = "com.tony.underlyingQueue"
    }

    func _notifyOperationsFinished() {
        waitingSemaphore.signal()
    }

    func _addOperation(_ operation: Operation, byAddOperations: Bool = false) {
        operationsManager.append(operation)
        if (!byAddOperations) {
            _runNextOperations()
        }
    }

    func _runNextOperations() {
        print("\(#function): current operation count: \(operationsManager.operations.count); canExecuteNewOp: \(operationsManager.canExecuteNewOperation)")
        
        while (operationsManager.canExecuteNewOperation) {
            operationsManager.dequeueFirstReadyOp { (operation, subqueue) in
                if let operation = operation as? TestOperation {
                    print("dequeued operation: \(operation.jobIndex)")
                }
                self.jobQueue.async {
                    if (operation.canStart) {
                        operation.start()
                    }
                }
            }
        }
    }
}

extension Operation {
    var canStart: Bool {
        return !isCancelled &&
               isReady &&
               !isExecuting &&
               !hasUncompleteDependency
    }
    var hasUncompleteDependency: Bool {
        if let operation = self as? TestOperation, operation.jobIndex == 8 {
            print("hasUncompleteDependency operation: \(operation.jobIndex); dependencies: \(operation.dependencies)")
        }
        return dependencies.contains(where: {!$0.isFinished })
    }
}

