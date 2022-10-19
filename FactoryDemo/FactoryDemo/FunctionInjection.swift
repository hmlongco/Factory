//
//  FunctionInjection.swift
//  FactoryDemo
//
//  Created by Michael Long on 10/17/22.
//

import SwiftUI
import Factory

typealias OpenURLFunction = (_ url: URL) -> Bool

extension Container {
    static let openURL = Factory<OpenURLFunction> {
        UIApplication.shared.openURL
    }
}

struct OpenView: View {
    let site: String
    @Injected(Container.openURL) var openURL
    var body: some View {
        Button("Open") {
            _ = openURL(URL(string: site)!)
        }
    }
}

struct OpenView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.openURL.register {{ _ in false }}
        OpenView(site: "https://www.google.com")
    }
}
