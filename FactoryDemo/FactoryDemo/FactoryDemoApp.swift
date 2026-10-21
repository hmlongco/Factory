//
//  FactoryDemoApp.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import FactoryKit

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            PerSceneContentView()
        }
    }
}

struct PerSceneContentView: View {
    // Create and store the container
    @State var sceneContainer = Container()
    var body: some View {
        NavigationStack {
            ContentView()
        }
        // Add container to the scene root view
        .withContainer(sceneContainer)
    }
}
