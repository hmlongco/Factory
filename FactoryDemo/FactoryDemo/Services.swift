//
//  Services.swift
//  Injectable2
//
//  Created by Michael Long on 5/8/22.
//

import Foundation


public class SimpleService {
    func text() -> String{
        "Hello World!"
    }
}


public protocol MyServiceType {
    func text() -> String
}

public class MyService: MyServiceType {
    public func text() -> String {
        "Hello World!"
    }
}


public class MockService1: MyServiceType {
    public func text() -> String {
        "Mock World!"
    }
}

public class MockService2: MyServiceType {
    public func text() -> String {
        "Mock Worlds!"
    }
}

public class MockServiceN: MyServiceType {
    let n: Int
    internal init(_ n: Int) {
        self.n = n
    }
    public func text() -> String {
        "Mock Number \(n)!"
    }
}

class ParameterService {
    let count: Int
    init(count: Int) {
        self.count = count
    }
    public func text() -> String {
        "Number is \(count)!"
    }
}

class MyConstructedService {

    private let service: MyServiceType

    init(service: MyServiceType) {
        self.service = service
    }

    func text() -> String {
        "Well, " + service.text()
    }

}
