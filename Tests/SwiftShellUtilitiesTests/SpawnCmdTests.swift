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

    func testThat_SpawnCmd_WithPipe_IsSuccessful() throws {
        let inputValue = "hello world"
        let expectedValue = inputValue
        var observedValue: String?

        let cmd = SpawnCmd(command: "/bin/echo")
        let task = try cmd.runAsync(["-n", inputValue], ioMode: .pipe, stdout: .reader({ handle in

            let data = handle.availableData
            guard !data.isEmpty else { return }

           observedValue = String(data: data, encoding: .utf8)!
        }))

        task.wait()

        XCTAssert(task.exitStatusIsSuccessful)

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_SpawnCmd_WithPty_IsSuccessful() async throws {
        let inputValue = "hello world"
        let expectedValue = inputValue
        var observedValue: String?

        let cmd = SpawnCmd(command: "/bin/echo")
        let task = try cmd.runAsync(["-n", inputValue], ioMode: .pty, stdout: .reader({ handle in

            let data = handle.availableData
//            print(" got \(data.count) bytes")
            guard !data.isEmpty else { return }

            observedValue = String(data: data, encoding: .utf8)!
//            print("read value: \(observedValue)")
        }), stderr: .discard)

        let exitStatus = await task.exitStatus()
        print("> exit status: \(exitStatus)")

        XCTAssert(task.exitStatusIsSuccessful)

        XCTAssertEqual(expectedValue, observedValue)
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

    func test_trial() throws {
        let task = Process()
//        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/vim")
        var fhPair = try SpawnCmd.IOMode.pty.createFileHandlePair()!
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
