import Foundation
import XCTest
@testable import SwiftShellUtilities

final class SpawnTests: XCTestCase {

    func testThat_SpawnTrue_ExitCodeIsZero() throws {
        let inputValue = "true"
        let expectedValue = 0
        
        let s = try Spawn(command: inputValue)
        let resolvedValue = s.wait()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

    func testThat_SpawnFalse_ExitCodeIsOne() throws {
        let inputValue = "false"
        let expectedValue = 1
        
        let s = try Spawn(command: inputValue)
        let resolvedValue = s.wait()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

}
