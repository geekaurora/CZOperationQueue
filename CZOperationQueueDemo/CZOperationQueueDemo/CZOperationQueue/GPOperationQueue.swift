//
//  GPOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit

extension Operation {
    var canStart: Bool {
        return !isCancelled && isReady && !isExecuting
    }
}

open class GPOperationQueue: NSObject {
    var maxConcurrentOperationCount: Int
    fileprivate var operationsManager: CZOperationsManager
    /** CZDispatchQueue */
    /// Serial queue acting as gate keeper, to ensure only one thread is blocked
    fileprivate let gateKeeperQueue: DispatchQueue
    /// Actual concurrent working queue
    fileprivate let jobQueue: DispatchQueue
    /// Semahore to limit the max concurrent executions in dispatch queue
    fileprivate let semaphore: DispatchSemaphore
    fileprivate enum QueueLabel: String {
        case gateKeeper, job
        func prefix(_ label: String) -> String {
            return label + "." + self.rawValue
        }
    }    
    
    required public init(maxConcurrentOperationCount: Int = config.maxConcurrentOperationCount) {
         self.maxConcurrentOperationCount = maxConcurrentOperationCount
        operationsManager = CZOperationsManager(maxConcurrentOperationCount: maxConcurrentOperationCount)
        
        let label = config.label
        let maxConcurrentCount = maxConcurrentOperationCount

        /// Initialize semaphore
        semaphore = DispatchSemaphore(value: maxConcurrentCount)
        /// Serial queue acting as gate keeper, to ensure only one thread is blocked
        gateKeeperQueue = DispatchQueue(label: QueueLabel.gateKeeper.prefix(label),
                                        attributes: [])

        /// Actual concurrent working queue
        jobQueue = DispatchQueue(label: QueueLabel.job.prefix(label),
                                 attributes:  [.concurrent]
        )
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
        static let maxConcurrentOperationCount = 128
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
            //self.semaphore.wait()
            operationsManager.dequeueFirstReadyOp { (op, subqueue) in
                if let op = op as? TestOperation {
                    print("dequeued op: \(op.jobIndex)")
                }
                self.jobQueue.async {
                    if (op.canStart) {
                        op.start()
                        //self.semaphore.signal()
                    }
                }
            }
        }
    }
}


