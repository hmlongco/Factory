//
//  FunctionInjection.swift
//  FactoryDemo
//
//  Created by Michael Long on 10/17/22.
//

import SwiftUI
import FactoryKit

//typealias OpenURLFunction = (_ url: URL) -> Bool
//
//extension Container {
//    var openURL: Factory<OpenURLFunction> {
//        self { UIApplication.shared.openURL }
//    }
//}
//
//struct OpenView: View {
//    let site: String
//    @Injected(\.openURL) var openURL
//    var body: some View {
//        Button("Open") {
//            _ = openURL(URL(string: site)!)
//        }
//    }
//}
//
//struct OpenView_Previews: PreviewProvider {
//    static var previews: some View {
//        let _ = Container.shared.openURL.register { { _ in false } }
//        OpenView(site: "https://www.google.com")
//    }
//}
