import Foundation
import Rainbow

/// Only print the actions.  This is useful for suporting verbose modes.
///
/// ANSI Colors and Styles can be altered by specifying a `ModeCode` from the `Rainbow` module.
public class SystemActionPrint: SystemAction {
    public typealias PrintStyle = [ModeCode]

    /// Set to false to disable color/styles
    public var enableStyle = true
    public var sectionStyle: PrintStyle = [ Color.yellow, Style.bold ]
    public var phaseStyle: PrintStyle = [ Color.cyan, Style.bold ]
    public var createDirectoryStyle: PrintStyle = [ Style.bold ]
    public var createFileStyle: PrintStyle = [ Style.bold ]
    public var runAndPrintStyle: PrintStyle = [ Style.bold ]

    public func heading(_ type: SystemActionHeading, _ string: String) {
        switch type {
        case .section:
            output(" == Section: \(string)", style: sectionStyle)
        case .phase:
            output(" -- Phase: \(string)", style: phaseStyle)
        }
    }

    public func createDirectory(url: URL) throws {
        output(" > Creating directory at path: \(url.path)", style: createDirectoryStyle)
    }
    
    public func createFile(fileUrl: URL, content: String) throws {
        output(" > Creating file at path: \(fileUrl.path)", style: createFileStyle)
        print(content.split(separator: "\n").map { "    " + $0 }.joined(separator: "\n").yellow)
    }

    public func runAndPrint(path: String?, command: [String]) throws {
        output(" > Executing command: \(command.joined(separator: " "))", style: runAndPrintStyle)
        if let path = path {
            output("   Working Directory: \(path)", style: runAndPrintStyle)
        }
    }

    private func output(_ string: String, style: PrintStyle) {
        print(string.style(enabled: self.enableStyle, printStyle: style))
    }
}

internal extension String {
    func style(enabled: Bool, printStyle: SystemActionPrint.PrintStyle) -> String {
        guard enabled else {
            return self
        }

        var newString = self
        for style in printStyle {
            newString = newString.applyingCodes(style)
        }
        return newString
    }
}
