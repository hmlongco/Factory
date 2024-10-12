import XCTest
@testable import Factory

private struct SomeSendableType: Sendable {}

private struct AsyncInitWrapper<T>: Sendable {
    let wrapped: @Sendable () async -> T
}

@MainActor private final class SomeMainActorType: Sendable {
    init() {}
}

private actor SomeActor {
    var value: Int = 0
    
    init() {}
    
    func increment() {
        value += 1
    }
}

@MainActor private final class ImplicitlySendableMainActorType {
    init() {}
}

@globalActor
public actor GlobalActor {
    public typealias ActorType = GlobalActor

    public static let shared = ActorType()
}

@GlobalActor private final class ImplicitlySendableGlobalActorType {
    init() {}
}

extension Container {
    fileprivate var sendable: Factory<SomeSendableType> {
        self { .init() }
    }

    @MainActor fileprivate var mainActor: Factory<AsyncInitWrapper<SomeMainActorType>> {
        self {
            .init {
                await SomeMainActorType()
            }
        }
    }
    
    fileprivate var someActor: Factory<SomeActor> {
        self { .init() }
    }
    
    @MainActor fileprivate var implicitlySendableMainActor: Factory<ImplicitlySendableMainActorType> {
        self { @MainActor in .init() }
    }
    
    fileprivate var nonisolatedImplicitlySendableMainActor: Factory<ImplicitlySendableMainActorType> {
        self { @MainActor in .init() }
    }
    
    @GlobalActor fileprivate var globalActor: Factory<ImplicitlySendableGlobalActorType> {
        Factory(self) { @GlobalActor in .init() }
    }
}

final class FactoryIsolationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }

    func testInjectSendableDependency() {
        let _: SomeSendableType = Container.shared.sendable()
    }

    func testInjectMainActorDependency() async {
        let _: SomeMainActorType = await Container.shared.mainActor().wrapped()
    }
    
    func testSomeActorDependency() async {
        let someActor = Container.shared.someActor()
        
        await someActor.increment()
        let value = await someActor.value
        
        XCTAssertEqual(value, 1)
    }
    
    @MainActor func testImplicitlySendableMainActorDependency() async {
        _ = Container.shared.implicitlySendableMainActor()
    }
    
    // Compiler error:
    // Main actor-isolated property 'implicitlySendableMainActor' can not be referenced from a Sendable closure
//    @MainActor func testImplicitlySendableMainActorDependencyInBackground() {
//        DispatchQueue.global().async {
//            _ = Container.shared.implicitlySendableMainActor()
//        }
//    }
    
    @MainActor func testImplicitlySendableMainActorDependencyInBackground() async {
        let exp = expectation(description: "\(#function)")
        
        DispatchQueue.global().async {
            Task { @MainActor in
                _ = Container.shared.implicitlySendableMainActor()
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [exp])
    }
    
    // crash from dispatch_assert_queue
    // !!!: no compiler warning about this
//    @MainActor func testImplicitlySendableMainActorDependencyInBackground() {
//        let exp = expectation(description: "\(#function)")
//        
//        DispatchQueue.global().async {
//            Task {
//                await _ = Container.shared.implicitlySendableMainActor()
//                exp.fulfill()
//            }
//        }
//        
//        wait(for: [exp])
//    }
    
    // works because we are probably implicitly on the main thread
    func testNonisolatedImplicitlySendableMainActorDependency() {
        _ = Container.shared.nonisolatedImplicitlySendableMainActor()
    }
    
    // crashes because the test is not started on the MainActor
//    func testNonisolatedImplicitlySendableMainActorDependency() async {
//        _ = Container.shared.nonisolatedImplicitlySendableMainActor()
//    }
    
    // crash because runtime check of factory closure is not run on MainActor
    // !!!: no compiler warning about this
//    func testNonisolatedImplicitlySendableMainActorDependencyInBackground() {
//        DispatchQueue.global().async {
//            _ = Container.shared.nonisolatedImplicitlySendableMainActor()
//        }
//    }
    
    // crashes on Swift 6 because the test is started on the MainActor and requires the method be async
//    @GlobalActor func testGlobalActorDependency() {
//        let a = 1
//    }
    
    @GlobalActor func testGlobalActorDependency() async {
        _ = Container.shared.globalActor()
    }
    
    func testGetGlobalActor() async {
        await _ = getGlobalActor()
    }
}

// contrived global function to force any compiler warnings
@GlobalActor fileprivate func getGlobalActor() -> ImplicitlySendableGlobalActorType {
    Container.shared.globalActor()
}
