#if canImport(SwiftUI)
import XCTest
import Combine
import Observation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@testable import FactoryKit

// MARK: - Fixtures

@MainActor
private final class SceneObjectModel: ObservableObject {
    @Published var name: String
    init(name: String) { self.name = name }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@MainActor @Observable
private final class SceneObservableModel {
    var name: String
    init(name: String) { self.name = name }
}

private final class SceneTestContainer: SharedContainer {
    @TaskLocal static var shared = SceneTestContainer()
    let manager = ContainerManager()

    var sceneTestName: Factory<String> { self { "shared" } }

    @MainActor var objectModel: Factory<SceneObjectModel> {
        self { SceneObjectModel(name: self.sceneTestName()) }.cached
    }

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    @MainActor var observableModel: Factory<SceneObservableModel> {
        self { SceneObservableModel(name: self.sceneTestName()) }.cached
    }
}

private extension Container {
    var sceneTestName: Factory<String> { self { "default" } }
    @MainActor var sceneTestObjectModel: Factory<SceneObjectModel> {
        self { SceneObjectModel(name: self.sceneTestName()) }.cached
    }
}

// MARK: - Views

@MainActor
private final class Seen {
    var name = ""
    var renders = 0
    func record(_ name: String) {
        self.name = name
        renders += 1
    }
}

private struct ObjectProbe: View {
    let seen: Seen
    @InjectedObject(\SceneTestContainer.objectModel) var model
    var body: some View {
        let _ = seen.record(model.name)
        Text(model.name)
    }
}

private struct ContainerObjectProbe: View {
    let seen: Seen
    @InjectedObject(\.sceneTestObjectModel) var model
    var body: some View {
        let _ = seen.record(model.name)
        Text(model.name)
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
private struct ObservableProbe: View {
    let seen: Seen
    @InjectedObservable(\SceneTestContainer.observableModel) var model
    var body: some View {
        let _ = seen.record(model.name)
        Text(model.name)
    }
}

// MARK: - Tests

@MainActor
final class FactorySceneTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        SceneTestContainer.shared.manager.reset()
    }

    // MARK: SceneContainers

    func testSceneContainersFallBackToShared() {
        let containers = SceneContainers()
        XCTAssertTrue(containers[SceneTestContainer.self] === SceneTestContainer.shared)
        XCTAssertTrue(containers[Container.self] === Container.shared)
    }

    func testSceneContainersReturnInstalledContainerByType() {
        var containers = SceneContainers()
        let scene = SceneTestContainer()
        containers[SceneTestContainer.self] = scene
        XCTAssertTrue(containers[SceneTestContainer.self] === scene)
        XCTAssertTrue(containers[Container.self] === Container.shared)
    }

    func testSceneContainersEquality() {
        let scene = SceneTestContainer()
        var a = SceneContainers()
        var b = SceneContainers()
        XCTAssertEqual(a, b)
        a[SceneTestContainer.self] = scene
        XCTAssertNotEqual(a, b)
        b[SceneTestContainer.self] = scene
        XCTAssertEqual(a, b)
        b[SceneTestContainer.self] = SceneTestContainer()
        XCTAssertNotEqual(a, b)
    }

    func testContainerEnvironmentValueRoundTrips() {
        var environment = EnvironmentValues()
        XCTAssertTrue(environment.container === Container.shared)
        let scene = Container()
        environment.container = scene
        XCTAssertTrue(environment.container === scene)
        XCTAssertTrue(environment.sceneContainers[Container.self] === scene)
    }

    #if canImport(AppKit)

    // MARK: InjectedObject

    func testInjectedObjectCustomContainerFallsBackToShared() {
        let seen = Seen()
        let window = host(ObjectProbe(seen: seen))
        spin()
        XCTAssertEqual(seen.name, "shared")
        _ = window
    }

    func testInjectedObjectResolvesInstalledCustomContainer() {
        let scene = SceneTestContainer()
        scene.sceneTestName.register { "scene" }
        let seen = Seen()
        let window = host(ObjectProbe(seen: seen).withContainer(scene))
        spin()
        XCTAssertEqual(seen.name, "scene")
        XCTAssertEqual(SceneTestContainer.shared.sceneTestName(), "shared")
        _ = window
    }

