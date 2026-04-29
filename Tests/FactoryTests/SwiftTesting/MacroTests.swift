////
////  MacroTests.swift
////  Factory
////
////  Created by Michael Long on 5/28/25.
////
//
//import Testing
//import FactoryTesting
//
//@testable import FactoryKit
//@testable import FactoryMacros
//
//@Suite(.container)
//struct MacroTests {
//
//    @Test func basicMacroEvaluationTest() async throws {
//        let service = Container.shared.macroMyService
//        #expect(service is MyService)
//    }
//
//    @Test func basicMacroRegistrationTest() async throws {
//        Container.shared.$macroMyService.register { MockService() }
//        let service = Container.shared.macroMyService
//        #expect(service is MockService)
//    }
//
//    @Test func basicMacroScopeTest() async throws {
//        let service1 = Container.shared.macroCachedService
//        let service2 = Container.shared.macroCachedService
//        #expect(service1.id == service2.id)
//    }
//
//    @Test func basicMacroOptionalTest() async throws {
//        let service1 = Container.shared.macroOptionalService
//        #expect(service1 == nil)
//
//        Container.shared.$macroOptionalService.register { MockService() }
//        let service2 = Container.shared.macroOptionalService
//        #expect(service2 is MockService)
//    }
//
////    @Test func macroMainActorTypeTest() async throws {
////        let service: SomeMainActorType? = Container.shared.macroMainActorType
////        #expect(service != nil)
////    }
////
////    @Test func macroTestActorTypeTest() async throws {
////        let service: TestActorType? = Container.shared.macroTestActorType
////        #expect(service != nil)
////    }
//
//    @Test func macroMirrorTest() async throws {
//        let service1: MyServiceType = Container.shared.mirrorMyService
//        #expect(service1 is MyService)
//
//        Container.shared.$mirrorMyService.register {
//            MockService()
//        }
//
//        let service2: MyServiceType = Container.shared.mirrorMyService
//        #expect(service2 is MockService)
//        #expect(service1.id != service2.id)
//
//        let service3: MyServiceType = Container.shared.mirrorMyService
//        #expect(service3 is MockService)
//        #expect(service2.id == service3.id)
//    }
//
//    @MainActor @Test func macroMirrorActorTest() async throws {
//        let service: MyMainActorType = Container.shared.mirrorMyActorService
//        #expect(type(of: service) == MyMainActorService.self)
//        Container.shared.$mirrorMyActorService.register {
//            MockMainActorService()
//        }
//        let service2: MyMainActorType = Container.shared.mirrorMyActorService
//        #expect(type(of: service2) == MockMainActorService.self)
//    }
//
//}
//
//extension Container {
//
//    func instance<T>(key: StaticString = #function, _ factory: @escaping () -> T) -> Factory<T> {
//        Factory<T>(self, key: key, factory)
//    }
//
//    public var anotherMyService: MyServiceType {
//        instance { MyService() }.cached()
//    }
//
//}
//
//extension Container {
//
//    @DefineFactory({ MyService() })
//    var macroMyService: MyServiceType
//
//    @DefineFactory({ MyService() }, scope: .cached)
//    public var macroCachedService: MyServiceType
//
//    @DefineFactory({ nil as MyServiceType? })
//    var macroOptionalService: MyServiceType?
//
//    @DefineFactory({ NonisolatedMainActorType() })
//    var macroNonisolatedMainActorType: NonisolatedMainActorType
//
//    //    @DefineFactory({ MyMainActorService() })
//    //    var macroMainActorType: MyMainActorType
//
//    //    @DefineFactory({ TestActorType() })
//    //    var macroTestActorType: TestActorType
//
//}
//
//protocol MirrorServiceTypeProviding {
//    var mirrorMyService: MyServiceType { get }
//    @MainActor var mirrorMyActorService: MyMainActorType { get }
//}
//
//extension Container: MirrorServiceTypeProviding {
//    @MirrorFactory
//    public var mirrorMyService: MyServiceType {
//        //        self { MyService() }.cached() // fails
//        //        instance { MyService() }.cached() // fails
//        Factory<MyServiceType>(self) { MyService() }.cached()
//    }
//
//    @MirrorFactory
//    public var mirrorMyService2: MyServiceType {
//        Factory(self) { MyService() as MyServiceType }()
//    }
//
//    @MirrorFactory
//    @MainActor var mirrorMyActorService: MyMainActorType {
//        Factory<MyMainActorType>(self) { MyMainActorService() }.cached()
//    }
//}
//
