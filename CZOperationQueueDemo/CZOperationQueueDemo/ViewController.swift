//
//  ViewController.swift
//  CZOperationQueueDemo
//
//  Created by Cheng Zhang on 8/8/17.
//  Copyright © 2017 Groupon Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var queueTester: GPOperationQueueTester?

    override func viewDidLoad() {
        super.viewDidLoad()

        queueTester = GPOperationQueueTester()
        queueTester?.test()
    }
}
