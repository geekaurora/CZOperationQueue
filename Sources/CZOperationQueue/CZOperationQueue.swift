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
///
open class CZOperationQueue: NSObject {
  private let operationsManager: CZOperationsManager
  private let jobQueue: DispatchQueue
  private let waitingSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
  private var operations: [Operation] {
    return operationsManager.operations
  }
  /// The count of operations currently in the queue.
  var operationCount: Int {
    return operations.count
  }
  /// Indicates whether the OperationQueue is suspended.
  var isSuspended: Bool {
    return false
  }
  /// The name of the OperationQueue.
  var name: String?
  
  // MARK: - Initializer
  
  public init(maxConcurrentOperationCount: Int = .max) {
    operationsManager = CZOperationsManager(maxConcurrentOperationCount: maxConcurrentOperationCount)
    jobQueue = DispatchQueue(label: config.label, attributes:  [.concurrent])
    super.init()
    
    operationsManager.delegate = self
  }
  
  /// Adds the specified `operation` to the operation queue.
  /// It will execute when it reaches the queue head based on its priority and is ready / has no unfinished dependencies,
  open func addOperation(_ operation: Operation) {
    _addOperation(operation)
  }
  
  /// Adds the specified `operations` to the operation queue.
  /// Eash operation will execute when it reaches the queue head based on its priority and is ready / has no unfinished dependencies.
  ///
  /// - Parameters:
  ///   - operations: operations to be executed.
  ///   - waitUntilFinished: Indicates whether should wait on the current thread until all `operations` finish.
  open func addOperations(_ operations: [Operation], waitUntilFinished: Bool = false) {
    operations.forEach {
      _addOperation($0, shouldRunNextOperations: false)
    }
    runNextOperations()
    
    if waitUntilFinished {
      waitingSemaphore.wait()
    }
  }
  
  /// Cancels all queued and executing operations.
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
    static let label = "com.CZOperationQueue.underlyingQueue"
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
    dbgPrint("\(#function): current operation count: \(operationsManager.operations.count); hasNextReadyOperation: \(operationsManager.hasNextReadyOperation)")
    
    while operationsManager.hasNextReadyOperation {
      operationsManager.dequeueFirstReadyOperation { (operation, subqueue) in
        dbgPrint("dequeued operation: \(operation)")
        
        self.jobQueue.async {
          if operation.canStart {
            operation.start()
          }
        }
      }
    }
  }
}

/// MARK: - Operation
///
extension Operation {
  var canStart: Bool {
    return !isCancelled &&
      isReady &&
      !isExecuting &&
      !hasUnfinishedDependency
  }
  
  var hasUnfinishedDependency: Bool {
    dbgPrint("hasUnfinishedDependency operation: \(self); dependencies: \(dependencies)")
    return dependencies.contains { !$0.isFinished }
  }
}

