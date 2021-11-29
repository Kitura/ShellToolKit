//
//  TabularTextFormatter.swift
//  
//
//  Created by Sung, Danny on 11/28/21.
//

import Foundation

/// A class to assist in displaying tabular data
public class TabularTextFormatter {
    public enum Justification {
        case left
        case center
        case right
    }
    public var dataSource: (_ rowIndex: Int)->[String]? = { _ in nil }
    public var outputRow: (_ rowIndex: Int, _ paddingColumns: [String])->Void = { _, cols in print(cols.joined(separator: "")) }
    public var paddingAfterColumn: (_ columnIndex: Int) -> Int = { _ in 2 }
    public var justificationForColumn: (_ columnIndex: Int) -> Justification = { _ in .left }
    
    /// Goes
    public func render() {
        // 1st pass, determine length of each row
        var columnLengths: [Int] = []
        var rowIndex = 0
        while let row = self.dataSource(rowIndex) {
            rowIndex += 1
            
            // pad any missing columns
            if row.count > columnLengths.count {
                let newZeroes = Array(repeating: 0, count: row.count - columnLengths.count)
                columnLengths.append(contentsOf: newZeroes)
            }
            
            for (ndx, col) in row.enumerated() {
                columnLengths[ndx] = max(columnLengths[ndx], col.count)
            }
        }
        
        // Generate output
        rowIndex = 0
        while let row = self.dataSource(rowIndex) {
            rowIndex += 1
            
            var paddedRow: [String] = []
            for (ndx, col) in row.enumerated() {
                let columnPadding = columnLengths[ndx] - col.count
                let paddedColumn: String
                switch self.justificationForColumn(ndx) {
                case .left:
                    paddedColumn = col + String(repeating: " ", count: columnPadding)
                case .center:
                    paddedColumn = String(repeating: " ", count: columnPadding/2)
                    + col
                    + String(repeating: " ", count: columnLengths[ndx] - (columnPadding/2 + col.count))
                case .right:
                    paddedColumn = String(repeating: " ", count: columnPadding) + col
                }
                paddedRow.append(paddedColumn + String(repeating: " ", count: self.paddingAfterColumn(ndx)))
            }
            outputRow(rowIndex, paddedRow)
        }
    }
}

