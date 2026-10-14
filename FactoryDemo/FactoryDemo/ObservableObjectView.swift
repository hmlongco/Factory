//
//  ObservableObjectView.swift
//  FactoryDemo
//

import FactoryKit
import SwiftUI

class ObservableObjectService: ObservableObject {
    @Published var name: String = "ObservableObjectService"
}

extension Container {
    @MainActor var observableObjectService: Factory<ObservableObjectService> {
        self { ObservableObjectService() }
    }
}

struct ObservableObjectView: View {
    @InjectedObject(\.observableObjectService) var observableObjectService
    @State var showPreview: Bool = false
    var body: some View {
        HStack {
            Text(observableObjectService.name)
            Spacer()
            Button("Mutate") {
                observableObjectService.name += " *"
            }
        }
    }
}
