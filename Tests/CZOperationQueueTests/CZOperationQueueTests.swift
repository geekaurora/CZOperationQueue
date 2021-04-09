import XCTest
@testable import CZOperationQueue

final class CZOperationQueueTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CZOperationQueue().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
