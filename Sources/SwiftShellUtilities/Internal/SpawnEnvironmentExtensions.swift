//
//  SpawnEnvironmentExtensions.swift
//  
//
//  Created by Danny Sung on 05/16/2022.
//

import Foundation

internal extension Spawn.Environment {
    var dictionary: [String:String] {
        get {
            let env: [String:String]

            switch self {
            case .empty:
                env = [:]
            case .passthru:
                env = ProcessInfo.processInfo.environment
            case .exact(let dictionary):
                env = dictionary
            case .append(let dictionary):
                var dict = ProcessInfo.processInfo.environment
                dictionary.forEach { dict[$0] = $1 }
                env = dict
            }
            return env
        }
    }
}
