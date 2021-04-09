import Foundation
import CZUtils

public class TestDataManager: CustomStringConvertible {
  
  public static let shared = TestDataManager()
  
  typealias Output = [Int]
  var output = Output()
  let lock: CZMutexLock<Output> = CZMutexLock(Output())
  let mutexLock = DispatchSemaphore(value: 0)
  
  public init(){}
  
  public func append(_ index: Int) {
    lock.writeLock {
      $0.append(index)
      print("output: \($0)")
    }
  }
  
  public func removeAll() {
    lock.writeLock { (output) -> Output? in
      output.removeAll()
      return output
    }
  }
  
  public func index(of obj: Int) -> Int? {
    return lock.readLock { (output) -> Int? in
      return output.index(of: obj)
    }
  }
  
  public var description: String {
    return lock.readLock { (output) -> String? in
      return "output: \(output)"
    } ?? ""
  }
}

