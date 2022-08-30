//
//  ContextExtensions.swift
//  
//
//  Created by Sung, Danny on 11/16/21.
//

import Foundation
import SwiftShell

internal extension Context {
    
    func with(workingDir: String? = nil) -> CustomContext {
        var context = CustomContext(self)
        guard let workingDir = workingDir else { return context }

        context.currentdirectory = workingDir
        
        return context
    }
    
    func with(stdin: String? = nil) -> CustomContext {
        var context = CustomContext(self)
        guard let stdin = stdin else { return context }

        let (writeStream, readStream) = streams()
        
        writeStream.write(stdin)
        context.stdin = readStream
        writeStream.close()
        return context
    }

}
