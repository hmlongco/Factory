//
//  SceneDemoView.swift
//  FactoryDemo
//

import SwiftUI
import FactoryKit

@available(iOS 17, *)
struct SceneDemoView: View {

    @InjectedObservable(\.sceneDemoViewModel) var model

    var body: some View {
        Text("Scene ID: \(model.id)")
    }

}

@available(iOS 17, *)
#Preview {
    SceneDemoView()
        .withContainer(\.id) { "TEST "}
}

@available(iOS 17, *)
#Preview {
    SceneDemoView()
        .withContainer {
            $0.setupMocks()
        }
}
