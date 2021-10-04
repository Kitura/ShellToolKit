# SwiftShellUtilities
<p align="center">
![badge-platforms] ![badge-languages]
</p>

`SwiftShellUtilities` is a set of classes that are typically useful when using Swift as a command-line tool.

## Installation
### [Swift Package Manager](https://swift.org/package-manager/)

```swift
import PackageDescription

let package = Package(
    name: "YourAwesomeSoftware",
    dependencies: [
        .package(url: "https://github.com/dannys42/SwiftShellUtilities.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["SwiftShellUtilities"]
        )
    ]
)
```

### [swift-sh](https://github.com/mxcl/swift-sh)

```
#!/usr/bin/swift sh

import SwiftShellUtilities          // @dannys42


```

## System Action

Currently the only class supported is `SystemAction` which allows command-line tools to more easily support variations of verbose/dry-run.  It uses the [Rainbow](https://github.com/onevcat/Rainbow) library for colorized output and [SwiftShell](https://github.com/kareman/SwiftShell) for executing commands.

 A typical swift-argument-parser based program may look something like this:
 
 ```swift
 
 import ArgumentParser   // https://github.com/apple/swift-argument-parser.git

struct BuildCommand: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Enable verbose mode")
    var verbose: Bool = false

    @Flag(name: [.customLong("dry-run"), .customShort("n")], help: "Dry-run (print but do not execute commands)")
    var enableDryRun: Bool = false


    mutating func run() throws {
        let actions: SystemAction
        
        if enableDryRun {
            actions = CompositeAction([SystemActionPrint()])
        } else if verbose {
            actions = CompositeAction([SystemActionPrint(), SystemActionReal()])
        } else {
            actions = CompositeAction([SystemActionReal()])
        }
     
        try actions.runAndPrint(command: "echo", "Hello", "World!")
    }
 
 }
 ```
