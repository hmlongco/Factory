//
// Contexts.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

/// Context types available for special purpose factory registrations.
public enum FactoryContext: Equatable {
    /// Context used when application is launched with a particular argument.
    case arg(String)
    /// Context used when application is launched with a particular argument or arguments.
    case args([String])
    /// Context used when application is running in Xcode Preview mode.
    case preview
    /// Context used when application is running in Xcode Unit Test mode.
    case test
    /// Context used when application is running in Xcode DEBUG mode.
    case debug
    /// Context used when application is running within an Xcode simulator.
    case simulator
    /// Context used when application is running on an actual device.
    case device
}

extension FactoryContext {
    /// Add argument to global context.
    public static func setArg(_ arg: String, forKey key: String) {
        runtimeArguments[key] = arg
    }
    /// Add argument to global context.
    public static func removeArg(forKey key: String) {
        runtimeArguments.removeValue(forKey: key)
    }
}

extension FactoryContext {
    /// Proxy for application arguments.
    internal static var arguments: [String] = ProcessInfo.processInfo.arguments
    /// Proxy check for application running in preview mode.
    internal static var isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    /// Proxy check for application running in test mode.
    internal static var isTest: Bool = NSClassFromString("XCTest") != nil
    /// Proxy check for application running in simulator.
    internal static var isSimulator: Bool = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil
    #if DEBUG
    /// Proxy checks for application running in DEBUG mode.
    internal static var isDebug: Bool = true
    #else
    /// Proxy check for application running in DEBUG mode.
    internal static var isDebug: Bool = false
    #endif
    /// Runtime arguments
    internal static var runtimeArguments: [String:String] = [:]
}
