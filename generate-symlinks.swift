//
//  generate-symlinks.swift
//  Factory
//
//  Created by Michael Long on 5/9/25.
//

import Foundation

let sourceDir = "Sources/Factory/Factory"
let linkDir = "Sources/FactoryKit/FactoryKit"

let fileManager = FileManager.default
let sourceURL = URL(fileURLWithPath: sourceDir)
let linkURL = URL(fileURLWithPath: linkDir)

do {
    // Ensure symlink target directory exists
    try? fileManager.removeItem(at: linkURL) // Clean slate
    try fileManager.createDirectory(at: linkURL, withIntermediateDirectories: true)

    // Enumerate .swift files
    let contents = try fileManager.contentsOfDirectory(atPath: sourceDir)
    let swiftFiles = contents.filter { $0.hasSuffix(".swift") }

    for file in swiftFiles {
        let sourceFile = sourceURL.appendingPathComponent(file)
        let linkFile = linkURL.appendingPathComponent(file)

        try fileManager.createSymbolicLink(at: linkFile, withDestinationURL: sourceFile)
        print("Linked \(file)")
    }

    print("✅ Symlinks created in \(linkDir)")

} catch {
    print("❌ Failed: \(error)")
    exit(1)
}
