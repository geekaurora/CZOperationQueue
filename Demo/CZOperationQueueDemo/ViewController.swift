import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    testGPOperationQueue()
  }
  
  func testGPOperationQueue() {
    GPOperationQueueTester().test()
  }
}

