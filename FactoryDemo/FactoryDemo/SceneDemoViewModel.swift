//
//  SceneDemoViewModel.swift
//  FactoryDemo
//

import Foundation
import FactoryKit
#if canImport(Observation)
import Observation
#endif

@available(iOS 17, *)
@MainActor
@Observable
final class SceneDemoViewModel {

    let id: String

    private let service: MyServiceType

    init(container: Container) {
        self.id = container.id()
        self.service = container.myServiceType()
    }

    func text() -> String {
        service.text()
    }

}

@available(iOS 17, *)
extension Container {
    @MainActor var sceneDemoViewModel: Factory<SceneDemoViewModel> {
        self { SceneDemoViewModel(container: self) }
    }
}
