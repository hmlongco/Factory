//
//  FactoryMacrosPlugin.swift
//  FactoryMacros
//
//  Created by Michael Long on 5/25/25.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FactoryMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefineFactoryMacro.self,
        DefineParameterFactoryMacro.self,
        MirrorFactoryMacro.self
    ]
}
