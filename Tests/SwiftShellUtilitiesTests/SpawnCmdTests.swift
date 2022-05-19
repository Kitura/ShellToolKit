import Foundation
import XCTest
@testable import SwiftShellUtilities

final class SpawnCmdTests: XCTestCase {

    func testThat_SpawnCmd_WithPty_CanReadFromStdout() throws {
        let cmd = SpawnCmd(command: "/bin/echo")
        let t = try cmd.runAsync("hello")

        let result = t.wait()
        print("result: \(result)")
    }

}
