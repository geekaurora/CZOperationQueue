import Foundation
import CZUtils

public class TestOperation: Operation {
  private var testDataManager: TestDataManager
  let sleepInterval: TimeInterval
  let jobIndex: Int
  
  public init(_ jobIndex: Int, sleepInterval: TimeInterval = 1, testDataManager: TestDataManager) {
    self.jobIndex = jobIndex
    self.sleepInterval = sleepInterval
    self.testDataManager = testDataManager
    super.init()
  }
  
  public override func main () {
    _execute()
  }
  
  // Should cancel execution code if it's concurrent
  public override func cancel() {
    super.cancel()
  }
  
  private func _execute() {
    guard !isCancelled else {
      print("jobIndex \(jobIndex): was cancelled!")
      return
    }
    print("jobIndex \(jobIndex): started!")
    Thread.sleep(forTimeInterval: sleepInterval)
    testDataManager.append(jobIndex)
    print("jobIndex \(jobIndex): finished!")
  }
  
  public override var description: String {
    return "Operation: jobIndex = \(jobIndex); isFinished: \(isFinished)"
  }
}

