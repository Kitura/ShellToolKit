import Foundation
import XCTest
@testable import ShellToolKit

final class SpawnTests: XCTestCase {

    func testThat_True_ExitCodeIsZero() throws {
        let inputValue = "true"
        let expectedValue = 0
        
        let s = try Spawn.run(inputValue)
        let resolvedValue = s.wait()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

    func testThat_False_ExitCodeIsOne() throws {
        let inputValue = "false"
        let expectedValue = 1
        
        let s = try Spawn.run(inputValue)
        let resolvedValue = s.wait()
        
        XCTAssertEqual(expectedValue, resolvedValue)
    }

    func testThat_True_ExitCodeIsSuccess() throws {
        let inputValue = "true"
        let expectedValue = true
        let observedValue: Bool

        let s = try Spawn.run(inputValue)
        s.wait()

        observedValue = s.exitStatusIsSuccessful

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_False_ExitCodeIsNotSuccess() throws {
        let inputValue = "false"
        let expectedValue = false
        let observedValue: Bool

        let s = try Spawn.run(inputValue)
        s.wait()

        observedValue = s.exitStatusIsSuccessful

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_Echo_WithPty_CanReadFromStdout() throws {
        let inputValue = "hello world"
        let expectedValue = inputValue
        var observedValue: String?

        let task = try Spawn.run("/bin/echo", args: ["-n", inputValue], ioMode: .pty, stdout: .readerBlock({ handle in

            let data = handle.availableData
            guard !data.isEmpty else { return }

            observedValue = String(data: data, encoding: .utf8)!
        }))

        task.wait()

        XCTAssert(task.exitStatusIsSuccessful)

        XCTAssertEqual(expectedValue, observedValue)
    }
    

    func testThat_Echo_WithPipe_CanReadFromStdout() throws {
        let inputValue = "hello world"
        let expectedValue = inputValue
        var observedValue: String?

        let task = try Spawn.run("/bin/echo", args: ["-n", inputValue], ioMode: .pipe, stdout: .readerBlock({ handle in

            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            observedValue = String(data: data, encoding: .utf8)!
        }))

        task.wait()

        XCTAssert(task.exitStatusIsSuccessful)

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_tr_WillTranslateStdin() throws {
        let inputValue = "hello world"
        let expectedValue = "HELLO WORLD"
        var observedValue: String?

//        let filter = Spawn.FilterOutput { data in
//            return .init(outputData: data, numberOfBytesConsumed: data.count, isEndOfFile: true)
//        }

        let inputData = inputValue.data(using: .utf8)!
        let streamOutput = Spawn.StreamOutput {
            return .init(data: inputData, isEndOfFile: true)
        }

        let streamInput = Spawn.StreamInput { input in
            let string = String(data: input.data, encoding: .utf8)
            observedValue = string
        }

        let task = try Spawn.run("/usr/bin/tr", args: ["a-z", "A-Z"], ioMode: .pipe, stdin: .writerBlock(streamOutput.writeHandler), stdout: .readerBlock(streamInput.readHandler))

        task.wait()
        XCTAssert(task.exitStatusIsSuccessful)
        XCTAssertEqual(expectedValue, observedValue)
    }
}
