import Foundation
import XCTest
import ShellToolKit

final class ShellCmdTests: XCTestCase {
    func testThat_ExitStatus_CanReturnTrue() async throws {
        let expectedValue = Int(EXIT_SUCCESS)
        let observedValue: Int
        let shellCmd = ShellCmd()

        let output = try shellCmd.runCapture("true")
        observedValue = output.exitStatus

        XCTAssertEqual(observedValue, expectedValue)
    }

    func testThat_ExitStatus_CanReturnFalse() async throws {
        let expectedValue = Int(EXIT_FAILURE)
        let observedValue: Int
        let shellCmd = ShellCmd()

        let output = try shellCmd.runCapture("false")
        observedValue = output.exitStatus

        XCTAssertEqual(observedValue, expectedValue)
    }

    func testThat_SingleCmd_CanWriteToStdin() async throws {
    }

    func testThat_SingleCmd_CanReadFromStdout() async throws {
    }

    func testThat_SingleCmd_CanReadFromStderr() async throws {
    }


    func testThat_SingleShellCommand_Works() async throws {
        let inputValue = "Hello World"
        let expectedValue = inputValue
        let observedValue: String

        let shellCmd = ShellCmd()
        let output: ShellCmd.Output = try shellCmd.runCapture("echo", inputValue)

        observedValue = output.stdout

        print("observedValue: \(observedValue)")
        XCTAssertEqual(observedValue, expectedValue)
    }
}
