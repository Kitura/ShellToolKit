//
//  PTYPair.swift
//  
//
//  Created by Danny Sung on 05/17/2022.
//

import Foundation
import System

class PTYPair: FileHandlePair {
    var writeHandler: fileHandler? {
        didSet {
            if let writeHandler = writeHandler {
                self.primaryFileHandle.writeabilityHandler = { fileHandle in
                    writeHandler(fileHandle)
                }
            } else {
                self.primaryFileHandle.writeabilityHandler = nil
            }
        }
    }

    var readHandler: fileHandler? {
        didSet {
            if let readHandler = readHandler {
                self.primaryFileHandle.readabilityHandler = { fileHandle in
                    readHandler(fileHandle)
                }
            } else {
                self.primaryFileHandle.readabilityHandler = nil
            }
        }
    }

    var processStreamAttachment: Any {
        self.childFileHandle
    }

    let primaryFileHandle: FileHandle
    let childFileHandle: FileHandle

    public enum Failures: Error {
        case unableToCreateReadWriteHandle
    }

    init() throws {
        let primaryFd = posix_openpt(O_RDWR)
        guard primaryFd >= 0 else {
            throw System.Errno(rawValue: errno)
        }

        guard grantpt(primaryFd) == 0 else {
            throw System.Errno(rawValue: errno)
        }

        guard unlockpt(primaryFd) == 0 else {
            throw System.Errno(rawValue: errno)
        }

        let ptsPath = String(cString: ptsname(primaryFd))

        guard let childFileHandle = FileHandle(forUpdatingAtPath: ptsPath) else {
            throw Failures.unableToCreateReadWriteHandle
        }

        self.primaryFileHandle = FileHandle(fileDescriptor: primaryFd)
        self.childFileHandle = childFileHandle
    }

}
