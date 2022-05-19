//
//  File.swift
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
