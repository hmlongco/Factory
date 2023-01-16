//
//  NewFactoryDemoApp.swift
//  NewFactoryDemo
//
//  Created by Michael Long on 1/15/23.
//

import SwiftUI

@main
struct NewFactoryDemoApp: App {
    var body: some Scene {
        WindowGroup {
            let _ = Container.shared.service.register { MockServiceN(8) }
            ContentView()
        }
    }
}
