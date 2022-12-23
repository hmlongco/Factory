//
//  GenericAPIs.swift
//  FactoryDemo
//
//  Created by Michael Long on 12/23/22.
//

import Foundation
import Factory

struct Account {

}

struct Transaction {

}

protocol AccountLoading {
    func load() -> [Account]
}

struct AccountLoader: AccountLoading {
    func load() -> [Account] {
        return [Account()]
    }
}

extension Container {
    static let accountLoader = Factory<AccountLoading> {
        AccountLoader()
    }
}

struct MockAccountLoader: AccountLoading {
    func load() -> [Account] {
        return [Account()]
    }
}

func setupMocks() {
    Container.accountLoader.register { MockAccountLoader() }
}



struct NetworkLoader<T> {
    let path: String
    func load() -> T {
        fatalError()
    }
}

struct MockLoader<T> {
    let data: T
    func load() -> T {
        return data
    }
}

extension Container {
    static let genericAaccountLoader = Factory<AccountLoading> {
        NetworkLoader<[Account]>(path: "/api/accounts")
    }
}


extension NetworkLoader<[Account]>: AccountLoading {}
extension MockLoader<[Account]>: AccountLoading {}



//protocol TypeLoading {
//    associatedtype T
//    func load() -> T
//}

extension NetworkLoader: TypeLoading {}
extension MockLoader: TypeLoading {}


protocol TypeLoading<T> {
    associatedtype T
    func load() -> T
}

struct AnyLoader<T> {
    let wrapped: any TypeLoading<T>
    init(_ wrapped:  any TypeLoading<T>) {
        self.wrapped = wrapped
    }
    func load() -> T {
        wrapped.load()
    }
}

extension Container {
    static let anyAccountLoader = Factory<AnyLoader<[Account]>> {
        AnyLoader(NetworkLoader(path: "/api/accounts"))
    }
}

//extension Container {
//    static let typedAccountLoader = Factory<any TypeLoading<[Account]>> {
//        NetworkLoader<[Account]>(path: "/api/accounts") as any TypeLoading<[Account]>
//    }
//}


protocol NewAccountLoading: TypeLoading where T == [Account] {}

extension NetworkLoader<[Account]>: NewAccountLoading {}
extension MockLoader<[Account]>: NewAccountLoading {}

extension Container {
    static let newAccountLoader = Factory<any NewAccountLoading> {
        NetworkLoader<[Account]>(path: "/api/accounts")
    }
}



class AbstractClassLoader<T> {
    func load() -> T {
        fatalError()
    }
}

class NetworkClassLoader<T>: AbstractClassLoader<T> {
    private let path: String
    init(path: String) {
        self.path = path
    }
    override func load() -> T {
        fatalError() // would return actual data
    }
}

extension Container {
    static let abstractAccountLoader = Factory<AbstractClassLoader<[Account]>> {
        NetworkClassLoader<[Account]>(path: "/api/accounts")
    }
}

typealias LoadFunction<T> = () -> T

extension Container {
    static let functionalAccountLoader = Factory<LoadFunction<[Account]>> {
        NetworkClassLoader<[Account]>(path: "/api/accounts").load
    }
}


//extension Container {
//    static func setupModules() {
//        accountLoader.register {
//            NetworkLoader<[Account]>(path: "/api/accounts")
//        }
//    }
//}

class ViewModel: ObservableObject {
    @Injected(Container.abstractAccountLoader) var loader
    @Published var accounts: [Account] = []
    func load() {
        accounts = loader.load()
    }
}


//public struct Factory<T> {
//    public init(factory: @escaping () -> T) {
//        // save it
//    }
//    public func callAsFunction() -> T {
//        // do it
//    }
//}
