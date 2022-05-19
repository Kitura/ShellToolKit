//
//  FileDescriptorExtensions.swift
//  
//
//  Created by Danny Sung on 05/16/2022.
//

import Foundation
import System

internal extension FileDescriptor {
    var isBlocking: Bool {
        get {
            let flags = fcntl(self.rawValue, F_GETFL, 0)
            if (flags & O_NONBLOCK) == 0 {
                return true
            }
            return false
        }

        set {
            let orignalFlags = fcntl(self.rawValue, F_GETFL, 0)
            let newFlags: Int32

            if newValue {
                newFlags = orignalFlags & (~O_NONBLOCK)
            } else {
                newFlags = orignalFlags | O_NONBLOCK
            }

            guard orignalFlags != newFlags else { return }
            _ = fcntl(self.rawValue, F_SETFL, newFlags)
        }
    }
}
