import Foundation

/// Actually perform the function
public class SystemActionReal: SystemAction {
    public var spawnContext: Spawn.Context
    let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.spawnContext = Spawn.Context()
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

    public func removeItem(at url: URL, options: ShellToolKit.RemoveItemOptions) throws {
        let dir = DirUtility.shared

        if !dir.fileExists(url: url) {
            if options.contains(.ignoreIfNotExist) {
                return
            } else {
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

    public func runAndPrint(workingDir: String?, command: [String]) throws {
        let context: Spawn.Context

        if let workingDir = workingDir {
            context = self.spawnContext.with(workingDirectory: URL(fileURLWithPath:  workingDir))
        } else {
            context = self.spawnContext
        }

        let cmd = command.first!
        var args = command
        args.removeFirst()

        let spawn = SpawnCmd(command: cmd, context: context)
        try spawn.runAndWait(args)
    }
    
    public func run(workingDir: String?, command: [String], stdin: String?) -> SystemActionOutput {

        let context: Spawn.Context

        if let workingDir = workingDir {
            context = self.spawnContext
                .with(workingDirectory: URL(fileURLWithPath:  workingDir))
                .with(defaultIoMode: .passthru)
        } else {
            context = self.spawnContext
                .with(defaultIoMode: .pipe)
        }

//        let context = self.swiftShellContext
//            .with(workingDir: workingDir)
//            .with(stdin: stdin)
        
        let cmd = command.first!
        var args = command
        args.removeFirst()

        // TODO: Probably can use SpawnCmd.runAndWait() -> Output
        let spawn = SpawnCmd(command: cmd, context: context)
        let stdoutCapture = Spawn.CaptureOutput()
        let stderrCapture = Spawn.CaptureOutput()

        do {
            let result: Int
            if let stdin = stdin {
                let stdinString = Spawn.StringOutput(stdin)
                result = try spawn.runAndWait(args,
                                              stdin: .writer(stdinString),
                                              stdout: .reader(stdoutCapture),
                                              stderr: .reader(stderrCapture))
            } else {
                result = try spawn.runAndWait(args)
            }

            let stdout = String(data: stdoutCapture.data, encoding: .utf8) ?? ""
            let stderr = String(data: stderrCapture.data, encoding: .utf8) ?? ""
            return SystemActionOutput(stdout: stdout, stderr: stderr, exitCode: result)
        } catch {
            return SystemActionOutput(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }
    }
    
    public func executeBlock(_ description: String?, _ block: () throws -> Void) rethrows {
        try block()
    }

}
