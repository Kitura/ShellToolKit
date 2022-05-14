//
//  SpawnCmdStatus.swift
//  
//
//  Created by Danny Sung on 05/11/2022.
//

import Foundation

public class SpawnCmdStatus {
    public let pid: pid_t
    private let monitor: ChildProcessMonitor

    init(pid: pid_t) {
        self.pid = pid
        self.monitor = ChildProcessMonitor(pid: pid)
    }

    var isRunning: Bool {
        self.monitor.isRunning
    }

    var didFinishRunning: Bool {
        self.monitor.didFinishRunning
    }

    var exitStatus: Int? {
        self.monitor.status
    }

    func wait() -> Int {
        return self.monitor.waitStatus()
    }
}
