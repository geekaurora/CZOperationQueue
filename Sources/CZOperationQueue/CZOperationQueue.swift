//
//  CZOperationQueue.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

/// Custom OperationQueue implemented with GCD - DispatchQueue (Without using NSOperationQueue).
///
/// It supports:
///  - Concurrent operations
///  - Operation priority
///  - Operation dependencies
///  - maxConcurrentOperationCount
///
open class CZOperationQueue: NSObject {
  private let jobQueue: DispatchQueue
  private let waitingSemaphore = DispatchSemaphore(value: 0)
  
  private let operationsManager: CZOperationsManager
  private var operations: [Operation] {
    return operationsManager.operations
  }
  private enum Constant {
    static let maxConcurrentOperationCount = Int.max
    static let label = "com.CZOperationQueue.underlyingQueue"
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
    jobQueue = DispatchQueue(label: Constant.label, attributes:  [.concurrent])
    super.init()
    
    operationsManager.delegate = self
  }
  
  /// Adds the specified `operation` to the operation queue.
  /// `operation` will execute when it reaches the queue head based on its priority / readiness / dependencies.
  open func addOperation(_ operation: Operation) {
    _addOperation(operation)
  }
  
  /// Adds the specified `operations` to the operation queue.
  /// Eash operation will execute when it reaches the queue head based on its priority / readiness / dependencies.
  ///
  /// - Parameters:
  ///   - operations: operations to be executed.
  ///   - waitUntilFinished: Indicates whether should wait on the current thread until all `operations` finish.
  open func addOperations(_ operations: [Operation], waitUntilFinished: Bool = false) {
    operations.forEach {
      _addOperation($0, shouldRunNextOperations: false)
    }
    runNextReadyOperations()
    
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
      notifyOperationsFinished()
    } else {
      runNextReadyOperations()
    }
    
//    if areAllOperationsFinished {
//      if operationsManager.areAllOperationsFinished {
//        notifyOperationsFinished()
//      } else {
//        runNextReadyOperations()
//      }
//    }
  }
}

// MARK: - Private methods

private extension CZOperationQueue {
  func notifyOperationsFinished() {
    waitingSemaphore.signal()
  }
  
  func _addOperation(_ operation: Operation,
                     shouldRunNextOperations: Bool = true) {
    operationsManager.append(operation)
    
    if shouldRunNextOperations {
      runNextReadyOperations()
    }
  }
  
  func runNextReadyOperations() {
    dbgPrint("\(#function): current operation count: \(operationsManager.operations.count); hasNextReadyOperation: \(operationsManager.hasNextReadyOperation)")
    
    while operationsManager.hasNextReadyOperation {
      operationsManager.dequeueFirstReadyOperation { (operation, _) in
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

