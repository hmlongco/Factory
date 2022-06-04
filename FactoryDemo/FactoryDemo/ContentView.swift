//
//  ContentView.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import Factory

struct ContentView: View {
    @StateObject var model = ContentViewModel8()
    var body: some View {
        VStack(spacing: 20) {
            Text(model.text())
            NavigationLink("Link") {
                ContentView()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.myServiceType.register { MockService2() }
        ContentView()
    }
}
