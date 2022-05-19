//
//  SpawnCmdStatus.swift
//  
//
//  Created by Danny Sung on 05/11/2022.
//

import Foundation

public class SpawnCmdStatusPid: SpawnCmdStatus {
    public let pid: pid_t
    private let monitor: ChildProcessMonitor

    init(pid: pid_t) {
        self.pid = pid
        self.monitor = ChildProcessMonitor(pid: pid)
    }

    public var isRunning: Bool {
        self.monitor.isRunning
    }

    public var didFinishRunning: Bool {
        self.monitor.didFinishRunning
    }

    public var exitStatus: Int? {
        self.monitor.status
    }

    public func wait() -> Int {
        return self.monitor.waitStatus()
    }
}
