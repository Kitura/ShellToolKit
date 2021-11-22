//
//  Print.swift
//  
//
//  Created by Sung, Danny on 11/21/21.
//

import Foundation

/// Convenience for printing to different streams
/// - Parameters:
///   - to: `PrintContext` to use (default: .stdout)
///   - string: Text to print
public func print(to fileHandle: FileHandle, _ string: String) {
    fileHandle.write(Data(string.utf8))
}
