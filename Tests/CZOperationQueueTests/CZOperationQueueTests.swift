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
        dbgPrint("TestDataManager: \(self.dataManager)")

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
        dbgPrint("TestDataManager: \(self.dataManager)")
        
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
        dbgPrint("TestDataManager: \(self.dataManager)")
        
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
          "Incorrect executing order of priority! resultIndexOfOperation0 = \(resultIndexOfOperation0), \nresultIndexOfOperation1=\(resultIndexOfOperation1)")

        // Verify priority: .low < .normal
        XCTAssertTrue(
          resultIndexOfOperation7 < resultIndexOfOperation1,
          "Incorrect executing order of priority! resultIndexOfOperation1 = \(resultIndexOfOperation1), \nresultIndexOfOperation7=\(resultIndexOfOperation7)")

        // Verify priority: .normal < .high
        XCTAssertTrue(
          resultIndexOfOperation8 < resultIndexOfOperation7,
          "Incorrect executing order of priority! resultIndexOfOperation7 = \(resultIndexOfOperation7), \nresultIndexOfOperation8=\(resultIndexOfOperation8)")

        // Verify priority: .high < .veryHigh
        XCTAssertTrue(
          resultIndexOfOperation6 < resultIndexOfOperation8,
          "Incorrect executing order of priority! resultIndexOfOperation7 = \(resultIndexOfOperation7), \nresultIndexOfOperation8=\(resultIndexOfOperation8)")
        
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testAddOperationWithDependency() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    let operations = MockData.testIndexesArray.map { TestOperation($0, dataManager: dataManager) }
    operations[0].queuePriority = .veryLow
    operations[1].queuePriority = .low
    operations[6].queuePriority = .veryHigh
    operations[8].addDependency(operations[0])
    
    czOperationQueue.addOperations(
      operations,
      allOperationsFinished: {
        // Fulfill the expectatation.
        expectation.fulfill()
        
      })
    
    //        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {[weak self] in
    //            guard let `self` = self else { return }
    //            self.czOperationQueue?.cancelAllOperations()
    //        }
    
    //        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {[weak self] in
    //            guard let `self` = self else { return }
    //            let operation = TestOperation(11, dataManager: self.dataManager)
    //            operation.queuePriority = .veryHigh
    //            self.czOperationQueue?.addOperation(operation)
    //        }
    
    dbgPrint("TestDataManager: \(dataManager)")
    
    // Wait for expectatation.
    waitForExpectatation()
  }
}
