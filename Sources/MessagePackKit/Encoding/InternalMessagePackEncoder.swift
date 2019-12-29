//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal class InternalMessagePackEncoder {
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]

    var data: Data {
        return container?.data ?? Data()
    }

    fileprivate var container: MessagePackEncodingContainer?
}

extension InternalMessagePackEncoder: Encoder {
        
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = InternalKeyedEndcodingContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = InternalUnkeyedEncodingContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = InternalSingleValueEncodingContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        return container
    }
}
