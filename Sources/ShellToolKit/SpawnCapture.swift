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

    public class StreamOutput {
        let output: () -> Output

        struct Output {
            let data: Data
            let isEndOfFile: Bool
        }

        init(_ output: @escaping () -> Output ) {
            self.output = output
        }

        func writeHandler(_ fileHandle: FileHandle) -> Void {
            let output = self.output()
            do {
                try fileHandle.write(contentsOf: output.data)
                if output.isEndOfFile {
                    try fileHandle.close()
                }
            } catch {
                // TODO: Need a better way of managing errors
                print("StreamOutput:\(#function): error: \(error.localizedDescription)")
            }

        }
    }

    public class StreamInput {
        let input: (Input) -> Void
        let chunkSize: Int

        struct Input {
            let data: Data
            let isEndOfFile: Bool
        }

        init(_ input: @escaping (Input) -> Void, chunkSize: Int = 1024) {
            self.input = input
            self.chunkSize = chunkSize
        }

        func readHandler(_ fileHandle: FileHandle) -> Void {
            do {
                if let data = try fileHandle.read(upToCount: self.chunkSize) {
                    self.input(Input(data: data, isEndOfFile: false))
                }
            } catch {
                // TODO: Need a better way of managing errors
                print("StreamInput:\(#function): error: \(error.localizedDescription)")
            }
        }
    }

    // TODO: In progress -- not working yet
    public class FilterOutput {
        public var data: Data {
            return self.outgoingData
        }
        private var incomingData: Data
        private var outgoingData: Data
        private var isClosed: Bool
        private var serialQ: DispatchQueue
        private var filter: Filter

        struct Transformation {
            let outputData: Data
            let numberOfBytesConsumed: Int
            let isEndOfFile: Bool
        }

        typealias Filter = (Data) -> Transformation

        init(filter: @escaping Filter) {
            self.incomingData = Data()
            self.outgoingData = Data()
            self.isClosed = false
            self.serialQ = DispatchQueue(label: "FilterOutput.dataQ")
            self.filter = filter
        }

        func readHandler(_ fileHandle: FileHandle) -> Void {
            let data = fileHandle.availableData

            guard !data.isEmpty else {
                self.isClosed = true
                return
            }

            self.serialQ.async {
                self.incomingData.append(data)
                self.runFilter()
            }
        }

        func writeHandler(_ fileHandle: FileHandle) -> Void {
print("writeHandler called")
//            let self.filter(self.incomingData)

            guard self.outgoingData.count > 0 else { return }

            self.serialQ.async {
                do {
                    try fileHandle.write(contentsOf: self.outgoingData)
                    self.outgoingData.removeAll()
                    try fileHandle.close()
                } catch {
                    print("Error writing: \(error.localizedDescription)")
                }
            }
        }

        private func runFilter() {
            guard self.incomingData.count > 0 else { return }

            let filterResult = self.filter(self.incomingData)
            self.incomingData.removeFirst(filterResult.numberOfBytesConsumed)
            self.outgoingData.append(contentsOf: filterResult.outputData)
        }
    }
}
