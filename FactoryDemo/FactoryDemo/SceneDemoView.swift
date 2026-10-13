//
//  SceneDemoView.swift
//  FactoryDemo
//

import SwiftUI
import FactoryKit

@available(iOS 17, *)
struct SceneDemoView: View {

    @SceneBasedObservable(\.sceneDemoViewModel) var model

    var body: some View {
        Text("Scene ID: \(model.id)")
    }

}

@available(iOS 17, *)
#Preview {
    SceneDemoView()
}
