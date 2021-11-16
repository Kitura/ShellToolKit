//
//  SystemActionOutput.swift
//  
//
//  Created by Sung, Danny on 11/15/21.
//

import Foundation

public struct SystemActionOutput {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int
    
    public var isSuccess: Bool {
        exitCode == 0
    }

    public init() {
        self.stdout = ""
        self.stderr = ""
        self.exitCode = .zero
    }
    
    public init(stdout: String, stderr: String, exitCode: Int) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
    
    /// Returns a new `SystemActionOutput` that appends the current and passed stdout and stderr streams.
    /// If an exitCode is specified, it will override the existing one
    /// - Parameters:
    ///   - stdout: stdout to append
    ///   - stderr: stderr to append
    ///   - exitCode: Use this exitCode if not nil
    /// - Returns: new `SystemActionOutput`
    public func appending(stdout: String, stderr: String, exitCode: Int?) -> SystemActionOutput {
        let returnExitCode = exitCode ?? self.exitCode
        return SystemActionOutput(stdout: self.stdout + stdout,
                                  stderr: self.stderr + stderr,
                                  exitCode: returnExitCode)
    }
}


