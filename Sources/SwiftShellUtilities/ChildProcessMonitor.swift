//
//  ChildProcessMonitor.swift
//  
//
//  Created by Danny Sung on 05/11/2022.
//

import Foundation
import System

public class ChildProcessMonitor {
    private let pid: pid_t
    private var pidStatus: Int32?
    private var exitStatus: Int?
    private var pidErrno: System.Errno?

    public init(pid: pid_t) {
        self.pid = pid
        self.exitStatus = nil
        self.pidStatus = nil
        self.pidErrno = nil
    }

    public var status: Int? {
        return self.wait(shouldBlock: false)
    }

    public func waitStatus() -> Int {
        return self.wait(shouldBlock: true)!
    }

    public var isRunning: Bool {
        self.updateStatus()

        if self.exitStatus != nil {
            return false
        } else if pidErrno == .noSuchFileOrDirectory {
            return false
        } else if pidErrno == .noChildProcess {
            return false
        }

        return true
    }

    public var didFinishRunning: Bool {
        self.updateStatus()

        if self.exitStatus != nil {
            return true
        }
        return false
    }

    private func updateStatus() {
        self.wait(shouldBlock: false)
    }

    @discardableResult
    private func wait(shouldBlock: Bool) -> Int? {
        if let exitStatus = self.exitStatus {
            return exitStatus
        }
        var status: CInt = -1
        let options: CInt
        if shouldBlock {
            options = 0
        } else {
            options = WNOHANG //| WUNTRACED
        }

        var waitTime: useconds_t = 1000
        var rv: pid_t
        var errorNumber = System.Errno(rawValue: errno)
        repeat {
            rv = waitpid(pid, &status, options)
            errorNumber = System.Errno(rawValue: errno)
            if rv == -1 {
                switch errorNumber {
                case .interrupted:
                    // Sometimes we can be interrupted trying to get the status, so let's try again until we're not interrupted
                    usleep(waitTime)
                    waitTime *= 2 // exponential backoff
                default:
                    print("error: \(errorNumber.rawValue): \(errorNumber.debugDescription)")
                    self.pidErrno = errorNumber
                }

            }
        } while rv == -1 && errorNumber == .interrupted

        if status > -1 {
            self.pidStatus = status
        }
        if rv == pid && WIFEXITED(status) {
            let exitStatus = Int(WEXITSTATUS(status))
            self.exitStatus = exitStatus
            return exitStatus
        }
        return nil
    }

    //
    // Taken from Swift.org swift/stdlib/private/SwiftPrivateLibcExtras/SwiftPrivateLibcExtras.swift
    //
    private func _WSTATUS(_ status: CInt) -> CInt {
        return status & 0x7f
    }

    private var _WSTOPPED: CInt {
        return 0x7f
    }

    private func WIFEXITED(_ status: CInt) -> Bool {
        return _WSTATUS(status) == 0
    }

    private func WIFSIGNALED(_ status: CInt) -> Bool {
        return _WSTATUS(status) != _WSTOPPED && _WSTATUS(status) != 0
    }

    private func WEXITSTATUS(_ status: CInt) -> CInt {
        return (status >> 8) & 0xff
    }

    private func WTERMSIG(_ status: CInt) -> CInt {
        return _WSTATUS(status)
    }
}
