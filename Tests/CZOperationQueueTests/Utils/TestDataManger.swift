import Foundation
import CZUtils

public class TestDataManager: CustomStringConvertible {
  public static let shared = TestDataManager()
  typealias Results = [Int]
  
  let resultsLock = CZMutexLock(Results())
  let mutexLock = DispatchSemaphore(value: 0)
  
  public init(){}
  
  public func append(_ index: Int) {
    resultsLock.writeLock {
      $0.append(index)
      dbgPrint("results: \($0)")
    }
  }
  
  public func removeAll() {
    resultsLock.writeLock { (results) -> Results? in
      results.removeAll()
      return results
    }
  }
  
  public func index(of obj: Int) -> Int? {
    return resultsLock.readLock { (results) -> Int? in
      return results.index(of: obj)
    }
  }
  
  public var description: String {
    return resultsLock.readLock { (results) -> String? in
      return "results: \(results)"
    } ?? ""
  }
}

