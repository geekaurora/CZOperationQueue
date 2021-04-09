import Foundation
import CZUtils

public class TestOperation: Operation {
  private var dataManager: TestDataManager
  let sleepInterval: TimeInterval
  let jobIndex: Int
  
  public init(_ jobIndex: Int, sleepInterval: TimeInterval = 1, dataManager: TestDataManager) {
    self.jobIndex = jobIndex
    self.sleepInterval = sleepInterval
    self.dataManager = dataManager
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
    dataManager.append(jobIndex)
    print("jobIndex \(jobIndex): finished!")
  }
  
  public override var description: String {
    return "Operation: jobIndex = \(jobIndex); isFinished: \(isFinished)"
  }
}

