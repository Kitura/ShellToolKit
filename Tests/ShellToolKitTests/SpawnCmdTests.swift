import Foundation
import XCTest
@testable import ShellToolKit

final class SpawnCmdTests: XCTestCase {

    func testThat_Echo_Pipe_CanReadStdout() async throws {
        let inputValue = "Hello World"
        let expectedValue = inputValue
        let observedValue: String

        let cmd = SpawnCmd(command: "/bin/echo")
        cmd.context = Spawn.Context(defaultIoMode: .pipe)
        let capture = Spawn.CaptureOutput()
        try await cmd.runAndWait(["-n", inputValue], stdout: .reader(capture.readHandler))

        observedValue = String(data: capture.data, encoding: .utf8)!
        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_Echo_Pty_CanReadStdout() async throws {
        let inputValue = "Hello World"
        let expectedValue = inputValue
        let observedValue: String

        let cmd = SpawnCmd(command: "/bin/echo")
        cmd.context = Spawn.Context(defaultIoMode: .pty)
        let capture = Spawn.CaptureOutput()
        try await cmd.runAndWait(["-n", inputValue], stdout: .reader(capture.readHandler))

        observedValue = String(data: capture.data, encoding: .utf8)!
        XCTAssertEqual(expectedValue, observedValue)
    }


    func test_trial() throws {
        let task = Process()
//        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/vim")
        var fhPair = try Spawn.IOMode.pty.createFileHandlePair()!
        fhPair.readHandler = { handle in
            let data = handle.availableData
            print("> available data: \(data.count) bytes")
            let s = String(data: data, encoding: .utf8)!
            print(s)
        }
        task.executableURL = URL(fileURLWithPath: "/bin/echo")
        task.arguments = ["-n", "hello world"]
        task.standardInput = nil
//        task.standardOutput = try getHandle()  // why doesn't this work??
        task.standardOutput = fhPair.processStreamAttachment
        task.standardError = nil

        print("stdin: \(task.standardInput)")
        print("stdout: \(task.standardOutput)")
        print("stderr: \(task.standardError)")

        print("> Running task...")
        try task.run()

        print("> Waiting for task to complete.")
        task.waitUntilExit()

        print("> Status code: \(task.terminationStatus)")

//        h.doSomething()
    }
    func getHandler() -> ((FileHandle)->Void) {
        return { handle in
            let data = handle.availableData
            print("> available data: \(data.count) bytes")
            let s = String(data: data, encoding: .utf8)!
            print(s)
        }
    }

    func getHandle() throws -> FileHandle {
        let pty = try PTYPair()
        let handler: (FileHandle)->Void = getHandler()

        pty.primaryFileHandle.readabilityHandler = handler

        return pty.childFileHandle
    }

    class Handler {
        let pty: PTYPair
        init() throws {
            self.pty = try PTYPair()
        }

        func setup() {
            self.pty.primaryFileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                print("> available data: \(data.count) bytes")
                let s = String(data: data, encoding: .utf8)!
                print(s)
            }
        }

        func getStandardOutput() -> Any {
            return self.pty.childFileHandle
        }

        func doSomething() {
            print("hello")
        }
    }

    func test_works2() throws {
        let task = Process()
//        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/vim")
        let h = try Handler()
        h.setup()
        task.executableURL = URL(fileURLWithPath: "/bin/echo")
        task.arguments = ["hello world"]
        task.standardInput = nil
//        task.standardOutput = try getHandle()  // why doesn't this work??
        task.standardOutput = h.getStandardOutput()
        task.standardError = nil

        print("> Running task...")
        try task.run()

        print("> Waiting for task to complete.")
        task.waitUntilExit()

//        h.doSomething()
    }

    func test_works() throws {
        let pty = try PTYPair()
        let task = Process()
//        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/vim")
        task.executableURL = URL(fileURLWithPath: "/bin/echo")
        task.arguments = ["hello world"]
        task.standardInput = nil
        task.standardOutput = pty.childFileHandle
        task.standardError = nil

        pty.primaryFileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            print("> available data: \(data.count) bytes")
            let s = String(data: data, encoding: .utf8)!
            print(s)
        }

        print("> Running task...")
        try task.run()

        print("> Waiting for task to complete.")
        task.waitUntilExit()

    }
}
