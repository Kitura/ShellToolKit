//
//  GitHub.swift
//  
//
//  Created by Sung, Danny on 11/15/21.
//

import Foundation

/// A class to wrap `gh` commands.
///
/// At least one shell will be spawned to execute these commands
public class GitHub {
    let action: SystemAction
    
    public enum Failures: LocalizedError {
        case apiCallFailure(Int, String, String)
        
        public var errorDescription: String? {
            switch self {
            case .apiCallFailure(let exitCode, let stdout, let stderr):
                return "API Call failed with exit code = \(exitCode), stdout=\"\(stdout)\", stderr=\"\(stderr)\""
            }
        }
    }
    
    public init(systemAction: SystemAction = SystemActionReal()) {
        self.action = systemAction
    }
    
    // MARK: Create Repository
    public enum CreateAccess {
        case `internal`
        case `private`
        case `public`
    }
    public enum CreateOptions {
        case description(String)
        case gitignore(String)
        case homepage(URL)
        case license(String)
        case access(CreateAccess)
        case team(Int)
    }
    
    /// Create a repository on github.com
    /// - Note: This can only create repositories on github.com.  `hostname` is ignored.
    /// - Parameters:
    ///   - organization: Organization/owner of repository
    ///   - name: Name of repository
    ///   - options: `CreateOptions`
    /// - Throws:
    ///   -  `CommandError.returnedErrorCode(command: String, errorcode: Int)` if the exit code is anything but 0.
    ///   - `CommandError.inAccessibleExecutable(path: String)` if 'executable’ turned out to be not so executable after all.
    public func createRepository(organization: String, name: String, options: [CreateOptions]=[]) throws {
        
        struct Body: Codable {
            let name: String
            var description: String?
            var homepage: URL?
            var `private`: Bool?
            var visibility: String?
            var gitignore_template: String?
            var license_template: String?
            var team_id: Int?
        }
        var body = Body(name: name)
        
        for option in options {
            switch option {
            case .description(let text): body.description = text
            case .gitignore(let template): body.gitignore_template = template
            case .homepage(let url): body.homepage = url
            case .license(let template): body.license_template = template
            case .team(let teamId): body.team_id = teamId
            case .access(let access):
                switch access {
                case .internal:
                    body.private = true
                    body.visibility = "internal"
                case .private:
                    body.private = true
                    body.visibility = "private"
                case .public:
                    body.private = false
                    body.visibility = "public"
                }
            }
        }
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(body)
        let jsonString = String(data: jsonData, encoding: .utf8)!
 
        try self.api(endpoint: "/orgs/\(organization)/repos", options: [
            .httpMethod("POST"),
            .requestBody(jsonString)
        ])
    }
    
    // MARK: API calls
    public enum APIOptions {
        case field(String,String)
        case hostname(String)
        case includeHttpResponse
        case requestBodyFile(String)
        case requestBody(String)
        case jqSelect(String)
        case httpMethod(String)
        case rawField(String,String)
        case silent
    }
    
    @discardableResult
    public func api(endpoint: String, options: [APIOptions]=[]) throws -> SystemActionOutput {
        var command: [String] = [ "gh", "api", endpoint ]
        var stdin: String? = nil
        
        for option in options {
            switch option {
            case .field(let key, let value): command.append(contentsOf: ["--field", "\(key)=\(value)"])
            case .hostname(let hostname): command.append(contentsOf: ["--hostname", hostname])
            case .includeHttpResponse: command.append("--include")
            case .requestBodyFile(let filename): command.append(contentsOf: ["--input", filename])
            case .requestBody(let body):
                command.append(contentsOf: ["--input", "-"])
                stdin = body
            case .jqSelect(let query): command.append(contentsOf: ["--jq", query])
            case .httpMethod(let method): command.append(contentsOf: ["--method", method])
            case .rawField(let key, let value): command.append(contentsOf: ["--raw-field", "\(key)=\(value)"])
            case .silent: command.append("--silent")
            }
        }
        
        let output = self.action.run(command: command, stdin: stdin)
        
        if !output.isSuccess || !output.stderr.isEmpty {
            throw Failures.apiCallFailure(output.exitCode, output.stdout, output.stderr)
        }
        return output
    }
    
    
    // MARK: Repository Collaborators
    public enum CollaboratorPermission: String {
        case pull
        case push
        case admin
        case maintain
        case triage
    }
    
    public struct Collaborator: Codable {
        public let login: String
        public let id: Int
        public let avatarUrl: URL
        public let url: URL

        
        public struct Permissions: Codable {
            public let pull: Bool
            public let push: Bool
            public let admin: Bool
        }
        public let permissions: Permissions
    }

    public func repositoryCollaborators(owner: String, repo: String, hostname: String?=nil) throws -> [Collaborator] {
        
        let options = APIOptions.hostname(hostname: hostname)

        let output = try self.api(endpoint: "/repos/\(owner)/\(repo)/collaborators", options: options)
        
        let jsonDecoder = JSONDecoder()
        let resultData = output.stdout.data(using: .utf8)!
        let collaborators = try jsonDecoder.decode([Collaborator].self, from: resultData)
        
        return collaborators
    }
    
    public func addRepositoryCollaborator(owner: String, repo: String, username: String, permission: CollaboratorPermission, hostname: String? = nil) throws -> String {
        
        let permissionBody = "{ \"permission\" : \"\(permission.rawValue)\" }"
        
        let options = APIOptions.hostname(hostname: hostname) + [
            .httpMethod("PUT"),
            .requestBody(permissionBody)
        ]
        
        let output = try self.api(endpoint: "/repos/\(owner)/\(repo)/collaborators/\(username)", options: options)
        
        return output.stdout
    }
    
    public func removeRepositoryCollaborator(owner: String, repo: String, username: String, hostname: String? = nil) throws {
        
        let options = APIOptions.hostname(hostname: hostname) + [.httpMethod("DELETE")]

        try self.api(endpoint: "/repos/\(owner)/\(repo)/collaborators/\(username)", options: options)
    }
}


extension GitHub.APIOptions {
    static func hostname(hostname: String?) -> [GitHub.APIOptions] {
        guard let hostname = hostname else {
            return []
        }
        
        return [.hostname(hostname)]
    }
}
