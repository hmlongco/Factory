//
//  FactoryMacroError.swift
//  FactoryMacros
//
//  Created by Michael Long on 5/25/25.
//

import Foundation

enum FactoryMacroError: Error {
    case block
    case closure
    case identifier
    case invalid
    case isolated
    case message(String)
    case parameterized
    case type
}

extension FactoryMacroError: CustomStringConvertible {
    var description: String {
        switch self {
        case .block:
            "Must be computed property"
        case .closure:
            "Missing factory closure"
        case .identifier:
            "Macro could not infer identifier"
        case .invalid:
            "Invalid Factory macro usage"
        case .isolated:
            "Macro does not support explicitly defined actor-isolated properties at this time"
        case .message(let message):
            message
        case .parameterized:
            "Missing parameterized closure"
        case .type:
            "Return type must be explicitly defined"
        }
    }
}
