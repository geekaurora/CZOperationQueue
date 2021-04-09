import Foundation
import CZUtils

public class TestDataManager: CustomStringConvertible {
  public static let shared = TestDataManager()
  let resultsLock = CZMutexLock([Int]())
  
  public init() {}
  
  public func append(_ result: Int) {
    resultsLock.writeLock {
      $0.append(result)
      dbgPrint("results: \($0)")
    }
  }
  
  public func results() -> [Int] {
    resultsLock.readLock { (results) -> [Int]? in
      results
    } ?? []
  }
  
  public func removeAll() {
    resultsLock.writeLock { (results) -> [Int]? in
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

