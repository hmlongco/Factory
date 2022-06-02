//
//  ContentView.swift
//  FactoryDemo
//
//  Created by Michael Long on 6/2/22.
//

import SwiftUI
import Factory

struct ContentView: View {
    @StateObject var model = ContentViewModel1()
    var body: some View {
        Text(model.text())
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = SharedFactory.myServiceType.register { MockService2() }
        ContentView()
    }
}
