//
//  InputPrompt.swift
//  
//
//  Created by Sung, Danny on 11/27/21.
//

import Foundation
import Rainbow

/// A class to help with simple console user input cases where we need a single response from the user (e.g. yes/no)
public class InputPrompt {
    public var enableColor = true
    public struct Style {
        var leadingText: String
        var leadingTextColor: Color
        var promptMessageColor: Color
        var allowedResponse: Color
        var responseColor: Color
    }
    public var style: Style = .normal
    
    public init() {
    }
    
    /// Prompt the user with a message and wait for the response
    /// - Parameters:
    ///   - prompt: The message to prompt with
    ///   - allowedResponses: Valid responses given in the format of ["short" : "long"].  For example ["y", "yes"] or ["n", "no"].  If no valid responses are given, any response is allowed and will return.
    ///   - style: Optional style to use.  Default will be taken from property `style`
    /// - Returns: Returns the "short" version of the response, regardless of whether the user gave the "short" or "long" version.
    @discardableResult
    public func input(prompt: String, allowedResponses: [String:String], style: Style?=nil) -> String? {
        let style = style ?? self.style
        var leadingText = style.leadingText
        var message = prompt
        var userResponsePrefix = "> "
        
        var eachAllowedResponse: [String] = []
        var allowedResponsePairs: [String] = []
        var allowedResponsesKey: [String:String] = [:]
        for (key,value) in allowedResponses {
            eachAllowedResponse.append(key)
            eachAllowedResponse.append(value)
            allowedResponsePairs.append("\(key)/\(value)")
            allowedResponsesKey[value] = key
        }
        var allowedResponsesText = allowedResponsePairs.joined(separator: ", ")
        
        if enableColor {
            leadingText = leadingText.applyingColor(style.leadingTextColor)
            message = message.applyingColor(style.promptMessageColor)
            allowedResponsesText = allowedResponsesText.applyingColor(style.allowedResponse)
            userResponsePrefix = userResponsePrefix.applyingColor(style.responseColor)
        }
        
        while true {
            print( [leadingText, message].joined(separator: " ") )
            print( allowedResponsesText + userResponsePrefix, terminator: "")
            if self.enableColor { // restore color after user input
                print("".white, terminator: "")
            }
            guard let response = readLine() else {
                return nil
            }
            if allowedResponses.isEmpty {
                return nil
            }
            if eachAllowedResponse.contains(response) {
                return allowedResponsesKey[response] ?? response
            }
        }
    }
}

public extension InputPrompt.Style {
    static let normal = InputPrompt.Style(leadingText: "- ", leadingTextColor: .white, promptMessageColor: .white, allowedResponse: .lightWhite, responseColor: .white)
    static let error = InputPrompt.Style(leadingText: "* ", leadingTextColor: .lightRed, promptMessageColor: .white, allowedResponse: .lightWhite, responseColor: .white)
}
