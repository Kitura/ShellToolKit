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
    let gitExecutable = "git"

    public init(systemAction: SystemAction = SystemActionReal()) {
        self.action = systemAction
    }
    
    public func git(workingDir: String?, args: [String]) throws {
        try action.runAndPrint(workingDir: workingDir,
                               command: [ self.gitExecutable ] + args)
    }
    
    public func git(workingDir: String?, args: String...) throws {
        try self.git(workingDir: workingDir, args: args)
    }

    public func initializeRepo(workingDir: String?, owner: String, repoName: String, commitMessage: String?=nil, sshUser: String="git", sshHost: String="github.com") throws {
        
        try git(workingDir: workingDir, args: "init")
        try git(workingDir: workingDir, args: "add", ".")
        try git(workingDir: workingDir, args: "commit", "-m", commitMessage ?? "Initial Import")

        try git(workingDir: workingDir, args: "branch", "--move", "main")
        try git(workingDir: workingDir, args: "remote", "add", "origin", "\(sshUser)@\(sshHost):\(owner)/\(repoName).git")
        
        try git(workingDir: workingDir, args: "push", "-u", "origin", "main")
    }

    /// Clone a git repository
    /// - Parameters:
    ///   - repo: repository to clone (http/https)
    ///   - outdir: output path (relative or absolute).  Git will create this directory.
    ///   - shallow: If true, use --depth=1
    /// - Throws: `KituraCommandCore.Failures.directoryExists(outdir)` if outdir already exists
    public func clone(repo: URL, outdir: URL, shallow: Bool=false) throws {
        try self.clone(repo: repo.absoluteString, outdir: outdir, shallow: shallow)
    }
    
    /// Clone a git repository
    /// - Parameters:
    ///   - repo: repository to clone (ssh/file path)
    ///   - outdir: output path (relative or absolute).  Git will create this directory.
    ///   - shallow: If true, use --depth=1
    /// - Throws: `KituraCommandCore.Failures.directoryExists(outdir)` if outdir already exists
    public func clone(repo: String, outdir: URL, shallow: Bool=false) throws {
        if DirUtility.shared.fileExists(url: outdir) {
            throw SystemActionFailure.directoryExists(outdir)
        }
        
        if shallow {
            try action.runAndPrint(command: "git", "clone", "--depth", "1", repo, outdir.path)
        } else {
            try action.runAndPrint(command: "git", "clone", repo, outdir.path)
        }
    }
}

