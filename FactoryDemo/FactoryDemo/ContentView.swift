//
//  ContentView.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import Factory

struct ContentView: View {

    @InjectedObject(\.contentViewModel) var model: ContentViewModel

    // @StateObject var model: ContentViewModel = ContentViewModel()

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
            ContainerDemoView()
        }
        .padding()
    }
    
}

// Illustrates multiple
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let _ = Container.shared.myServiceType.register { MockServiceN(44) }
            let model1 = ContentViewModel()
            ContentView(model: InjectedObject(model1))

            let _ = Container.shared.myServiceType.register { MockServiceN(88) }
            let model2 = ContentViewModel()
            ContentView(model: InjectedObject(model2))
        }
    }
}

//struct ContentView_Previews1: PreviewProvider {
//    static var previews: some View {
//        let _ = Container.shared.myServiceType.register { MockServiceN(6) }
//        ContentView()
//    }
//}

