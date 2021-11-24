//
//  Spawn.swift
//  
//
//  Created by Sung, Danny on 11/24/21.
//

import Foundation

/// Spawn is a convenient way to run other executables while passing through stdin/stdout.
///
/// This is especially useful when needing to support interactive console programs (such as vim), which neither the standard Process class nor SwiftShell is capable of.
/// This class is intended to behave like the system() call and provides no mechanism to control stdin/stdout/stderr.
public class Spawn {
    public let command: String
    
    /// Specify the environment to pass to pass to the command being spawned
    public enum Environment {
        /// The spawned process will have no environment variables
        case empty
        /// The spawned process will have the same environment variables as the parent
        case passthru
        /// The spawned process will have the environmenet variables specified
        case exact([String:String])
        /// The spawned process will have the same environment variables as the parent as well as the environmenet variables specified.
        ///
        /// If there are any duplicates, the environment variables specified will take precedence.
        case append([String:String])
    }
    
    public enum Failures: LocalizedError {
        case commandTooLong
        case argumentTooLong
        case permissionDenied
        case ioError
        case commandDoesNotExist
        case insufficientMemory
        case commandBusy
        case errno(Int32)
    }
    
    var pid: pid_t?
    var returnValue: Int?
    
    /// Command to execute when run() or runAsync() is called
    /// - Parameter command: Command name.  If a path is not specified, the PATH environment will be used ot search for the command.
    public init(command: String) {
        self.command = command
    }
    
    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    public func run(_ args: [String] = [], environment: Environment = .passthru) throws -> Int {
        try self.runAsync(args, environment: environment)
        return self.wait()
    }
    
    /// Run the command, but do not wait for it to terminate.
    ///
    /// You should cal wait() or getStatus() to determine the exit code of the program once terminated.
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Throws: `Spawn.Failures`
    public func runAsync(_ args: [String] = [], environment: Environment = .passthru) throws {
        let ccmd = command.cString(using: .utf8)!
        let cargs = args.map { strdup($0) } + [nil]
        let env: [String:String]
        
        switch environment {
        case .empty:
            env = [:]
        case .passthru:
            env = ProcessInfo.processInfo.environment
        case .exact(let dictionary):
            env = dictionary
        case .append(let dictionary):
            var dict = ProcessInfo.processInfo.environment
            dictionary.forEach { dict[$0] = $1 }
            env = dict
        }
        let cenv = env.map { strdup("\($0)=\($1)") } + [nil]
        defer {
            cargs.forEach { free($0) }
            cenv.forEach { free($0) }
        }
        
        var pid: pid_t = 0
        let retval = posix_spawnp(&pid, ccmd, nil, nil, cargs, cenv)
        switch retval {
        case 0:
            self.pid = pid
            return
        case E2BIG: throw Failures.argumentTooLong
        case EACCES: throw Failures.permissionDenied
        case EIO: throw Failures.ioError
        case ENAMETOOLONG: throw Failures.commandTooLong
        case ENOENT: throw Failures.commandDoesNotExist
        case ENOMEM: throw Failures.insufficientMemory
        case ETXTBSY: throw Failures.commandBusy
        default:
            throw Failures.errno(retval)
        }

    }
    
    /// Wait for the process to terminate.
    ///
    /// If the process has already terminated, this will return immediately.
    /// - Returns: The exit code of the command.  Or -1 if there was an error.
    @discardableResult
    public func wait() -> Int {
        return self.wait(shouldBlock: true)
    }
    
    /// Get the exit code of the command if it has terminated.
    /// - Returns: Exit code of the command if it has terminated.  -1 otherwise
    public func getStatus() -> Int {
        return self.wait(shouldBlock: false)
    }
    
    /// Returns true if the command has terminated
    public var hasTerminated: Bool {
        return self.getStatus() == -1
    }
    
    private func wait(shouldBlock: Bool) -> Int {
        guard let pid = self.pid else {
            return -1
        }
        if let returnValue = self.returnValue {
            return returnValue
        }
        var status: CInt = 0
        let options: Int32
        if shouldBlock {
            options = 0
        } else {
            options = WNOHANG
        }
        let rv = waitpid(pid, &status, options)
        
        if rv == 0 && WIFEXITED(status) {
            self.returnValue = Int(WEXITSTATUS(status))
        }
        return -1
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
