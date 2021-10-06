import Foundation

public struct SwiftShellUtilities {

}

public extension SwiftShellUtilities {
    struct RemoveItemOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let ignoreIfNotExist = RemoveItemOptions(rawValue: 1<<0)
        /// `removeFile` specifies any type of file that is not a directory
        static let removeFile = RemoveItemOptions(rawValue: 1<<1)
        static let removeDirectory = RemoveItemOptions(rawValue: 1<<2)

        static let defaultOptions: RemoveItemOptions = [ .ignoreIfNotExist, .removeFile, .removeDirectory ]
    }
}
