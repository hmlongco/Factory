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
        Container.shared.example.register {
            Example1()
        }
        let result = sut.execute()
        #expect(result == "foo")
    }

    @Test
    func bar() {
        let sut = SomeUseCase()
        Container.shared.example.register {
            Example2()
        }
        let result = sut.execute()
        #expect(result == "bar")
    }
}
