import XCTest
import CoreAgent
@testable import UIComponents

final class UIComponentsTests: XCTestCase {
    func testFaceViewInit() {
        XCTAssertNotNil(BMOFaceView(expression: .happy, state: .idle))
        XCTAssertNotNil(BMOFaceView(expression: .excited, state: .speaking))
    }
}
