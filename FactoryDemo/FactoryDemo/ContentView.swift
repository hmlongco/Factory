//
//  ContentView.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import Factory

struct ContentView: View {

    @StateObject var model = ContentModuleViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(model.text() + " for \(model.name)")
            TextField("Name", text: $model.name)
            NavigationLink("Link") {
                ContentView()
            }
            Button("Mutate") {
                model.name += "z"
            }
            Button("Trigger Circular Dependency Crash") {
                Container.testCircularDependencies()
            }
        }
        .padding()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.myServiceType.register { MockServiceN(4) }
            let model1 = ContentModuleViewModel()
            ContentView(model: model1)

            let _ = Container.myServiceType.register { MockServiceN(8) }
            let model2 = ContentModuleViewModel()
            ContentView(model: model2)
        }
    }
}
