//
//  Copy FactoryKit files to Factory Directory
//  Created by Michael Long on 5/9/25.
//
//  swift copy-fk2f.swift
//

import Foundation

let sourceDir = "Sources/FactoryKit/FactoryKit"
let destinationDir = "Sources/Factory/Factory"

let fileManager = FileManager.default
let sourceURL = URL(fileURLWithPath: sourceDir)
let destinationURL = URL(fileURLWithPath: destinationDir)

do {
    // Enumerate .swift files
    let contents = try fileManager.contentsOfDirectory(atPath: sourceDir)
    let swiftFiles = contents.filter { $0.hasSuffix(".swift") }

    for file in swiftFiles {
        let sourceFile = sourceURL.appendingPathComponent(file)
        let destinationFile = destinationURL.appendingPathComponent(file)

        try? fileManager.removeItem(at: destinationFile)
        try fileManager.copyItem(at: sourceFile, to: destinationFile)

        print("Copied \(file)")
    }

    print("✅ Copies created in \(destinationDir)")

} catch {
    print("❌ Failed: \(error)")
    exit(1)
}
