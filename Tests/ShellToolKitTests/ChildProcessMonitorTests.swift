import Foundation
import Darwin
import XCTest
@testable import ShellToolKit

final class ChildProcessMonitorTests: XCTestCase {
    let nonexistantPid: pid_t = 31234 // some arbitrary number

    func testThat_NonExistantPID_ReturnsNil() throws {
        let processMonitor = ChildProcessMonitor(pid: nonexistantPid)

        XCTAssertNil(processMonitor.status)
    }

    func testThat_NonExistantPID_IsNotRunning() throws {
        let processMonitor = ChildProcessMonitor(pid: nonexistantPid)

        let expectedValue = false
        let observedValue = processMonitor.isRunning

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_ExistantPidNotChild_IsNotRunning() throws {
        let processMonitor = ChildProcessMonitor(pid: 1) // init always runs as pid 1

        let expectedValue = false
        let observedValue = processMonitor.isRunning

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_ExistantPidOfChild_IsRunning() throws {
        let pid = unsafeFork()

        if pid == 0 {
            sleep(2)
            exit(0)
        }
        print("child pid: \(pid)")
        XCTAssertTrue(pid > 0, "pid invalid: \(errno)")
        let processMonitor = ChildProcessMonitor(pid: pid)

        let expectedValue = true
        let observedValue = processMonitor.isRunning

        XCTAssertEqual(expectedValue, observedValue)
    }


    func testThat_RunningChild_IsNotComplete() throws {
        let pid = unsafeFork()

        if pid == 0 {
            sleep(2)
            exit(0)
        }
        print("child pid: \(pid)")
        XCTAssertTrue(pid > 0, "pid invalid: \(errno)")
        let processMonitor = ChildProcessMonitor(pid: pid)

        let expectedValue = false
        let observedValue = processMonitor.didFinishRunning

        XCTAssertEqual(expectedValue, observedValue)
    }

    func testThat_FinishedChild_IsComplete() throws {
        let pid = unsafeFork()

        if pid == 0 {
            exit(0)
        }
        print("child pid: \(pid)")
        XCTAssertTrue(pid > 0, "pid invalid: \(errno)")
        let processMonitor = ChildProcessMonitor(pid: pid)

        sleep(1)
        let expectedValue = true
        let observedValue = processMonitor.didFinishRunning

        XCTAssertEqual(expectedValue, observedValue)
    }

}


// ref: https://gist.github.com/bugaevc/4307eaf045e4b4264d8e395b5878a63b
fileprivate func unsafeFork() -> pid_t {
    let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
    let forkPtr = dlsym(RTLD_DEFAULT, "fork")
    typealias ForkType = @convention(c) () -> Int32
    let fork = unsafeBitCast(forkPtr, to: ForkType.self)

    return fork()
}

