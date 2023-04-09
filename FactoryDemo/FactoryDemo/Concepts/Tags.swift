//
//  Tags.swift
//  FactoryDemo
//
//  Created by Michael Long on 4/8/23.
//

import Foundation
import Factory

public protocol Tag {
    associatedtype T
    var name: String { get }
}

extension Tag {
    var name: String {
        String(describing: self)
    }
}

struct Processor {
    var name: String
}

struct PipelineProcessorTag : Tag {
    typealias T = Processor
}

extension Tag where Self == PipelineProcessorTag {
    static var pipelineProcessor: PipelineProcessorTag { PipelineProcessorTag() }
}

extension TaggedContainer: AutoRegistering {
    func autoRegister() {
        tag(.pipelineProcessor, keyPath: \TaggedContainer.processor1)
        tag(.pipelineProcessor, keyPath: \TaggedContainer.processor2)
//        processor1.tag(.pipelineProcessor) ideal???
    }

    var processor1: Factory<Processor> { self { Processor(name: "processor #1") } }
    var processor2: Factory<Processor> { self { Processor(name: "processor #2") } }

}

final class TaggedContainer: SharedContainer {
    static var shared = TaggedContainer()

    private var tags: [String:[AnyTaggedFactoryReference]] = [:]

    func tag<C,G,T>(_ tag: G, keyPath: KeyPath<C, Factory<T>>) where C: ManagedContainer, G:Tag, G.T == T {
        let name = tag.name
        if tags[name] == nil {
            tags[name] = []
        }
        tags[name]?.append(TaggedFactoryReference(keypath: keyPath))
    }

    func resolve<G,T>(tagged: G) -> [T] where G:Tag, G.T == T {
        if tags.isEmpty {
            autoRegister() // chicken and egg issue
        }
        let tagged: [AnyTaggedFactoryReference] = tags[tagged.name] ?? []
        var results: [T] = []
        for entry in tagged {
            if let ref = entry as? TaggedFactoryReference<Self, T> {
                results.append(ref.resolve(from: self as! Self))
            }
        }
        return results
    }

    var manager = ContainerManager()
}

internal protocol AnyTaggedFactoryReference {}

internal struct TaggedFactoryReference<C: ManagedContainer, T>: AnyTaggedFactoryReference {
    var keypath: KeyPath<C, Factory<T>>
    func resolve(from container: C) -> T {
        let factory: Factory<T> = container[keyPath: keypath]
        return factory()
    }
}
