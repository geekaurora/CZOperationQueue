//
//  Created by Cheng Zhang on 7/11/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import UIKit
import CZOperationQueue

class CZOperationQueueTester {
  private lazy var testDataManager = TestDataManager.shared
  private var czOperationQueue: CZOperationQueue?
  
  func test() {
    testDataManager.removeAll()
    czOperationQueue = CZOperationQueue(maxConcurrentOperationCount: 3)
    
    let operations = (0...10).map {TestOperation($0, testDataManager: testDataManager)}
    operations[0].queuePriority = .veryLow
    operations[1].queuePriority = .low
    operations[6].queuePriority = .veryHigh
    operations[8].addDependency(operations[0])
    
    czOperationQueue?.addOperations(operations, waitUntilFinished: true)
    
    //        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {[weak self] in
    //            guard let `self` = self else { return }
    //            self.czOperationQueue?.cancelAllOperations()
    //        }
    
    //        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {[weak self] in
    //            guard let `self` = self else { return }
    //            let operation = TestOperation(11, testDataManager: self.testDataManager)
    //            operation.queuePriority = .veryHigh
    //            self.czOperationQueue?.addOperation(operation)
    //        }
    
    print("TestDataManager: \(testDataManager)")
  }
  
}


