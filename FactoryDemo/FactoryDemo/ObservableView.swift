//
//  ObservableView.swift
//  FactoryDemo
//
//  Created by Michael Long on 10/28/23.
//

import Factory
#if canImport(Observation)
import Observation
#endif
import SwiftUI

@available(iOS 17, *)
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
    var name: String = "MockObservationService"
}

@available(iOS 17, *)
extension Container {
    var observableService: Factory<ObservationServiceType> {
        self { ObservationService() }
    }
}

@available(iOS 17, *)
struct ObservableView: View {
    @Injected(\.observableService) var observableService
    var body: some View {
        HStack {
            Text(observableService.name)
            Spacer()
            Button("Mutate") {
                observableService.name += " *"
            }
        }
        .padding()
    }
}

@available(iOS 17, *)
#Preview {
    let _ = Container.shared.observableService.register { MockObservationService() }
    return ObservableView()
}
