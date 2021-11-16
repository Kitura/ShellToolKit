import Foundation
import SwiftShell

/// Actually perform the function
public class SystemActionReal: SystemAction {
    public var swiftShellContext: Context = main
    let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func heading(_ type: SystemActionHeading, _ string: String) {
        // do nothing
    }

    public func createDirectory(url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    /// Create a file at a given path.
    ///
    /// This will overwrite existing files.
    /// - Parameters:
    ///   - file: fileURL to create
    ///   - content: Content of file
    /// - Throws: any problems in creating file.
    public func createFile(fileUrl: URL, content: String) throws {
        try? fileManager.removeItem(at: fileUrl)
        try content.write(to: fileUrl, atomically: false, encoding: .utf8)
    }

    public func removeItem(at url: URL, options: SwiftShellUtilities.RemoveItemOptions) throws {
        let dir = DirUtility.shared

        if !options.contains(.ignoreIfNotExist) {
            if !dir.fileExists(url: url) {
                throw SystemActionFailure.pathDoesNotExist(url)
            }
        }

        if options.contains([.removeFile, .removeDirectory]) {
            try fileManager.removeItem(at: url)
        } else if options.contains(.removeFile) {
            guard dir.isFile(url: url) else {
                throw SystemActionFailure.attemptToRemoveDirectory(url)
            }
            try dir.removeItem(at: url)
        } else if options.contains(.removeDirectory) {
            guard dir.isDirectory(url: url) else {
                throw SystemActionFailure.attemptToRemoveFile(url)
            }
            try dir.removeItem(at: url)
        }

    }

    public func runAndPrint(path: String?, command: [String]) throws {
        let context = self.swiftShellContext.with(path: path)
        let cmd = command.first!
        var args = command
        args.removeFirst()
        try context.runAndPrint(cmd, args)
    }
    
    public func run(path: String?, command: [String], stdin: String?) -> SystemActionOutput {
        let context = self.swiftShellContext
            .with(path: path)
            .with(stdin: stdin)
        
        let cmd = command.first!
        var args = command
        args.removeFirst()

        let result = context.run(cmd, args)
        
        return SystemActionOutput(stdout: result.stdout, stderr: result.stderror, exitCode: result.exitcode)
    }
    

}
