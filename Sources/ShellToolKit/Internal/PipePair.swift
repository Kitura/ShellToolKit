//
//  PipePair.swift
//  
//
//  Created by Danny Sung on 05/24/2022.
//

import Foundation

class PipePair: FileHandlePair {
    var writeHandler: fileHandler? {
        didSet {
            if let writeHandler = writeHandler {
                self.pipe.fileHandleForWriting.writeabilityHandler = { handle in
                    writeHandler(handle)
                }
            } else {
                self.pipe.fileHandleForWriting.writeabilityHandler = nil
            }
        }
    }

    var readHandler: fileHandler? {
        didSet {
            if let readHandler = readHandler {
                self.pipe.fileHandleForReading.readabilityHandler = { handle in
                    readHandler(handle)
                }
            } else {
                self.pipe.fileHandleForReading.readabilityHandler = nil
            }
        }
    }

    var processStreamAttachment: Any {
        return pipe
    }

    let pipe: Pipe

    init() {
        self.pipe = Pipe()
    }
}
