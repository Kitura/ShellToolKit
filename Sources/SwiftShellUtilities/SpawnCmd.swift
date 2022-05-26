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


    public enum StreamReaderHandler: Equatable {
        public static func == (lhs: SpawnCmd.StreamReaderHandler, rhs: SpawnCmd.StreamReaderHandler) -> Bool {
            switch (lhs, rhs) {
            case (.discard, .discard): return true
            case (.passthru, .passthru): return true
            case (.reader(_), .reader(_)): return false
            default:
                return false
            }
        }

        case discard
        case passthru
        case reader((FileHandle) -> Void)
    }
    public enum StreamWriterHandler: Equatable {
        public static func == (lhs: SpawnCmd.StreamWriterHandler, rhs: SpawnCmd.StreamWriterHandler) -> Bool {
            switch (lhs, rhs) {
            case (.discard, .discard): return true
            case (.passthru, .passthru): return true
            case (.writer(_), .writer(_)): return false
            default:
                return false
            }
        }

        case discard
        case passthru
        case writer((FileHandle) -> Void)
    }

    public enum IOMode {
        case pty
        case passthru
        case pipe

        func createFileHandlePair() throws -> FileHandlePair? {
            switch self {
            case .pty:
                return try PTYPair()
            case .passthru:
                return nil
            case .pipe:
                return PipePair()
            }
        }

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
    public func runAsync(_ args: [String] = [], environment: Spawn.Environment?=nil, ioMode: IOMode = .passthru, stdin: StreamWriterHandler = .discard, stdout: StreamReaderHandler = .passthru, stderr: StreamReaderHandler = .passthru) throws -> SpawnCmdStatus {

        let env = (environment ?? self.environment).dictionary

        if ioMode == .passthru {
            return try self.runAsyncPtyPassthru(args, environment: env)
        } else {
            return try self.runAsyncStandardIOCapture(args, environment: env, ioMode: ioMode, stdin: stdin, stdout: stdout, stderr: stderr)
        }
    }

    @discardableResult
    private func runAsyncPtyPassthru(_ args: [String], environment: [String:String]) throws -> SpawnCmdStatus {
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
            return SpawnCmdStatusPid(pid: pid)
        default:
            throw System.Errno(rawValue: retval)
        }
    }

    @discardableResult
    private func runAsyncStandardIOCapture(_ args: [String], environment: [String:String], ioMode: IOMode, stdin: StreamWriterHandler, stdout: StreamReaderHandler, stderr: StreamReaderHandler) throws -> SpawnCmdStatus {
        let filename = try self.fileManager.findFileInPath(filename: self.command)
        let fileUrl = URL(fileURLWithPath: filename)

        let task = Process()
        task.executableURL = fileUrl
        task.arguments = args
        task.environment = environment

        var fileHandlePairs: [FileHandlePair] = []

        switch stdin {
        case .discard:
            task.standardInput = nil
        case .passthru:
            break
        case .writer(let writeHandler):
            if var fhPair = try ioMode.createFileHandlePair() {
                fhPair.writeHandler = writeHandler
                fileHandlePairs.append(fhPair)

                task.standardInput = fhPair.processStreamAttachment
            }
        }

        switch stdout {
        case .discard:
            task.standardOutput = nil
        case .passthru:
            break
        case .reader(let readHandler):
            if var fhPair = try ioMode.createFileHandlePair() {
                fhPair.readHandler = readHandler
                fileHandlePairs.append(fhPair)

                task.standardOutput = fhPair.processStreamAttachment
            }
        }

        switch stderr {
        case .discard:
            task.standardError = nil
        case .passthru:
            break
        case .reader(let readHandler):
            if var fhPair = try ioMode.createFileHandlePair() {
                fhPair.readHandler = readHandler
                fileHandlePairs.append(fhPair)

                task.standardError = fhPair.processStreamAttachment
            }
        }

        try task.run()
        return SpawnCmdStatusProcess(process: task, fileHandlePairs: fileHandlePairs)
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
