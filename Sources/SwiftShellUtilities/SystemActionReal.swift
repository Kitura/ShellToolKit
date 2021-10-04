import Foundation
import SwiftShell

/// Actually perform the function
public class SystemActionReal: SystemAction {
    public var swiftShellContext: Context = main

    public func heading(_ type: SystemActionHeading, _ string: String) {
        // do nothing
    }

    public func createDirectory(url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    /// Create a file at a given path.
    ///
    /// This will overwrite existing files.
    /// - Parameters:
    ///   - file: fileURL to create
    ///   - content: Content of file
    /// - Throws: any problems in creating file.
    public func createFile(fileUrl: URL, content: String) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: fileUrl)
        try content.write(to: fileUrl, atomically: false, encoding: .utf8)
    }

    public func runAndPrint(path: String?, command: [String]) throws {
        var context = CustomContext(self.swiftShellContext)
        if let path = path {
            context.currentdirectory = path
        }
        let cmd = command.first!
        var args = command
        args.removeFirst()
        try context.runAndPrint(cmd, args)
    }
}
