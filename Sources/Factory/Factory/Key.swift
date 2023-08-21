//
//  Key.swift
//  
//
//  Created by Michael Long on 8/17/23.
//

import Foundation

public struct FactoryKey: Hashable {

    public let type: Int
    public let key: Int

    internal init(type: Any.Type, key: StaticString) {
        self.type = Int(bitPattern: ObjectIdentifier(type))
        if key.hasPointerRepresentation {
            self.key = Int(bitPattern: key.utf8Start)
        } else {
            self.key = Int(key.unicodeScalar.value)
        }
    }

}