    func testInjectedObjectUpdatesFromInstalledCustomContainer() {
        let scene = SceneTestContainer()
        let seen = Seen()
        let window = host(ObjectProbe(seen: seen).withContainer(scene))
        spin()
        let rendersBefore = seen.renders
        scene.objectModel().name = "mutated"
        spin()
        XCTAssertEqual(seen.name, "mutated")
        XCTAssertGreaterThan(seen.renders, rendersBefore)
        _ = window
    }

    func testInjectedObjectStillResolvesContainerFromEnvironment() {
        let scene = Container()
        scene.sceneTestName.register { "scene-default" }
        let seen = Seen()
        let window = host(ContainerObjectProbe(seen: seen).environment(\.container, scene))
        spin()
        XCTAssertEqual(seen.name, "scene-default")
        _ = window
    }

    // MARK: InjectedObservable

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    func testInjectedObservableResolvesInstalledCustomContainer() {
        let scene = SceneTestContainer()
        scene.sceneTestName.register { "scene" }
        let seen = Seen()
        let window = host(ObservableProbe(seen: seen).withContainer(scene))
        spin()
        XCTAssertEqual(seen.name, "scene")
        _ = window
    }

    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    func testInjectedObservableUpdatesFromInstalledCustomContainer() {
        let scene = SceneTestContainer()
        let seen = Seen()
        let window = host(ObservableProbe(seen: seen).withContainer(scene))
        spin()
        scene.observableModel().name = "mutated"
        spin()
        XCTAssertEqual(seen.name, "mutated")
        _ = window
    }

    // MARK: withContainer

    func testWithContainerClosureRegistersOnInstalledCustomContainer() {
        let scene = SceneTestContainer()
        let seen = Seen()
        let view = ObjectProbe(seen: seen)
            .withContainer(SceneTestContainer.self) { $0.sceneTestName.register { "closure" } }
            .withContainer(scene)
        let window = host(view)
        spin()
        XCTAssertEqual(seen.name, "closure")
        XCTAssertEqual(scene.sceneTestName(), "closure")
        XCTAssertEqual(SceneTestContainer.shared.sceneTestName(), "shared")
        _ = window
    }

    func testWithContainerKeyPathRegistersOnInstalledCustomContainer() {
        let scene = SceneTestContainer()
        let seen = Seen()
        let view = ObjectProbe(seen: seen)
            .withContainer(\SceneTestContainer.sceneTestName) { "keypath" }
            .withContainer(scene)
        let window = host(view)
        spin()
        XCTAssertEqual(seen.name, "keypath")
        XCTAssertEqual(SceneTestContainer.shared.sceneTestName(), "shared")
        _ = window
    }

    func testWithContainerAppliedOutsideRegistersOnShared() {
        let scene = SceneTestContainer()
        let seen = Seen()
        let view = ObjectProbe(seen: seen)
            .withContainer(scene)
            .withContainer(SceneTestContainer.self) { $0.sceneTestName.register { "leaked" } }
        let window = host(view)
        spin()
        XCTAssertEqual(SceneTestContainer.shared.sceneTestName(), "leaked")
        XCTAssertEqual(scene.sceneTestName(), "shared")
        _ = window
    }

    func testWithContainerImplicitKeyPathStillTargetsDefaultContainer() {
        let scene = Container()
        let seen = Seen()
        let view = ContainerObjectProbe(seen: seen)
            .withContainer(\.sceneTestName) { "implicit" }
            .environment(\.container, scene)
        let window = host(view)
        spin()
        XCTAssertEqual(seen.name, "implicit")
        XCTAssertEqual(scene.sceneTestName(), "implicit")
        XCTAssertEqual(Container.shared.sceneTestName(), "default")
        _ = window
    }

    // MARK: Hosting

    private func host<V: View>(_ view: V) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: view)
        window.orderBack(nil)
        return window
    }

    private func spin() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    }

    #endif

}
#endif
