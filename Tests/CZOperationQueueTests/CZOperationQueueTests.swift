import XCTest
import CZUtils
import CZTestUtils
@testable import CZOperationQueue

final class CZOperationQueueTests: XCTestCase {
  private enum Constant {
    static let timeOut: TimeInterval = 30
    static let maxConcurrentOperationCount = 3
  }
  private enum MockData {
    static let testIndexesArray = Array(0...10)
  }
  private let dataManager = TestDataManager.shared
  private var czOperationQueue: CZOperationQueue!
  
  override func setUp() {
    dataManager.removeAll()
    czOperationQueue = CZOperationQueue(maxConcurrentOperationCount: Constant.maxConcurrentOperationCount)
  }
  
  func testAddOperation() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    // Add one operation.
    let operation = TestOperation(0, dataManager: dataManager)
    czOperationQueue.addOperations(
      [operation],
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operation` has been executed.
        XCTAssertTrue(operation.isExecuted, "operation should have been executed.")
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testAddOperations() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Add operations.
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operations` have been executed.
        XCTAssertTrue(!operations.contains { !$0.isExecuted }, "All operations should have been executed.")
        
        // Verify results of dataManager are correct.
        let expected = Set(MockData.testIndexesArray)
        let actual = Set(self.dataManager.results())
        XCTAssertEqual(expected, actual, "Results are incorrect! expected = \(expected), \nactual=\(actual)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testAddOperationsWithPriority() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Init operations with priority.
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    operations[0].queuePriority = .veryLow
    operations[1].queuePriority = .low
    operations[8].queuePriority = .high
    operations[6].queuePriority = .veryHigh
    
    // Add operations.
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operations` have been executed.
        XCTAssertTrue(!operations.contains { !$0.isExecuted }, "All operations should have been executed.")
        
        // Verify results of dataManager are correct.
        let expected = Set(MockData.testIndexesArray)
        let actual = Set(self.dataManager.results())
        XCTAssertEqual(expected, actual, "Results are incorrect! expected = \(expected), \nactual=\(actual)")
        
        // Verify `operations` execution order - should correspond to priorities.
        // operations[0].queuePriority = .veryLow
        let resultIndexOfOperation0 = self.dataManager.index(of: 0)!
        // operations[1].queuePriority = .low
        let resultIndexOfOperation1 = self.dataManager.index(of: 1)!
        
        // operations[7].queuePriority = .normal
        // Note: Should choose operation with later index for .normal priority,
        // because if operation already executes, it will ignore priority.
        let resultIndexOfOperation7 = self.dataManager.index(of: 7)!
        
        // operations[8].queuePriority = .high
        let resultIndexOfOperation8 = self.dataManager.index(of: 8)!
        // operations[6].queuePriority = .veryHigh
        let resultIndexOfOperation6 = self.dataManager.index(of: 6)!
        
        // Verify priority: .veryLow < .low
        XCTAssertTrue(
          resultIndexOfOperation1 < resultIndexOfOperation0,
          "Incorrect executing order of priority! resultIndexOfOperation1 = \(resultIndexOfOperation1), \nresultIndexOfOperation0 = \(resultIndexOfOperation0)")
        
        // Verify priority: .low < .normal
        XCTAssertTrue(
          resultIndexOfOperation7 < resultIndexOfOperation1,
          "Incorrect executing order of priority! resultIndexOfOperation7 = \(resultIndexOfOperation7), \nresultIndexOfOperation1 = \(resultIndexOfOperation1)")
        
        // Verify priority: .normal < .high
        XCTAssertTrue(
          resultIndexOfOperation8 < resultIndexOfOperation7,
          "Incorrect executing order of priority! resultIndexOfOperation8 = \(resultIndexOfOperation8), \resultIndexOfOperation7 = \(resultIndexOfOperation7)")
        
        // Verify priority: .high < .veryHigh
        XCTAssertTrue(
          resultIndexOfOperation6 < resultIndexOfOperation8,
          "Incorrect executing order of priority! resultIndexOfOperation6 = \(resultIndexOfOperation6), \nresultIndexOfOperation8= \(resultIndexOfOperation8)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  /// Test add Operations with priority.
  /// Add Operation with .veryHigh  priority after 1 sec.
  /// Note: should consider concurrent executions with`maxConcurrentOperationCount` as 3 every sec.
  func testAddOperationsWithPriorityByDelayAddingVeryHighPriorityOperation() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Init operations with priority.
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    operations[0].queuePriority = .veryLow
    operations[1].queuePriority = .low
    operations[8].queuePriority = .high
    operations[6].queuePriority = .veryHigh
    
    // Add operations.
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operations` have been executed.
        XCTAssertTrue(!operations.contains { !$0.isExecuted }, "All operations should have been executed.")
        
        // Verify results of dataManager are correct.
        let expected = Set(MockData.testIndexesArray + [11])
        let actual = Set(self.dataManager.results())
        XCTAssertEqual(expected, actual, "Results are incorrect! expected = \(expected), \nactual=\(actual)")
        
        // Verify `operations` execution order - should correspond to priorities.
        
        // operations[0].queuePriority = .veryLow
        let resultIndexOfOperation0 = self.dataManager.index(of: 0)!
        // operations[11].queuePriority = .veryHigh
        let resultIndexOfOperation11 = self.dataManager.index(of: 11)!
        
        // Verify priority: .veryLow < .veryHigh
        XCTAssertTrue(
          resultIndexOfOperation11 < resultIndexOfOperation0,
          "Incorrect executing order of priority! resultIndexOfOperation11 = \(resultIndexOfOperation11), \nresultIndexOfOperation0 = \(resultIndexOfOperation0)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    
    // Add Operation with .veryHigh  priority after 1 sec.
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
      let operation = TestOperation(11, dataManager: self.dataManager)
      operation.queuePriority = .veryHigh
      self.czOperationQueue.addOperation(operation)
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testAddOperationWithDependency() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Init operations.
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    operations[0].queuePriority = .veryLow
    operations[1].queuePriority = .low
    operations[6].queuePriority = .veryHigh
    
    // Set operations[0] as operations[8]'s dependency.
    operations[8].addDependency(operations[0])
    
    // Add operations.
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operations` have been executed.
        XCTAssertTrue(!operations.contains { !$0.isExecuted }, "All operations should have been executed.")
        
        // Verify results of dataManager are correct.
        let expected = Set(MockData.testIndexesArray)
        let actual = Set(self.dataManager.results())
        XCTAssertEqual(expected, actual, "Results are incorrect! expected = \(expected), \nactual=\(actual)")
        
        // Verify dependency - operations[0] is operations[8]'s dependency.
        // operations[8] should execute after operations[0].
        let resultIndexOfOperation0 = self.dataManager.index(of: 0)!
        let resultIndexOfOperation8 = self.dataManager.index(of: 8)!
        XCTAssertTrue(
          resultIndexOfOperation0 < resultIndexOfOperation8,
          "Incorrect executing order for dependency! resultIndexOfOperation0 = \(resultIndexOfOperation0), \nresultIndexOfOperation8 = \(resultIndexOfOperation8)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testCancelAllOperations() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Add operations.
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        dbgPrint("dataManager: \(self.dataManager)")
        
        // Verify `operations` shound't have been all executed.
        let totalOperationsCount = MockData.testIndexesArray.count
        let executedOperationsCount = self.dataManager.results().count
        XCTAssertTrue(
          executedOperationsCount < totalOperationsCount,
          "operations shound't have been all executed. executedOperationsCount = \(executedOperationsCount), \ntotalOperationsCount = \(totalOperationsCount)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    
    // Call `cancelAllOperations()` after 1 sec.
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
      self.czOperationQueue.cancelAllOperations()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
}
