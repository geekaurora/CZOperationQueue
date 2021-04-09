//
//  Operation+.swift
//
//  Created by Cheng Zhang on 7/10/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZUtils

extension Operation {
  var canStart: Bool {
    return !isCancelled &&
      isReady &&
      !isExecuting &&
      !hasUnfinishedDependency
  }
  
  var hasUnfinishedDependency: Bool {
    dbgPrint("hasUnfinishedDependency operation: \(self); dependencies: \(dependencies)")
    return dependencies.contains(where: {!$0.isFinished })
  }
}

