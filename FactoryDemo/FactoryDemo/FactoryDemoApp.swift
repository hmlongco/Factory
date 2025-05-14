//
//  FactoryDemoApp.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import FactoryKit

@main
struct FactoryDemoApp: App {
    var body: some Scene {
        let _ = Container.shared.setupMocks()
        let _ = ServiceContainer.test()
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(DemoContainer.shared)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
