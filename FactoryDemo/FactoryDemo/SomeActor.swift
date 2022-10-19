//
//  SomeActor.swift
//  FactoryDemo
//
//  Created by Michael Long on 9/12/22.
//

import Foundation
import Factory

extension Container {
    static var myActor = Factory { SomeActor() }
    static var mainActorFuncTest = Factory { MainActorFuncTest() }

}

extension Container {
    static var mainActorTest = Factory { MainActorTest() }
}

@MainActor
class MainActorTest {
    nonisolated init() {}
    func load() async -> String {
        return "Acting"
    }
}

class MainActorFuncTest {
    @MainActor
    func load() async -> String {
        return "Acting"
    }
}

actor SomeActor {
    func load() async -> String {
        return "Acting"
    }
}

class SomeActorParent {

    @Injected(Container.myActor) var myActor

    let myTest1 = Container.mainActorFuncTest()
    let myTest2 = Container.mainActorTest()

    @MainActor
    func test() async {
        let result0 = await myActor.load()
        print(result0)
        let result1 = await myTest1.load()
        print(result1)
        let result2 = await myTest2.load()
        print(result2)
    }

}
