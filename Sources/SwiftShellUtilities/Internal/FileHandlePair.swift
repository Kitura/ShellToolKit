//
//  FileHandlePair.swift
//  
//
//  Created by Danny Sung on 05/24/2022.
//

import Foundation

protocol FileHandlePair {
    typealias fileHandler = (FileHandle) ->Void

    var writeHandler: fileHandler? { get set }
    var readHandler: fileHandler? { get set }

    var processStreamAttachment: Any { get }
}
