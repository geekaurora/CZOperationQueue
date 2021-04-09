//
//  CZOperationsManager.swift
//
//  Created by Cheng Zhang on 8/9/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

/// Delegate that gets notified whenever an operation is finished.
internal protocol CZOperationsManagerDelegate: class {
  func operationDidFinish(_ operation: Operation, areAllOperationsFinished: Bool)
}

/// Thread safe manager that maintains underlying operations, it dequeues the first ready operation from the queue with
/// ready state / priority / dependencies.
internal class CZOperationsManager: NSObject {
  typealias DequeueOperationClosure = (Operation, inout [Operation]) -> Void
  typealias OperationsMapByPriority = [Operation.QueuePriority: [Operation]]
    
  private enum Constant {
    static let kOperationFinishedKeyPath = "isFinished"
  }
  private static let orderedPriorities: [Operation.QueuePriority] = [
    .veryHigh, .high, .normal, .low, .veryLow
  ]
  private lazy var operationsMapByPriorityLock = CZMutexLock(OperationsMapByPriority())
  private lazy var executingOperationsLock = CZMutexLock([Operation]())
  
  private var executingOperations: [Operation] {
    return executingOperationsLock.readLock{ $0 } ?? []
  }
  private var hasExceededMaxConcurrentCount: Bool {
    return executingOperationsLock.readLock({ [weak self] in
      guard let `self` = self else { return false }
      return $0.count >= self.maxConcurrentOperationCount
    }) ?? false
  }
  private var hasReadyOperation: Bool {
    return operations.contains { $0.canStart }
  }
  
  /// Delegate that gets notified whenever an operation is finished.
  weak var delegate: CZOperationsManagerDelegate?
  
  /// All operations that are currently in the queue - ordered by priority descendingly.
  var operations: [Operation] {
    return operationsMapByPriorityLock.readLock({ (operationsMapByPriority) -> [Operation]? in
      [Operation](CZOperationsManager.orderedPriorities.compactMap {
        operationsMapByPriority[$0]
      }.joined())
    }) ?? []
  }  
  /// Indicates whether there's the next ready Operation.
  var hasNextReadyOperation: Bool {
    return hasReadyOperation && !hasExceededMaxConcurrentCount
  }
  /// Indicates whether all Operations are finished.
  var areAllOperationsFinished: Bool {
    return operations.isEmpty && executingOperations.isEmpty
  }
  /// The max count of the concurrent Operation executions.
  let maxConcurrentOperationCount: Int
  
  // MARK: - Initializer
  
  init(maxConcurrentOperationCount: Int = .max) {
    self.maxConcurrentOperationCount = maxConcurrentOperationCount
    super.init()
  }
  
  /// Append `operation` to the queue.
  func append(_ operation: Operation) {
    operation.addObserver(
      self,
      forKeyPath: Constant.kOperationFinishedKeyPath,
      options: [.new, .old],
      context: &kOperationObserverContext)
    
    operationsMapByPriorityLock.writeLock {
      if $0[operation.queuePriority] == nil {
        $0[operation.queuePriority] = []
      }
      $0[operation.queuePriority]?.append(operation)
    }
  }
  
  /// Dequeue the first ready Operation if exists.
  func dequeueFirstReadyOperation(dequeueOperationClosure: @escaping DequeueOperationClosure) {
    operationsMapByPriorityLock.writeLock { (operationsMapByPriority) -> OperationsMapByPriority? in
      
      for priority in Self.orderedPriorities {
        guard operationsMapByPriority[priority] != nil else { continue }
        
        if let firstReadyOperation = operationsMapByPriority[priority]?.first(where: {$0.canStart}) {
          
          operationsMapByPriority[priority]?.remove(firstReadyOperation)
          
          self.executingOperationsLock.writeLock({ (executingOperations) -> [Operation]? in
            executingOperations.append(firstReadyOperation)
            return executingOperations
          })
          
          dequeueOperationClosure(firstReadyOperation, &(operationsMapByPriority[priority]!))
          break
        }
      }
      return operationsMapByPriority
    }
  }
  
  /// Cancel all operations from the queue.
  func cancelAllOperations() {
    operationsMapByPriorityLock.writeLock { (operationsMapByPriority) -> OperationsMapByPriority? in
      var canceledCount = 0
      for priority in CZOperationsManager.orderedPriorities {
        guard operationsMapByPriority[priority] != nil else { continue }
        canceledCount += operationsMapByPriority[priority]!.count
        operationsMapByPriority[priority]!.forEach{[weak self] in
          $0.cancel()
          self?.removeFinishedObserver(from: $0)
        }
        operationsMapByPriority[priority]!.removeAll()
      }
      
      dbgPrint("\(#function): canceled \(canceledCount) operations.")
      return operationsMapByPriority
    }
  }
}

// MARK: - KVO

private var kOperationObserverContext: UInt8 = 0
extension CZOperationsManager {
  open override func observeValue(forKeyPath keyPath: String?,
                                  of object: Any?,
                                  change: [NSKeyValueChangeKey : Any]?,
                                  context: UnsafeMutableRawPointer?) {
    guard let newValue = change?[.newKey] as? Bool,
          let oldValue = change?[.oldKey] as? Bool,
          let operation = object as? Operation,
          newValue != oldValue,
          context == &kOperationObserverContext,
          Constant.kOperationFinishedKeyPath == keyPath else {
      return
    }
    let isInExecutingQueue = self.executingOperationsLock.readLock{ $0.contains(operation) } ?? false
    
    if !isInExecutingQueue {
      assertionFailure("Error - attemped to cancel operation that isn't in executing queue.")
      return
    }
    
    self.executingOperationsLock.writeLock{ $0.remove(operation) }
    removeFinishedObserver(from: operation)
    
    //delegate?.operationDidFinish(operation, areAllOperationsFinished: true)
    delegate?.operationDidFinish(operation, areAllOperationsFinished: areAllOperationsFinished)
  }
  
  func removeFinishedObserver(from operation: Operation) {
    operation.removeObserver(self, forKeyPath: Constant.kOperationFinishedKeyPath)
  }
}
