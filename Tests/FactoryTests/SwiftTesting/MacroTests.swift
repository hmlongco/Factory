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

    @Test func macroMainActorTypeTest() async throws {
        let service: SomeMainActorType? = Container.shared.macroMainActorType
        #expect(service != nil)
    }

    @Test func macroTestActorTypeTest() async throws {
        let service: TestActorType? = Container.shared.macroTestActorType
        #expect(service != nil)
    }

}

extension Container {
    @DefineFactory({ MyService() })
    var macroMyService: MyServiceType

    @DefineFactory({ MyService() }, scope: .cached)
    public var macroCachedService: MyServiceType

    @DefineFactory({ nil as MyServiceType? })
    var macroOptionalService: MyServiceType?

    // why?
    @DefineFactory({ @MainActor in SomeMainActorType() })
    var macroMainActorType: SomeMainActorType

    // why?
    @DefineFactory({ @TestActor in TestActorType() })
    var macroTestActorType: TestActorType
}
