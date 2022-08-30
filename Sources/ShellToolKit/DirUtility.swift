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
    
    // MARK: Temporary filenames
    /// Create a filename suitable for temporary use
    /// - Parameter fileExtension: File extension to use (default: no extension)
    /// - Returns: file URL to file
    /// - Note: The file is guaranteed not to exist at the time of this call, but the file is not created.
    public func temporaryFilename(ofType fileExtension: String?=nil) -> URL {
        let tempRootDir = FileManager.default.temporaryDirectory
        let tempBaseName = ProcessInfo.processInfo.processName + "." + randomNameString(length: 8)
        
        var tempFile = tempRootDir.appendingPathComponent(tempBaseName)
        if let fileExtension = fileExtension {
            tempFile = tempFile.appendingPathExtension(fileExtension)
        }
        
        if self.fileManager.fileExists(atPath: tempFile.path) {
            return self.temporaryFilename(ofType: fileExtension)
        }
        return tempFile
    }
    
    public enum TemporaryFileAction {
        case removeFile
        case keepFile
        case rerunBlock
    }
    
    /// Create and remove a temporary file
    /// - Parameters:
    ///   - fileExtension: File extension to use for file (default: none)
    ///   - initialContent: Initial content to use for file.  (Default: none; empty file)
    ///   - block: completion handler will be passed the URL of the temporary file
    /// - Note:
    ///      This function creates temporary files with several gaurantees:
    ///              * A new unique temporary file will be created in a thread-safe manner
    ///              * No existing file will be overwritten
    ///              * The file will exist with the `initialContent` given.  Or it will be a 0-byte file if nil.
    public func withTemporaryFile(ofType fileExtension: String?=nil, initialContent: Data?, block: (URL) throws -> TemporaryFileAction) throws {
        func createFile(fileExtension: String?, content: Data) throws -> (URL) {
            while true {
                let tempFilename: URL
                do {
                    tempFilename = self.temporaryFilename(ofType: fileExtension)
                    try content.write(to: tempFilename, options: .withoutOverwriting)
                    
                    return tempFilename
                } catch let error as NSError {
                    if error.code == NSFileWriteFileExistsError {
                        // retry with new filename
                    } else {
                        throw error
                    }
                }
            }
        }
        
        let startingContent = initialContent ?? Data()
        let filename = try createFile(fileExtension: fileExtension, content: startingContent)
        
        var action: TemporaryFileAction
        repeat {
            action = try block(filename)
        } while action == .rerunBlock
        
        switch action {
        case .removeFile:
            try self.fileManager.removeItem(at: filename)
        case .keepFile:
            break       // do nothing
        case .rerunBlock:
            break       // can't happen
        }
    }
    
    /// Create and remove a temporary file
    /// - Parameters:
    ///   - fileExtension: File extension to use for file (default: none)
    ///   - initialContent: Initial content to use for file.  (Default: none; empty file)
    ///   - removeAfterCompletion: If true (default), remove the file after completion handler returns.
    ///   - block: block will be passed the URL of the temporary file
    /// - Note:
    ///      This function creates temporary files with several gaurantees:
    ///              * A new unique temporary file will be created in a thread-safe manner
    ///              * No existing file will be overwritten
    ///              * The file will exist with the `initialContent` given.  Or it will be a 0-byte file if nil.
    public func withTemporaryFile(ofType fileExtension: String?=nil, initialContent: String?, removeAfterCompletion: Bool=true, block: (URL) throws -> TemporaryFileAction) throws {

        let initialData = initialContent?.data(using: .utf8)
        try withTemporaryFile(ofType: fileExtension, initialContent: initialData, block: block)
    }
    
    // MARK: Temporary directories
    @discardableResult
    /// Create a temporary directory
    /// - Returns: URL path to created directory
    public func createTemporaryDirectory() throws -> URL {
        let tempDir = self.temporaryFilename()
        
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
        
        let cCount = s.c.count
        for i in 0..<length {
            let r = Int.random(in: 0..<cCount)
            result[i] = s.c[r]
        }
        
        return String(result)
    }
}

