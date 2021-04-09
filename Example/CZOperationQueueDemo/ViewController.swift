import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    testCZOperationQueue()
  }
  
  func testCZOperationQueue() {
    CZOperationQueueTester().test()
  }
}

