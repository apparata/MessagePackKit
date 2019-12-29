//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal class InternalMessagePackEncoder {
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    fileprivate var container: MessagePackEncodingContainer?
    var data: Data {
        return container?.data ?? Data()
    }
}

extension InternalMessagePackEncoder: Encoder {
    
    fileprivate func assertCanCreateContainer() {
        precondition(container == nil)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        assertCanCreateContainer()
        let container = InternalKeyedEncodingContainer<Key>(codingPath: codingPath,
                                                            userInfo: userInfo)
        self.container = container
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()
        let container = InternalUnkeyedEncodingContainer(codingPath: codingPath,
                                                         userInfo: userInfo)
        self.container = container
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()
        let container = InternalSingleValueEncodingContainer(codingPath: codingPath,
                                                             userInfo: userInfo)
        self.container = container
        return container
    }
}
