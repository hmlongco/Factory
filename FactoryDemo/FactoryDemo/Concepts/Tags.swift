//
//  Tags.swift
//  FactoryDemo
//
//  Created by Michael Long on 4/8/23.
//

import Foundation
import Factory

extension SharedContainer {
    var processor1: Factory<Processor> { self { Processor(name: "processor #1") } }
    var processor2: Factory<Processor> { self { Processor(name: "processor #2") } }
}

extension Container {
    static var processors: [KeyPath<Container, Factory<Processor>>] = [
        \.processor1,
        \.processor2,
    ]
    func processors() -> [Processor] {
        Container.processors.map { self[keyPath: $0]() }
    }
}

final class TaggedContainer: SharedContainer {
    static var shared = TaggedContainer()
    var manager = ContainerManager()
}

extension TaggedContainer: AutoRegistering {
    func autoRegister() {
        tag(\TaggedContainer.processor1, as: .pipelineProcessor)
        tag(\TaggedContainer.processor2, as: .pipelineProcessor)
    }
}




struct Processor {
    var name: String
}

struct PipelineProcessorTag : Tag {
    typealias S = Processor
}

extension Tag where Self == PipelineProcessorTag {
    static var pipelineProcessor: PipelineProcessorTag { PipelineProcessorTag() }
}



public protocol Tag<S> {
    associatedtype S
    var name: String { get }
}

extension Tag {
    var name: String {
        String(reflecting: type(of: self))
    }
}

protocol AnyTaggedFactory {
    var priority: Int { get }
}

struct TaggedFactory<C: SharedContainer, T: Tag> : AnyTaggedFactory {
    let tag: T
    let factoryKeyPath: KeyPath<C, Factory<T.S>>
    let priority: Int
    let alias: String?
}

// FactoryModifying tagging
extension SharedContainer {
    func tag<C: SharedContainer, T: Tag>(_ keyPath: KeyPath<C, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
        self._tag(keyPath, as: tag, priority: priority, alias: alias)
    }

    fileprivate func _tag<C: SharedContainer, T: Tag>(_ keyPath: KeyPath<C, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
        let taggedFactory = TaggedFactory(tag: tag, factoryKeyPath: keyPath, priority: priority, alias: alias)
        if taggedFactories[tag.name] == nil {
            taggedFactories[tag.name] = [:]
        }
        taggedFactories[tag.name]![C.shared[keyPath: keyPath].registration.id] = taggedFactory
    }

    func resolve<T: Tag>(tagged tag: T) -> [T.S] {
        let taggedFactories = taggedFactories[tag.name] ?? [:]
        var results: [T.S] = []
        for anyTaggedFactory in taggedFactories.values.sorted(by: { $0.priority < $1.priority }) {
            guard let taggedFactory = anyTaggedFactory as? TaggedFactory<Self, T> else {
                continue
            }
            let instance = self[keyPath: taggedFactory.factoryKeyPath].resolve()
            results.append(instance)
        }
        return results
    }

    func resolveAssociative<T: Tag>(tagged tag: T) -> [String: T.S] {
        let taggedFactories = taggedFactories[tag.name] ?? [:]
        var results: [String: T.S] = [:]
        for anyTaggedFactory in taggedFactories.values {
            guard let taggedFactory = anyTaggedFactory as? TaggedFactory<Self, T>, let alias = taggedFactory.alias else {
                continue
            }
            results[alias] = self[keyPath: taggedFactory.factoryKeyPath].resolve()
        }
        return results
    }
}

extension Container {
    func tag<T: Tag>(_ keyPath: KeyPath<Container, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
        self._tag(keyPath, as: tag, priority: priority, alias: alias)
    }
}

// would go in manager

/// Alias for tagged registrations.
internal typealias TaggedFactoryMap = [String:[String: AnyTaggedFactory]]
/// tagged registrations
internal var taggedFactories: TaggedFactoryMap = .init(minimumCapacity: 32)

//extension TaggedContainer: AutoRegistering {
//    func autoRegister() {
//        tag(\TaggedContainer.processor1, as: .pipelineProcessor)
//        tag(\TaggedContainer.processor2, as: .pipelineProcessor)
//    }
//
//    var processor1: Factory<Processor> { self { Processor(name: "processor #1") } }
//    var processor2: Factory<Processor> { self { Processor(name: "processor #2") } }
//
//}
//
//final class TaggedContainer: SharedContainer {
//    static var shared = TaggedContainer()
//
//    private var tags: [String:[AnyTaggedFactoryReference]] = [:]
//
//    func tag<C,T,G>(_ keyPath: KeyPath<C, Factory<T>>, as tag: G) where C: ManagedContainer, G:Tag, G.T == T {
//        let name = tag.name
//        if tags[name] == nil {
//            tags[name] = []
//        }
//        tags[name]?.append(TaggedFactoryReference(keypath: keyPath))
//    }
//
//    func resolve<G,T>(tagged: G) -> [T] where G:Tag, G.T == T {
//        if tags.isEmpty {
//            autoRegister() // chicken and egg issue
//        }
//        let tagged: [AnyTaggedFactoryReference] = tags[tagged.name] ?? []
//        var results: [T] = []
//        for entry in tagged {
//            if let ref = entry as? TaggedFactoryReference<Self, T> {
//                results.append(ref.resolve(from: self as! Self))
//            }
//        }
//        return results
//    }
//
//    var manager = ContainerManager()
//}
//
//internal protocol AnyTaggedFactoryReference {}
//
//internal struct TaggedFactoryReference<C: ManagedContainer, T>: AnyTaggedFactoryReference {
//    var keypath: KeyPath<C, Factory<T>>
//    func resolve(from container: C) -> T {
//        let factory: Factory<T> = container[keyPath: keypath]
//        return factory()
//    }
//}
