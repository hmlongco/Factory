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
@Observable
final class SceneDemoViewModel {

    let id: String

    init(id: String) {
        self.id = id
    }

}

@available(iOS 17, *)
extension Container {
    @MainActor var sceneDemoViewModel: Factory<SceneDemoViewModel> {
        self { SceneDemoViewModel(id: self.id()) }
    }
}
