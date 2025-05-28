//
//  MacroTests.swift
//  Factory
//
//  Created by Michael Long on 5/28/25.
//

import Testing
import FactoryTesting

@testable import FactoryMacros

@Suite(.container)
struct MacroTests {

    @Test func basicMacroEvaluationTest() async throws {
        let service = Container.shared.macroMyService
        #expect(service is MyService)
    }

    @Test func basicMacroRegistrationTest() async throws {
        Container.shared.$macroMyService.register { MockService() }
        let service = Container.shared.macroMyService
        #expect(service is MockService)
    }

    @Test func basicMacroScopeTest() async throws {
        let service1 = Container.shared.macroCachedService
        let service2 = Container.shared.macroCachedService
        #expect(service1.id == service2.id)
    }

    @Test func basicMacroOptionalTest() async throws {
        let service1 = Container.shared.macroOptionalService
        #expect(service1 == nil)

        Container.shared.$macroOptionalService.register { MockService() }
        let service2 = Container.shared.macroOptionalService
        #expect(service2 is MockService)
    }

}

extension Container {
    @DefineFactory({ MyService() })
    public var macroMyService: MyServiceType

    @DefineFactory({ MyService() }, scope: .cached)
    public var macroCachedService: MyServiceType

    // do better?
    @DefineFactory({ nil as MyServiceType? })
    public var macroOptionalService: MyServiceType?
}
