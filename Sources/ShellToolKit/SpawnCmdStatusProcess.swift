//
//  SpawnCmdStatusProcess.swift
//  
//
//  Created by Danny Sung on 05/17/2022.
//

import Foundation

public class SpawnCmdStatusProcess: SpawnCmdStatus {
    public let process: Process
    private let fileHandlePairs: [FileHandlePair]
    private var terminationStatus: Int?

    // Note: Even thoguh we do not use `fileHandlePairs`, we must retain them here until the process terminates otherwise their handlers will not be called.
    init(process: Process, fileHandlePairs: [FileHandlePair] = []) {
        self.process = process
        self.fileHandlePairs = fileHandlePairs
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

    public func exitStatus() async -> Int {
        if let terminationStatus = terminationStatus {
            return terminationStatus
        }
        return await withCheckedContinuation { continuation in
            let exitStatus = self.wait()
            continuation.resume(returning: exitStatus)
        }
    }

    public func wait() -> Int {
        if let terminationStatus = terminationStatus {
            return terminationStatus
        }

        self.process.waitUntilExit()
        let terminationStatus = Int(self.process.terminationStatus)
        self.terminationStatus = terminationStatus

        return terminationStatus
    }
}
