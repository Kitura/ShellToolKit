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
    public let command: String
    public let fileManager: FileManager
    private let args: [String]
    private let spawnCmd: SpawnCmd
    private let spawnStatus: SpawnCmdStatus

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

    private var returnValue: Int?

    /// Command to execute when run() or runAsync() is called
    /// - Parameter command: Command name.  If a path is not specified, the PATH environment will be used ot search for the command.
    public init(command: String, args: [String] = [], environment: Environment = .passthru, fileManager: FileManager = .default) throws {
        self.command = command
        self.fileManager = fileManager
        self.args = args

        self.spawnCmd = SpawnCmd(command: command)
        self.spawnStatus = try spawnCmd.runAsync(args, environment: environment)
    }

    /// Wait for the process to terminate.
    ///
    /// If the process has already terminated, this will return immediately.
    /// - Returns: The exit code of the command.  Or -1 if there was an error.
    @discardableResult
    public func wait() -> Int {
        return self.spawnStatus.wait()
    }

    /// Get the exit code of the command if it has terminated.
    /// - Returns: Exit code of the command if it has terminated.  -1 otherwise
    public func getStatus() -> Int {
        return self.spawnStatus.exitStatus ?? -1
    }

    /// Returns true if the command has terminated
    public var hasTerminated: Bool {
        return self.spawnStatus.didFinishRunning
    }
}
