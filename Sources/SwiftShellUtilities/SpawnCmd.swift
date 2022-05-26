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
    public var environment: Spawn.Environment
    public var context: Spawn.Context

    /// Command to execute when runAndWait() or runAsync() is called
    /// - Parameter command: Command name.  If a path is not specified, the PATH environment will be used ot search for the command.
    public init(command: String, environment: Spawn.Environment?=nil, context: Spawn.Context?=nil) {
        self.command = command
        self.environment = environment ?? .passthru
        self.context = context ?? Spawn.defaultContext
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func runAndWait(_ args: [String] = [], environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) async throws -> Int {
        let cmdStatus = try await Spawn.runAndWait(context: self.context, self.command, args: args, stdin: stdin, stdout: stdout, stderr: stderr)
        return cmdStatus
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func runAndWait(_ args: String..., environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) async throws -> Int {
        return try await self.runAndWait(args, environment: environment, stdin: stdin, stdout: stdout, stderr: stderr)
    }


}
