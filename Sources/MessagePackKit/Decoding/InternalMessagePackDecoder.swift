//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal final class InternalMessagePackDecoder {
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    var container: MessagePackDecodingContainer?
    fileprivate var data: Data
    
    init(data: Data) {
        self.data = data
    }
}

extension InternalMessagePackDecoder: Decoder {
    
    fileprivate func assertCanCreateContainer() {
        precondition(container == nil)
    }
        
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key: CodingKey {
        assertCanCreateContainer()
        let container = InternalKeyedDecodingContainer<Key>(data: data,
                                                            codingPath: codingPath,
                                                            userInfo: userInfo)
        self.container = container
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        assertCanCreateContainer()
        let container = InternalUnkeyedDecodingContainer(data: data,
                                                         codingPath: codingPath,
                                                         userInfo: userInfo)
        self.container = container
        return container
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        assertCanCreateContainer()
        let container = InternalSingleValueDecodingContainer(data: data,
                                                             codingPath: codingPath,
                                                             userInfo: userInfo)
        self.container = container
        
        return container
    }
}
