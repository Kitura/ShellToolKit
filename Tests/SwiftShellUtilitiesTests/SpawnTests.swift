import Foundation
import XCTest
@testable import SwiftShellUtilities

final class SpawnTests: XCTestCase {

    func testThat_SpawnTrue_ExitCodeIsCorrect() throws {
        let inputValue = "true"
        let expectedValue = 0
        
        let s = Spawn(command: inputValue)
        let resolvedValue = try s.run()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

    func testThat_SpawnFalse_ExitCodeIsCorrect() throws {
        let inputValue = "false"
        let expectedValue = 1
        
        let s = Spawn(command: inputValue)
        let resolvedValue = try s.run()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

}
