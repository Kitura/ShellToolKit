//
//  SpawnCmdStatus.swift
//  
//
//  Created by Danny Sung on 05/17/2022.
//

import Foundation

public protocol SpawnCmdStatus {
    var isRunning: Bool { get }

    var didFinishRunning: Bool { get }

    var exitStatus: Int? { get }

    @discardableResult
    func wait() -> Int
}

extension SpawnCmdStatus {
    var exitStatusIsSuccessful: Bool {
        return self.exitStatus == Int(EXIT_SUCCESS)
    }

    public func exitStatus() async -> Int {
        if let exitStatus = self.exitStatus {
            return exitStatus
        }
        return await withCheckedContinuation { continuation in
            let exitStatus = self.wait()
            continuation.resume(returning: exitStatus)
        }
    }
}
