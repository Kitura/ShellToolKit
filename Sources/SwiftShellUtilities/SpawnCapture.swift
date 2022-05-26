//
//  SpawnCapture.swift
//  
//
//  Created by Danny Sung on 05/25/2022.
//

import Foundation

extension Spawn {
    public class CaptureOutput {
        public private(set) var data: Data

        init() {
            self.data = Data()
        }

        func readHandler(_ fileHandle: FileHandle) -> Void {
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }

            self.data.append(data)
        }
    }
}
