import XCTest
import CZUtils
import CZTestUtils
@testable import CZOperationQueue

final class CZOperationQueueTests: XCTestCase {
  private lazy var dataManager = TestDataManager.shared
  private var czOperationQueue: CZOperationQueue!
  private enum Constant {
    static let timeOut: TimeInterval = 30
    static let maxConcurrentOperationCount = 3
  }
  
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
        // Verify `operation` has been executed.
        XCTAssertTrue(operation.isExecuted, "operation should have been executed.")
        // Fulfill the expectatation.
        expectation.fulfill()
      })
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testAddOperationWithDependency() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    let operations = (0...10).map { TestOperation($0, dataManager: dataManager) }
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
