//
//  Spawn.swift
//
//
//  Created by Sung, Danny on 05/11/2022
//

import Foundation
import System

/// Spawn is a convenient way to run other executables while passing through stdin/stdout.
///
/// This is especially useful when needing to support interactive console programs (such as vim), which neither the standard Process class nor SwiftShell is capable of.
/// This class is intended to behave like the system() call and provides no mechanism to control stdin/stdout/stderr.
public class Spawn {
    public struct Context {
        public let defaultEnvironment: Environment
        public let defaultIoMode: IOMode
        public let fileManager: FileManager

        public init(defaultEnvironment: Environment?=nil,
                    defaultIoMode: IOMode?=nil,
                    fileManager: FileManager?=nil) {
            self.defaultEnvironment = defaultEnvironment ?? .passthru
            self.defaultIoMode = defaultIoMode ?? .passthru
            self.fileManager = fileManager ?? .default
        }
    }

    public static let defaultContext = Context()

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

    public enum StreamReaderHandler: Equatable {
        public static func == (lhs: StreamReaderHandler, rhs: StreamReaderHandler) -> Bool {
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
        public static func == (lhs: StreamWriterHandler, rhs: StreamWriterHandler) -> Bool {
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
    /// You should call wait() or getStatus() on the returned object to determine the exit code of the program once terminated.
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Throws: `Spawn.Failures`
    /// - Note: argv[0] for the calling app will be set to the path to the file discovered if it was found via the PATH environment.  Otherwise it will be whatever was given from `self.command`.
    @discardableResult
    static public func run(context: Context = Spawn.defaultContext, _ command: String, args: [String] = [], environment: Spawn.Environment?=nil, ioMode: IOMode? = nil, stdin: StreamWriterHandler = .discard, stdout: StreamReaderHandler = .passthru, stderr: StreamReaderHandler = .passthru) throws -> SpawnCmdStatus {

        let env = (environment ?? context.defaultEnvironment).dictionary

        let io = ioMode ?? context.defaultIoMode

        if io == .passthru {
            return try self.runPtyPassthru(context: context, command: command, args: args, environment: env)
        } else {
            return try self.runStandardIOCapture(context: context, command: command, args: args, environment: env, ioMode: io, stdin: stdin, stdout: stdout, stderr: stderr)
        }
    }

    @discardableResult
    static public func runAndWait(context: Context = Spawn.defaultContext, _ command: String, args: [String] = [], environment: Spawn.Environment?=nil, ioMode: IOMode?=nil, stdin: StreamWriterHandler = .discard, stdout: StreamReaderHandler = .passthru, stderr: StreamReaderHandler = .passthru) async throws -> Int {

        let task = try self.run(context: context, command, args: args, environment: environment, ioMode: ioMode, stdin: stdin, stdout: stdout, stderr: stderr)

        return await task.exitStatus()
    }

}

// MARK: - Private Methods

extension Spawn {
    @discardableResult
    static private func runPtyPassthru(context: Context, command: String, args: [String], environment: [String:String]) throws -> SpawnCmdStatus {
        let fileManager = context.fileManager
        let filename = try fileManager.findFileInPath(filename: command)
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
    static private func runStandardIOCapture(context: Context, command: String, args: [String], environment: [String:String], ioMode: IOMode, stdin: StreamWriterHandler, stdout: StreamReaderHandler, stderr: StreamReaderHandler) throws -> SpawnCmdStatus {
        let fileManager = context.fileManager
        let filename = try fileManager.findFileInPath(filename: command)
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

}
