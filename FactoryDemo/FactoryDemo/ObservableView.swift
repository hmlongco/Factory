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

protocol ObservationServiceType: AnyObject {
    var name: String { get set }
}

@available(iOS 17, *)
@Observable
class ObservationService: ObservationServiceType {
    var name: String = "ObservationService"
}

@available(iOS 17, *)
@Observable
class MockObservationService: ObservationServiceType {
    var name: String
    init(name: String) {
        self.name = name
    }
}

@available(iOS 17, *)
extension Container {
    @MainActor var observableService: Factory<ObservationServiceType> {
        self { ObservationService() }
    }
}

@available(iOS 17, *)
struct ObservableView: View {
    @Injected(\.observableService) var observableService
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

// With traditional inline register
@available(iOS 17, *)
#Preview("Register") {
    let _ = Container.shared.observableService.register {
        MockObservationService(name: "MockObservationService1")
    }
    return ObservableView().padding()
}

@available(iOS 17, *)
extension Container {
    @MainActor var observableServiceWithPreview: Factory<ObservationServiceType> {
        self { ObservationService() }
            .onPreview {
                MockObservationService(name: "MockObservationService2")
            }
    }
}

@available(iOS 17, *)
struct ObservableView2: View {
    @Injected(\.observableServiceWithPreview) var observableService
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

// With onPreview
@available(iOS 17, *)
#Preview("onPreview") {
    ObservableView2().padding()
}
