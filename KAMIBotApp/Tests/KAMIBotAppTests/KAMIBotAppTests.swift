import XCTest
@testable import KAMIBotApp

@MainActor
final class KAMIBotAppTests: XCTestCase {
    func testContainerBuildsAgent() {
        let container = AppContainer()
        _ = container.agent
        _ = container.audioStartupCoordinator
    }

    func testFloatingWindowConfigDefaults() {
        let config = FloatingWindowConfig()
        XCTAssertTrue(config.isBorderless)
        XCTAssertTrue(config.isFloating)
        XCTAssertTrue(config.isTransparent)
    }
}
