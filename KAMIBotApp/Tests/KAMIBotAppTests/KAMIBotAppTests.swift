import XCTest
@testable import KAMIBotApp

@MainActor
final class KAMIBotAppTests: XCTestCase {
    func testContainerBuildsAgent() {
        let container = AppContainer()
        _ = container.agent
    }
}
