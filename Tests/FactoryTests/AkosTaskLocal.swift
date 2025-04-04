//
//  AkosTaskLocal.swift
//  Factory
//
//  Created by Grabecz, Akos on 2025. 04. 04..
//

@testable import Factory
import Testing

@Suite
struct PlayingWithTaskLocal {
    @Test
    func foo() {
        let sut = SomeUseCase()

        var containerCopy = Container()

        var containerManagerCopy = ContainerManager()
        containerManagerCopy.defaultScope = Container.shared.manager.defaultScope
        containerManagerCopy.dependencyChainTestMax = Container.shared.manager.dependencyChainTestMax
        containerManagerCopy.promiseTriggersError = Container.shared.manager.promiseTriggersError
        containerManagerCopy.trace = Container.shared.manager.trace
        containerManagerCopy.logger = Container.shared.manager.logger

        containerCopy.setManager(to: containerManagerCopy)

        containerCopy.example.register {
            Example1()
        }

        Container.$shared.withValue(containerCopy) {
            let result = sut.execute()
            #expect(result == "foo")
        }
    }

    @Test
    func bar() {
        let sut = SomeUseCase()

        var containerCopy = Container()
        var containerManagerCopy = ContainerManager()
        containerManagerCopy.defaultScope = Container.shared.manager.defaultScope
        containerManagerCopy.dependencyChainTestMax = Container.shared.manager.dependencyChainTestMax
        containerManagerCopy.promiseTriggersError = Container.shared.manager.promiseTriggersError
        containerManagerCopy.trace = Container.shared.manager.trace
        containerManagerCopy.logger = Container.shared.manager.logger

        containerCopy.setManager(to: containerManagerCopy)

        containerCopy.example.register {
            Example2()
        }

        Container.$shared.withValue(containerCopy) {
            let result = sut.execute()
            #expect(result == "bar")
        }
    }
}
