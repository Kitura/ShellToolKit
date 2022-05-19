//
//  SpawnCmd.swift
//  
//
//  Created by Danny Sung on 05/11/2022.
//

import Foundation
import System
import SwiftShell

/// Spawn is a convenient way to run other executables while passing through stdin/stdout.
///
/// This is especially useful when needing to support interactive console programs (such as vim), which neither the standard Process class nor SwiftShell is capable of.
/// This class is intended to behave like the system() call and provides no mechanism to control stdin/stdout/stderr.
public class SpawnCmd {
    public let command: String
    public var fileManager: FileManager
    public var environment: Spawn.Environment

    var pid: pid_t?
    var returnValue: Int?

    /// Command to execute when run() or runAsync() is called
    /// - Parameter command: Command name.  If a path is not specified, the PATH environment will be used ot search for the command.
    public init(command: String, environment: Spawn.Environment?=nil) {
        self.command = command
        self.fileManager = FileManager.default
        self.environment = environment ?? .passthru
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func run(_ args: [String] = [], environment: Spawn.Environment?=nil) throws ->  Int {
        let cmdStatus = try self.runAsync(args, environment: environment)
        return cmdStatus.wait()
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func run(_ args: String..., environment: Spawn.Environment?=nil) throws -> Int {
        return try self.run(args, environment: environment)
    }

    /// Run the command, but do not wait for it to terminate.
    ///
    /// You should call wait() or getStatus() to determine the exit code of the program once terminated.
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Throws: `Spawn.Failures`
    /// - Note: argv[0] for the calling app will be set to the path to the file discovered if it was found via the PATH environment.  Otherwise it will be whatever was given from `self.command`.
    @discardableResult
    public func runAsync(_ args: [String] = [], environment: Spawn.Environment?=nil) throws -> SpawnCmdStatus {
        let env = (environment ?? self.environment).dictionary
        return try self.runAsyncNoPty(args, environment: env)
    }

    @discardableResult
    private func runAsyncNoPty(_ args: [String], environment: [String:String]) throws -> SpawnCmdStatus {
        let filename = try self.fileManager.findFileInPath(filename: self.command)
        let ccmd = filename.cString(using: .utf8)!
        let cargs = ([filename] + args).map { strdup($0) } + [nil]
        let cenv = environment.map { strdup("\($0)=\($1)") } + [nil]
        defer {
            cargs.forEach { free($0) }
            cenv.forEach { free($0) }
        }

        var pid: pid_t = 0
        let retval = posix_spawn(&pid, ccmd, nil, nil, cargs, cenv)
        switch retval {
        case 0:
            self.pid = pid
            return SpawnCmdStatusPid(pid: pid)
        default:
            throw System.Errno(rawValue: retval)
        }
    }

    // TODO: need to implement something to handle stdin/stdout/stderr
    @discardableResult
    private func runAsyncPty(_ args: [String], environment: [String:String]) throws -> SpawnCmdStatus {
        let filename = try self.fileManager.findFileInPath(filename: self.command)
        let fileUrl = URL(fileURLWithPath: filename)

        print("attempting to run: \(fileUrl)")
        let pty = try PTYPair()
        let task = Process()
        task.executableURL = fileUrl
        task.arguments = args
        task.environment = environment

        pty.primaryFileHandle.readabilityHandler = { handle in
            print("> available data: \(handle.availableData.count) bytes")
            let s = String(data: handle.availableData, encoding: .utf8)!
            print(s)
        }

        try task.run()
        return SpawnCmdStatusProcess(process: task)
    }

    /// Run the command, but do not wait for it to terminate.
    ///
    /// You should call wait() or getStatus() to determine the exit code of the program once terminated.
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Throws: `Spawn.Failures`
    ///
    @discardableResult
    public func runAsync(_ args: String..., environment: Spawn.Environment = .passthru) throws -> SpawnCmdStatus {
        return try self.runAsync(args, environment: environment)
    }
}
