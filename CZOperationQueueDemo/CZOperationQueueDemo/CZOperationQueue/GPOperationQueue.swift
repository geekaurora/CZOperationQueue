//
//  GPOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

open class GPOperationQueue: NSObject {
    var maxConcurrentOperationCount: Int
    fileprivate var operationsManager: CZOperationsManager
    fileprivate let jobQueue: DispatchQueue

    required public init(maxConcurrentOperationCount: Int = config.maxConcurrentOperationCount) {
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        operationsManager = CZOperationsManager(maxConcurrentOperationCount: maxConcurrentOperationCount)
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
        while (!operationsManager.isEmpty && !operationsManager.reachedMaxConcurrentCount) {
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
        return !isCancelled && isReady && !isExecuting
    }
}
