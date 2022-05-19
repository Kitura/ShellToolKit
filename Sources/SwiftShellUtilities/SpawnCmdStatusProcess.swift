//
//  SpawnCmdStatusProcess.swift
//  
//
//  Created by Danny Sung on 05/17/2022.
//

import Foundation

public class SpawnCmdStatusProcess: SpawnCmdStatus {
    public let process: Process

    init(process: Process) {
        self.process = process
    }

    public var isRunning: Bool {
        self.process.isRunning
    }

    public var didFinishRunning: Bool {
        !self.process.isRunning
    }

    public var exitStatus: Int? {
        guard self.didFinishRunning else { return nil }
        return Int(self.process.terminationStatus)
    }

    public func wait() -> Int {
        self.process.waitUntilExit()
        return Int(self.process.terminationStatus)
    }
}
