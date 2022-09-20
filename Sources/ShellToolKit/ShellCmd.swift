//
//  SpawnShell.swift
//  
//
//  Created by Danny Sung on 09/18/2022.
//

import Foundation

class ShellCmd {
    public var environment: Spawn.Environment {
        get {
            self.spawnCmd.environment
        }
        set {
            self.spawnCmd.environment = newValue
        }
    }
    public var context: Spawn.Context {
        get {
            self.spawnCmd.context
        }
        set {
            self.spawnCmd.context = newValue
        }
    }
    public let spawnCmd: SpawnCmd
    public let shell: String

    /// Command to execute when runAndWait() or runAsync() is called
    /// - Parameter command: Command name.  If a path is not specified, the PATH environment will be used ot search for the command.
    public init(shell: String?=nil, environment: Spawn.Environment?=nil, context: Spawn.Context?=nil) {

        if let shell = shell {
            self.shell = shell
        } else {
            let fallbackShells = [ "/bin/zsh", "/bin/bash", "/bin/ash" ]
            let fm = FileManager.default

            if let defaultShell = ProcessInfo.processInfo.environment["SHELL"] {
                self.shell = defaultShell
            } else {
                var fallbackShell: String?
                for shell in fallbackShells {
                    if fm.fileExists(atPath: shell) {
                        fallbackShell = shell
                        break
                    }
                }

                self.shell = fallbackShell ?? "/bin/sh" // last resort
            }
        }

        self.spawnCmd = SpawnCmd(command: self.shell, environment: environment, context: context)
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func runAndWait(_ command: [String] = [], environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) async throws -> Int {

        // do nothing if no command was given
        guard command.count > 0 else {
            return 0
        }

        let shellArgs = [ "-c", command.map({"'\($0)'"}).joined(separator: " ") ]
        return try await self.spawnCmd.runAndWait(shellArgs, environment: environment, stdin: stdin, stdout: stdout, stderr: stderr)
    }

    /// Run the command and wait for the results
    /// - Parameters:
    ///   - args: Arguments to pass to command
    ///   - environment: Specify the environment to pass to the command
    /// - Returns: The exit code of the program
    /// - Throws: `Spawn.Failures`
    @discardableResult
    public func runAndWait(_ command: String..., environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) async throws -> Int {

        return try await self.runAndWait(command, environment: environment, stdin: stdin, stdout: stdout, stderr: stderr)
    }



    // MARK: non-async versions

    @discardableResult
    public func runAndWait(_ command: String..., environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) throws -> Int {

        return try self.runAndWait(command, environment: environment, stdin: stdin, stdout: stdout, stderr: stderr)
    }

    @discardableResult
    public func runAndWait(_ command: [String] = [], environment: Spawn.Environment?=nil, stdin: Spawn.StreamWriterHandler = .discard, stdout: Spawn.StreamReaderHandler = .passthru, stderr: Spawn.StreamReaderHandler = .passthru) throws -> Int {

        return try self.runAndWait(command, environment: environment, stdin: stdin, stdout: stdout, stderr: stderr)
    }


    public struct Output {
        let exitStatus: Int
        let stdout: String
        let stderr: String

        var didSucceed: Bool {
            return exitStatus == Int(EXIT_SUCCESS)
        }
    }
    @discardableResult
    public func runAndWait(_ command: [String], environment: Spawn.Environment?=nil, stdin: String?=nil) throws -> Output {

        let stdinHandler: Spawn.StreamWriterHandler

        if let stdin = stdin {
            stdinHandler = .writer(Spawn.StringOutput(stdin))
        } else {
            stdinHandler = .discard
        }

        let stdoutCapture = Spawn.CaptureOutput()
        let stderrCapture = Spawn.CaptureOutput()

        // TODO: Need to somehow put the stream handlers in their own thread?  Should test this theory before major restructuring.

        let exitStatus = try self.runAndWait(command,
                                             environment: environment,
                                             stdin: stdinHandler,
                                             stdout: .reader(stdoutCapture),
                                             stderr: .reader(stderrCapture))

        return Output(exitStatus: exitStatus,
                      stdout: stdoutCapture.string,
                      stderr: stderrCapture.string)
    }

    @discardableResult
    public func runAndWait(_ command: String..., environment: Spawn.Environment?=nil, stdin: String?=nil) throws -> Output {

        return try self.runAndWait(command, environment: environment, stdin: stdin)
    }
}
