//
//  CZOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

/// Custom OperationQueue implemented with GCD - DispatchQueue.
///
/// It supports:
///  - Concurrent operations
///  - Operation priority
///  - Operation dependencies
///  - `maxConcurrentOperationCount`
open class CZOperationQueue: NSObject {
  private let operationsManager: CZOperationsManager
  private let jobQueue: DispatchQueue
  private let waitingSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
  private var operations: [Operation] {
    return operationsManager.operations
  }
  /// Current executing operations count.
  var operationCount: Int {
    return operations.count
  }
  /// Indicates whether the OperationQueue is suspended.
  var isSuspended: Bool {
    return false
  }
  /// The name of the OperationQueue.
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
  
  open func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
    operations.forEach { _addOperation($0, shouldRunNextOperations: false) }
    runNextOperations()
    
    // Sync execute: block current thread to wait until all operations finished
    waitingSemaphore.wait()
  }
  
  open func cancelAllOperations() {
    operationsManager.cancelAllOperations()
  }
}

// MARK: - CZOperationsManagerDelegate

extension CZOperationQueue: CZOperationsManagerDelegate {
  func operationDidFinish(_ operation: Operation,
                          areAllOperationsFinished: Bool) {
    if areAllOperationsFinished {
      if operationsManager.areAllOperationsFinished {
        notifyOperationsFinished()
      } else {
        runNextOperations()
      }
    }
  }
}

// MARK: - Private methods

private extension CZOperationQueue {
  private enum config {
    static let maxConcurrentOperationCount: Int = .max
    static let label = "com.tony.underlyingQueue"
  }
  
  func notifyOperationsFinished() {
    waitingSemaphore.signal()
  }
  
  func _addOperation(_ operation: Operation,
                     shouldRunNextOperations: Bool = true) {
    operationsManager.append(operation)
    
    if shouldRunNextOperations {
      runNextOperations()
    }
  }
  
  func runNextOperations() {
    dbgPrint("\(#function): current operation count: \(operationsManager.operations.count); canExecuteNewOp: \(operationsManager.hasNextReadyOperation)")
    
    while operationsManager.hasNextReadyOperation {
      operationsManager.dequeueFirstReadyOperation { (operation, subqueue) in
        dbgPrint("dequeued operation: \(operation)")
        
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
    //if let operation = self as? TestOperation, operation.jobIndex == 8 {
    dbgPrint("hasUncompleteDependency operation: \(self); dependencies: \(dependencies)")
    //}
    return dependencies.contains(where: {!$0.isFinished })
  }
}

