# SwiftShellUtilities
<p align="center">
<a href="https://github.com/Kitura/SwiftShellUtilities/actions?query=workflow%3ASwift"><img src="https://github.com/Kitura/SwiftShellUtilities/workflows/Swift/badge.svg" alt="build status"></a>
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2"></a>
<br/>
<a href="https://swiftpackageindex.com/Kitura/SwiftShellUtilities"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKitura%2F SwiftShellUtilities%2Fbadge%3Ftype%3Dswift-versions"></a>
<a href="https://swiftpackageindex.com/Kitura/SwiftShellUtilities"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKitura%2F SwiftShellUtilities%2Fbadge%3Ftype%3Dplatforms"></a>
</p>
`SwiftShellUtilities` is a set of classes that are typically useful when using Swift as a command-line tool.

## Installation
### [Swift Package Manager](https://swift.org/package-manager/)

```swift
import PackageDescription

let package = Package(
    name: "YourAwesomeSoftware",
    dependencies: [
        .package(url: "https://github.com/Kitura/SwiftShellUtilities.git", from: "0.1.0")
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

import SwiftShellUtilities          // @Kitura


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
