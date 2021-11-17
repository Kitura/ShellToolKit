import Foundation

/// Allow actions to be composited and performed one after another.
/// Actions will be performed in the order they are specified in the initializer
public class SystemActionComposite: SystemAction {
    var actions: [SystemAction]

    public init(_ actions: [SystemAction] = []) {
        self.actions = actions
    }

    public func heading(_ type: SystemActionHeading, _ string: String) {
        self.actions.forEach {
            $0.heading(type, string)
        }
    }
    public func createDirectory(url: URL) throws {
        try self.actions.forEach {
            try $0.createDirectory(url: url)
        }
    }

    public func createFile(fileUrl: URL, content: String) throws {
        try self.actions.forEach {
            try $0.createFile(fileUrl: fileUrl, content: content)
        }
    }

    public func removeItem(at url: URL, options: SwiftShellUtilities.RemoveItemOptions) throws {
        try self.actions.forEach {
            try $0.removeItem(at: url, options: options)
        }
    }

    public func runAndPrint(workingDir: String?, command: [String]) throws {
        try self.actions.forEach {
            try $0.runAndPrint(workingDir: workingDir, command: command)
        }
    }
    
    public func run(workingDir: String?, command: [String], stdin: String?) -> SystemActionOutput {
        var output = SystemActionOutput()
        self.actions.forEach {
            let result = $0.run(workingDir: workingDir, command: command, stdin: stdin)
            
            let exitCode: Int? = result.isSuccess ? result.exitCode : nil

            output = output.appending(stdout: result.stdout, stderr: result.stderr, exitCode: exitCode)
        }
        
        return output
    }
    
    public func executeBlock(_ description: String?, _ block: () throws -> Void) rethrows {
        try self.actions.forEach {
            try $0.executeBlock(description, block)
        }
    }
}
