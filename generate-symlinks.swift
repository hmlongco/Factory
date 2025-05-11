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

func relativePath(from base: URL, to target: URL) -> String {
    let baseComponents = base.standardized.pathComponents
    let targetComponents = target.standardized.pathComponents

    var index = 0
    while index < baseComponents.count && index < targetComponents.count &&
          baseComponents[index] == targetComponents[index] {
        index += 1
    }

    // `up`: how many levels we need to move upwards in the directory
    let up = Array(repeating: "..", count: baseComponents.count - index)
    let down = targetComponents[index...]
    return (up + down).joined(separator: "/")
}

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

        let relativeTargetPath = relativePath(from: linkFile.deletingLastPathComponent(), to: sourceFile)

        try fileManager.createSymbolicLink(atPath: linkFile.path, withDestinationPath: relativeTargetPath)
        print("Linked \(file) → \(relativeTargetPath)")
    }

    print("✅ Symlinks created in \(linkDir)")

} catch {
    print("❌ Failed: \(error)")
    exit(1)
}
