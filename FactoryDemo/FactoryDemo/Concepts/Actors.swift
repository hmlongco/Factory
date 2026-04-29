//
//  SomeActor.swift
//  FactoryDemo
//
//  Created by Michael Long on 9/12/22.
//

import Foundation
import FactoryKit

extension Container {
    var myActor: Factory<SomeActor> { self { SomeActor() } }
    var mainActorFuncTest: Factory<MainActorFuncTest> { self { MainActorFuncTest() } }
}

extension Container {
    @MainActor var mainActorTest1: Factory<MainActorTest1> { self { MainActorTest1() } }
    var mainActorTest2: Factory<MainActorTest2> { self { MainActorTest2() } }
}

@MainActor
class MainActorTest1 {
    init() {}
    func load() async -> String {
        return "Acting"
    }
}

@MainActor
class MainActorTest2 {
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

@MainActor
class SomeActorParent {

    @Injected(\.mainActorTest1) var mainActor
    @Injected(\.myActor) var myActor

    let myTest0 = Container.shared.mainActorFuncTest()
    let myTest1 = Container.shared.mainActorTest1()
    let myTest2 = Container.shared.mainActorTest2()

    func test() async {
        let result0 = await myActor.load()
        print(result0)
        let result1 = await myTest1.load()
        print(result1)
        let result2 = await myTest2.load()
        print(result2)
    }

}
