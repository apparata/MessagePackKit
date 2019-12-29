//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal class InternalKeyedEndcodingContainer<Key> where Key: CodingKey {
    
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    private var storage: [String: MessagePackEncodingContainer] = [:]
        
    func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
}

extension InternalKeyedEndcodingContainer: KeyedEncodingContainerProtocol {
    
    func encodeNil(forKey key: Key) throws {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }
    
    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let codingPath = nestedCodingPath(forKey: key)
        let container = InternalSingleValueEncodingContainer(codingPath: codingPath,
                                                     userInfo: userInfo)
        storage[key.stringValue] = container
        return container
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let codingPath = nestedCodingPath(forKey: key)
        let container = InternalUnkeyedEncodingContainer(codingPath: codingPath,
                                                 userInfo: userInfo)
        storage[key.stringValue] = container
        
        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let codingPath = nestedCodingPath(forKey: key)
        let container = InternalKeyedEndcodingContainer<NestedKey>(codingPath: codingPath,
                                                          userInfo: userInfo)
        storage[key.stringValue] = container
        
        return KeyedEncodingContainer(container)
    }
    
    func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Unimplemented")
    }
}

extension InternalKeyedEndcodingContainer: MessagePackEncodingContainer {
    
    var data: Data {
        var data = Data()
        
        let length = storage.count
        if let uint16 = UInt16(exactly: length) {
            if length <= 15 {
                data.append(0x80 + UInt8(length))
            } else {
                data.append(0xde)
                data.append(contentsOf: uint16.bytes)
            }
        } else if let uint32 = UInt32(exactly: length) {
            data.append(0xdf)
            data.append(contentsOf: uint32.bytes)
        } else {
            fatalError()
        }
        
        for (key, container) in self.storage {
            let keyContainer = InternalSingleValueEncodingContainer(codingPath: codingPath,
                                                            userInfo: userInfo)
            try! keyContainer.encode(key)
            data.append(keyContainer.data)
            
            data.append(container.data)
        }
        
        return data
    }
}
