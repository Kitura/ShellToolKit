//
//  GitCommand.swift
//  
//
//  Created by Danny Sung on 10/03/2021.
//

import Foundation

/// A class to wrap `git` commands.
///
/// At least one shell will be spawned to execute these commands
public class GitCommand {
    let action: SystemAction

    public init(systemAction: SystemAction = SystemActionReal()) {
        self.action = systemAction
    }

    /// Clone a git repository
    /// - Parameters:
    ///   - repo: repository to clone (ssh/http/https/file path)
    ///   - outdir: output path (relative or absolute).  Git will create this directory.
    ///   - shallow: If true, use --depth=1
    /// - Throws: `KituraCommandCore.Failures.directoryExists(outdir)` if outdir already exists
    public func clone(repo: URL, outdir: URL, shallow: Bool=false) throws {
        if DirUtility.shared.fileExists(url: outdir) {
            throw SystemActionFailure.directoryExists(outdir)
        }

        let repoString = repo.absoluteString
        if shallow {
            try action.runAndPrint(command: "git", "clone", "--depth", "1", repoString, outdir.path)
        } else {
            try action.runAndPrint(command: "git", "clone", repoString, outdir.path)
        }
    }
}

