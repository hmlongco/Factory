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

        let containerCopy = Container()

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

        let containerCopy = Container()

        containerCopy.example.register {
            Example2()
        }

        Container.$shared.withValue(containerCopy) {
            let result = sut.execute()
            #expect(result == "bar")
        }
    }
}
