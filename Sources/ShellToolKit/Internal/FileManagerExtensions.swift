//
//  FileManagerExtensions.swift
//  
//
//  Created by Danny Sung on 05/11/2022.
//

import Foundation
import System

internal extension FileManager {
    /// Search PATH for file
    /// - Parameter filename: If `filename` does not contain a "/", then the PATH environment is searched in order for the.  If `filename` contains a "/", then simply test for the existence of `filename`
    /// - Returns: Path to file
    /// - Throws: `System.Errno.noSuchFileOrDirectory` if file could not be found
    /// - Note: This function only tests the existes of the file, it does not ensure the file is executable.
    func findFileInPath(filename: String) throws -> String {
        guard !filename.contains("/") else {
            guard self.fileExists(atPath: filename) else {
                throw System.Errno.noSuchFileOrDirectory
            }
            return filename
        }
        guard let pathValue = ProcessInfo.processInfo.environment["PATH"] else {
            return filename
        }
        let pathDirs = pathValue.components(separatedBy: ":").map({ URL(fileURLWithPath: $0 )})
        for pathDir in pathDirs {
            let pathToFile = pathDir.appendingPathComponent(filename).path
            if self.fileExists(atPath: pathToFile) {
                return pathToFile
            }
        }

        throw System.Errno.noSuchFileOrDirectory
    }
}
