//
//  Tags.swift
//  FactoryDemo
//
//  Created by Michael Long on 4/8/23.
//

import Foundation
import FactoryKit

extension SharedContainer {
    var processor1: Factory<Processor> { self { Processor(name: "processor #1") } }
    var processor2: Factory<Processor> { self { Processor(name: "processor #2") } }
}

//extension Container {
//    static var processors: [KeyPath<Container, Factory<Processor>>] = [
//        \.processor1,
//        \.processor2,
//    ]
//    func processors() -> [Processor] {
//        Container.processors.map { self[keyPath: $0]() }
//    }
//}

nonisolated final class TaggedContainer: SharedContainer {
    static let shared = TaggedContainer()
    let manager = ContainerManager()
}

//extension TaggedContainer: AutoRegistering {
//    func autoRegister() {
//        tag(\TaggedContainer.processor1, as: .pipelineProcessor)
//        tag(\TaggedContainer.processor2, as: .pipelineProcessor)
//    }
//}

nonisolated struct Tag<T>: @unchecked Sendable {
    let path: KeyPath<Container, Factory<T>>
    let priority: Int
}

extension Container {
    static let processors: [Tag<Processor>] = [
        Tag(path: \.processor1, priority: 20),
        Tag(path: \.processor2, priority: 10),
    ]
    func processors() -> [Processor] {
        Container.processors
            .sorted(by: { $0.priority < $1.priority })
            .map { self[keyPath: $0.path]() }
    }
}



struct Processor {
    var name: String
}

//struct PipelineProcessorTag : Tag {
//    typealias S = Processor
//}
//
//extension Tag where Self == PipelineProcessorTag {
//    static var pipelineProcessor: PipelineProcessorTag { PipelineProcessorTag() }
//}

//public protocol Tag<S> {
//    associatedtype S
//    var name: String { get }
//}
//
//extension Tag {
//    var name: String {
//        String(reflecting: type(of: self))
//    }
//}
//
//protocol AnyTaggedFactory {
//    var priority: Int { get }
//}
//
//struct TaggedFactory<C: SharedContainer, T: Tag> : AnyTaggedFactory {
//    let tag: T
//    let factoryKeyPath: KeyPath<C, Factory<T.S>>
//    let priority: Int
//    let alias: String?
//}
//
//// FactoryModifying tagging
//extension SharedContainer {
//    func tag<C: SharedContainer, T: Tag>(_ keyPath: KeyPath<C, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
//        self._tag(keyPath, as: tag, priority: priority, alias: alias)
//    }
//
//    fileprivate func _tag<C: SharedContainer, T: Tag>(_ keyPath: KeyPath<C, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
//        let taggedFactory = TaggedFactory(tag: tag, factoryKeyPath: keyPath, priority: priority, alias: alias)
//        if taggedFactories[tag.name] == nil {
//            taggedFactories[tag.name] = [:]
//        }
//        taggedFactories[tag.name]![C.shared[keyPath: keyPath].registration.id] = taggedFactory
//    }
//
//    func resolve<T: Tag>(tagged tag: T) -> [T.S] {
//        let taggedFactories = taggedFactories[tag.name] ?? [:]
//        var results: [T.S] = []
//        for anyTaggedFactory in taggedFactories.values.sorted(by: { $0.priority < $1.priority }) {
//            guard let taggedFactory = anyTaggedFactory as? TaggedFactory<Self, T> else {
//                continue
//            }
//            let instance = self[keyPath: taggedFactory.factoryKeyPath].resolve()
//            results.append(instance)
//        }
//        return results
//    }
//
//    func resolveAssociative<T: Tag>(tagged tag: T) -> [String: T.S] {
//        let taggedFactories = taggedFactories[tag.name] ?? [:]
//        var results: [String: T.S] = [:]
//        for anyTaggedFactory in taggedFactories.values {
//            guard let taggedFactory = anyTaggedFactory as? TaggedFactory<Self, T>, let alias = taggedFactory.alias else {
//                continue
//            }
//            results[alias] = self[keyPath: taggedFactory.factoryKeyPath].resolve()
//        }
//        return results
//    }
//}
//
//extension Container {
//    func tag<T: Tag>(_ keyPath: KeyPath<Container, Factory<T.S>>, as tag: T, priority: Int = 0, alias: String? = nil) {
//        self._tag(keyPath, as: tag, priority: priority, alias: alias)
//    }
//}
//
//// would go in manager
//
///// Alias for tagged registrations.
//internal typealias TaggedFactoryMap = [String:[String: AnyTaggedFactory]]
///// tagged registrations
//internal var taggedFactories: TaggedFactoryMap = .init(minimumCapacity: 32)
