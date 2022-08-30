//
//  GitCommand.swift
//  
//
//  Created by Danny Sung on 10/03/2021.
//

import Foundation
import SwiftShell

/// A class to wrap `git` commands.
///
/// At least one shell will be spawned to execute these commands
public class GitCommand {
    let action: SystemAction
    let gitExecutable = "git"
    public var workingDir: String?

    public init(systemAction: SystemAction = SystemActionReal(), workingDir: String?=nil) {
        self.action = systemAction
        self.workingDir = workingDir
    }
    
    // MARK: Base command

    public func run(workingDir: String?=nil, args: [String]) throws {
        let cwd = workingDir ?? self.workingDir
        try action.runAndPrint(workingDir: cwd,
                               command: [ self.gitExecutable ] + args)
    }
    
    public func run(workingDir: String?=nil, args: String...) throws {
        let cwd = workingDir ?? self.workingDir
        try self.run(workingDir: cwd, args: args)
    }

    // MARK: Initialization
    public func initializeRepo(workingDir: String?=nil, owner: String, repoName: String, commitMessage: String?=nil, sshUser: String="git", sshHost: String="github.com") throws {
        let cwd = workingDir ?? self.workingDir

        try run(workingDir: cwd, args: "init")
        try run(workingDir: cwd, args: "add", ".")
        try run(workingDir: cwd, args: "commit", "-m", commitMessage ?? "Initial Import")

        try run(workingDir: cwd, args: "branch", "--move", "main")
        try run(workingDir: cwd, args: "remote", "add", "origin", "\(sshUser)@\(sshHost):\(owner)/\(repoName).git")
        
        try run(workingDir: cwd, args: "push", "-u", "origin", "main")
    }
    
    // MARK: Add
    public func add(workingDir: String?=nil, path: [String]) throws {
        let args = ["add"] + path
        let cwd = workingDir ?? self.workingDir

        try run(workingDir: cwd, args: args)
    }
    
    public func add(workingDir: String?=nil, path: String...) throws {
        try self.add(workingDir: workingDir, path: path)
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
    
    // MAKR: Git Commit
    public enum CommitOptions {
        case quiet
        case verbose
        case author(String)
        case date(String)
        case dryRun
        case allChangedFiles
    }
    public func commit(workingDir: String?=nil, message: String, options: [CommitOptions]) throws {
        let cwd = workingDir ?? self.workingDir
        var args = [ "commit" ]

        for option in options {
            switch option {
            case .verbose: args += [ "--verbose" ]
            case .quiet: args += [ "--quiet" ]
            case .author(let text): args += [ "--author", text ]
            case .date(let text): args += [ "--date", text ]
            case .allChangedFiles: args += [ "--all" ]
            case .dryRun: args += [ "--dry-run" ]
            }
        }

        try self.run(workingDir: cwd, args: args + ["--message", message])
    }
    
    
    // MARK: Git Push
    
    public enum PushOptions {
        case verbose
        case quiet
        case progress
        case dryRun
        case force
    }
    
    public func push(workingDir: String?=nil, options: [PushOptions]=[]) throws {
        let cwd = workingDir ?? self.workingDir
        var args = [ "push" ]
        
        for option in options {
            switch option {
            case .verbose: args += [ "--verbose" ]
            case .quiet: args += [ "--quiet" ]
            case .progress: args += [ "--progress" ]
            case .dryRun: args += [ "--dry-run" ]
            case .force: args += [ "--force" ]
            }
        }
        
        try self.run(workingDir: cwd, args: args)
    }

    // MARK: Pull
    public enum PullOptions {
        case verbose
        case quiet
        case progress
        case rebase
        case dryRun
        case force
    }
    
    public func pull(workingDir: String?=nil, options: [PullOptions]) throws {
        let cwd = workingDir ?? self.workingDir
        var args = [ "pull" ]
        
        for option in options {
            switch option {
            case .verbose: args += [ "--verbose" ]
            case .quiet: args += [ "--quiet" ]
            case .progress: args += [ "--progress" ]
            case .rebase: args += [ "--rebase" ]
            case .dryRun: args += [ "--dry-run" ]
            case .force: args += [ "--force" ]
            }
        }
        
        try self.run(workingDir: cwd, args: args)
    }

    // MARK: Stash
    public enum StashAction: String {
        case list
        case pop
        case push
    }
    public enum StashOptions {
        case quiet
    }
    public func stash(workingDir: String?=nil, action: StashAction, options: [StashOptions]=[]) throws {
        let cwd = workingDir ?? self.workingDir
        var args = [ "stash", action.rawValue]
        
        for option in options {
            switch option {
            case .quiet: args += [ "--quiet" ]
            }
        }
        try self.run(workingDir: cwd, args: args)
    }
    
    /// Temporarily stash changes and execute block
    ///
    /// Will only perform `stash pop` operation if `stash push` succeeds.
    /// - Parameters:
    ///   - workingDir: Working directory
    ///   - options: `StashOption`
    ///   - block: Block to execute between push/pop
    /// - Throws: `CommandError` from `SwiftShell`
    public func stash(workingDir: String?, options: [StashOptions]=[], block: () throws ->Void) throws {
        let cwd = workingDir ?? self.workingDir

        var args: [String] =
            []
        for option in options {
            switch option {
            case .quiet: args += [ "--quiet" ]
            }
        }

        let pushCommand = ["git", "stash", "push"]
        let pushOutput = self.action.run(workingDir: cwd, command: pushCommand, stdin: nil)
        
        guard pushOutput.isSuccess else {
            if !options.contains(.quiet) {
                print(pushOutput.stdout)
            }
            throw CommandError.returnedErrorCode(command: pushCommand.joined(separator: ""), errorcode: pushOutput.exitCode)
        }

        try block()
        
        if !pushOutput.stdout.lowercased().contains("no local changes") {
            try self.stash(workingDir: cwd, action: .pop, options: options)
        }
    }
}

