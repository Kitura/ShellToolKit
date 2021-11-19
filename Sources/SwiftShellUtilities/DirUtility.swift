//
//  DirUtility.swift
//  
//
//  Created by Sung, Danny on 2/7/21.
//

import Foundation
import SwiftShell

/// A collection of functions that operate on directories and filenames.
public class DirUtility {
    public static let shared = DirUtility()

    let fileManager: FileManager

    enum Failure: LocalizedError {
        case pathDoesNotExist(String)

        public var errorDescription: String? {
            switch self {
            case .pathDoesNotExist(let path):
                return "The path \"\(path)\"specified does not exist."
            }
        }
    }

    /// Create a new DirUtility instance
    /// - Parameter fileManager: If not specified, `FileManager.default` will be used.
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Recursively duplicate content of files from one path to another.
    ///
    /// - Parameters:
    ///   - from: filePath of source directory.  The contents of this directory will be duplicated into `to`
    ///   - to: filePath of destination directory.  This directory must exist prior to executing this command.
    /// - Throws: Any errors in this operation
    /// - Note: This specifically excludes ".git" direcotries.
    public func duplicateFiles(from: URL, to: URL) throws {
        let cmd = "(cd '\(from.path)' && tar -c -f - --exclude .git . ) | (cd '\(to.path)' && tar xf - )"
        
        try runAndPrint(bash: cmd)
    }
    
    /// Recursively substitute text in filenames and directory names.
    ///
    /// All files/directory under the specified path will be renamed such that any names containing `from` will be sustituted with `to`.
    ///
    /// For example, if from="From" and to="To', then "FileFromName.txt" will be renamed to "FileToName.txt"
    ///
    /// - Parameters:
    ///   - from: search text
    ///   - to: replace text
    ///   - path: directory path to recurse (substitution will not be performed on the path specified)
    public func renameItemsContaining(from: String, to: String, path: URL) throws {

        let contents = try fileManager.contentsOfDirectory(atPath: path.path)
        
        for content in contents {
            let contentPath = path.appendingPathComponent(content)
            if self.isDirectory(url: contentPath) {
                try renameItemsContaining(from: from, to: to, path: contentPath)
            }
            let origName = contentPath.lastPathComponent
            let newName = origName.replacingOccurrences(of: from, with: to)
            guard newName != origName else {
                continue
            }
            let newPath = path.appendingPathComponent(newName)
            try fileManager.moveItem(at: contentPath, to: newPath)
        }
    }

    /// Convenience function to get the file attribute type
    /// - Parameters:
    ///   - url: file URL to test
    /// - Returns: `FileAttributeType`
    /// - Throws: `DirUtility.Failure.pathDoesNotExist(path)` if path does not exist
    public func fileAttributeType(url: URL) throws -> FileAttributeType {
        guard fileManager.fileExists(atPath: url.path) else {
            throw DirUtility.Failure.pathDoesNotExist(url.path)
        }
        let attributes = try fileManager.attributesOfItem(atPath: url.path)

        return (attributes[.type] as? FileAttributeType) ?? .typeUnknown
    }

    /// Determine if a given file URL is not a directory
    /// - Parameters:
    ///   - url: file URL to test
    /// - Returns: `true` if path exists and is not a directory
    ///            `false` otherwise or if there is any problem in resolving the path.
    public func isFile(url: URL) -> Bool {
        guard let fileType = try? self.fileAttributeType(url: url) else {
            return false
        }
        return fileType != .typeDirectory
    }

    /// Determine if a given file URL is a regular file
    /// - Parameters:
    ///   - url: file URL to test
    /// - Returns: `true` if path exists and is a regular file.
    ///            `false` otherwise or if there is any problem in resolving the path.
    public func isRegularFile(url: URL) -> Bool {
        guard let fileType = try? self.fileAttributeType(url: url) else {
            return false
        }
        return fileType == .typeRegular
    }


