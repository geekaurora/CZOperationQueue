import Foundation
import CZUtils

// public class TestOperation: Operation {
public class TestOperation: ConcurrentBlockOperation {
private var dataManager: TestDataManager
  let sleepInterval: TimeInterval
  let jobIndex: Int
  var isExecuted = false

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
    
    // Call start() to mark state as isFinished.
    start()
    finish()
  }
  
  public override func _execute() {
    guard !isCancelled else {
      dbgPrint("jobIndex \(jobIndex): was cancelled!")
      return
    }
    dbgPrint("jobIndex \(jobIndex): started!")
    Thread.sleep(forTimeInterval: sleepInterval)
    isExecuted = true
    dataManager.append(jobIndex)
    dbgPrint("jobIndex \(jobIndex): finished!")
    
    finish()
  }
  
  public override var description: String {
    return "Operation: jobIndex = \(jobIndex); isFinished: \(isFinished)"
  }
}

