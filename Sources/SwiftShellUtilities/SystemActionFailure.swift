//
//  File.swift
//  
//
//  Created by Danny Sung on 10/05/2021.
//

import Foundation

public enum SystemActionFailure: LocalizedError {
    case nothingToRemove
    case attemptToRemoveDirectory(URL)
    case attemptToRemoveFile(URL)
    case pathDoesNotExist(URL)
    case directoryExists(URL)

    public var errorDescription: String? {
        switch self {
        case .nothingToRemove:
            return "Remove requested, but no item type specified."
        case .attemptToRemoveDirectory(let fileUrl):
            return "Attempted to remove a directory at \"\(fileUrl.path)\" when only file removal was specified"
        case .attemptToRemoveFile(let fileUrl):
            return "Attempted to remove a file at \"\(fileUrl.path)\" when only directory removal was specified"
        case .pathDoesNotExist(let fileUrl):
            return "The path \"\(fileUrl.path)\"specified does not exist."
        case .directoryExists(let fileUrl):
            return "Directory '\(fileUrl.path)' already exists."
        }
    }

}