    /// Determine if a given file URL is a directory
    /// - Parameters:
    ///   - fileManager: The default `FileManager` will be used if none is specified.
    ///   - url: file URL to test
    /// - Returns: `true` if path exists and is a directory
    ///            `false` otherwise or if there is any problem in resolving the path.
    public func isDirectory(url: URL) -> Bool {
        guard let fileType = try? self.fileAttributeType(url: url) else {
            return false
        }
        return fileType == .typeDirectory
    }

    /// Determine if a file exists
    /// - Parameter url: file URL to test
    /// - Returns: `true` if file exists at path.  `false` if it does not exist, path does not exist, or it is a symbolic link to a file that does not exist.
    /// Note: See `FileManager.fileExists(atPath:)` for more details.
    public func fileExists(url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    /// Remove a file/directory
    /// - Parameters:
    ///   - url: file URL to remove
    ///   - shouldTrash: If `true` (default), send item to trash rather than removing directly.  This parameter is ignored on Linux and always directly removes the item.
    /// - Returns: URL to object in trash if available
    @discardableResult
    public func removeItem(at url: URL, shouldTrash: Bool = true) throws -> URL? {
        var movedUrl: NSURL? = nil
#if os(Linux)
        try fileManager.removeItem(at: url)
#else
        if shouldTrash {
            try fileManager.trashItem(at: url, resultingItemURL: &movedUrl)
        } else {
            try fileManager.removeItem(at: url)
        }
#endif
        return movedUrl as URL?
    }
    
    /// Get path to executable (if available)
    ///
    /// - Note: Relies on /usr/bin/which
    /// - Parameter executable: executable name
    /// - Returns: Full path to executable
    public func executablePath(_ executable: String) -> String? {
        guard !executable.contains("/") else {
            return executable
        }
        let output = SwiftShell.run("/usr/bin/which", executable)
        guard output.succeeded else {
            return nil
        }
        let path = output.stdout
        return path.isEmpty ? executable : path
    }
    
    /// Determine if executable is in path
    /// - Parameter executable: executable name
    /// - Returns: true if in path; false otherwise
    public func isExecutableInPath(_ executable: String) -> Bool {
        return self.executablePath(executable) != nil
    }
    
    // MARK: Temporary directories
    @discardableResult
    /// Create a temporary directory
    /// - Returns: URL path to created directory
    public func createTemporaryDirectory() throws -> URL {
        let tempRootDir = fileManager.temporaryDirectory
        let tempBaseName = ProcessInfo.processInfo.processName + "." + randomNameString(length: 7)
        let tempDir = tempRootDir.appendingPathComponent(tempBaseName)
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: false, attributes: nil)
        
        return tempDir
    }
    
    /// Execute block within a temporary directory.
    ///
    /// The temporary directory will be removed once the block is finished.
    /// - Parameters:
    ///   - changeWorkingDirectory: If true (default), the current working directory of the process will be changed to the temporary directory for the duration of the block.  Once the block finishes, the current working directory will be restored.  This may have unexpected behavior in a threaded context.
    ///   - block: Block to execute with parameters (originalPath, temporaryDirectoryPath)
    public func inTemporaryDirectory(changeWorkingDirectory: Bool=true, _ block: (URL, URL) throws ->Void) throws {
        let tempDir = try createTemporaryDirectory()
        let origDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        if changeWorkingDirectory {
            fileManager.changeCurrentDirectoryPath(tempDir.path)
            
            try block(origDir, tempDir)
            
            fileManager.changeCurrentDirectoryPath(origDir.path)
        } else {
            try block(origDir, tempDir)
        }
        
        try fileManager.removeItem(at: tempDir)
    }
    
    // Source: https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    private func randomNameString(length: Int = 7)->String{
        enum s {
            static let c = Array("abcdefghjklmnpqrstuvwxyz12345789")
            static let k = UInt32(c.count)
        }
        
        var result = [Character](repeating: "-", count: length)
        
        for i in 0..<length {
            let r = Int(arc4random_uniform(s.k))
            result[i] = s.c[r]
        }
        
        return String(result)
    }
}

