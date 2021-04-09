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
  
  // MARK: - Add Operations
  
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
  
  // MARK: - cancelAllOperations
  
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
