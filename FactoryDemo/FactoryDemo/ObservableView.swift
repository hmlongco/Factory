//
//  ObservableView.swift
//  FactoryDemo
//
//  Created by Michael Long on 10/28/23.
//

import FactoryKit
#if canImport(Observation)
import Observation
#endif
import SwiftUI

@available(iOS 17, *)
@Observable
class ObservationService {
    var name: String = "ObservationService"
}

@available(iOS 17, *)
extension Container {
    @MainActor var observableService: Factory<ObservationService> {
        self { ObservationService() }
    }
}

@available(iOS 17, *)
struct ObservableView: View {
    @InjectedObservable(\.observableService) var observableService
    @State var showPreview: Bool = false
    var body: some View {
        HStack {
            Text(observableService.name)
            Spacer()
            Button("Mutate") {
                observableService.name += " *"
            }
        }
    }
}
