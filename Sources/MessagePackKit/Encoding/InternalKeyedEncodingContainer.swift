//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation
    
internal final class InternalKeyedEncodingContainer<Key> where Key: CodingKey {

    private var storage: [AnyCodingKey: MessagePackEncodingContainer] = [:]
    
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    
    func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        codingPath + [key]
    }
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
}

extension InternalKeyedEncodingContainer: KeyedEncodingContainerProtocol {
    
    func encodeNil(forKey key: Key) throws {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }
    
    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = InternalSingleValueEncodingContainer(codingPath: nestedCodingPath(forKey: key), userInfo: userInfo)
        storage[AnyCodingKey(key)] = container
        return container
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = InternalUnkeyedEncodingContainer(codingPath: nestedCodingPath(forKey: key), userInfo: userInfo)
        storage[AnyCodingKey(key)] = container
        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = InternalKeyedEncodingContainer<NestedKey>(codingPath: nestedCodingPath(forKey: key), userInfo: userInfo)
        storage[AnyCodingKey(key)] = container
        return KeyedEncodingContainer(container)
    }
    
    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Unimplemented") // FIXME
    }
}

extension InternalKeyedEncodingContainer: MessagePackEncodingContainer {
    
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
        
        for key in storage.keys.sorted() {
            guard let container = storage[key] else {
                continue
            }
            let keyContainer = InternalSingleValueEncodingContainer(codingPath: codingPath, userInfo: userInfo)
            try! keyContainer.encode(key.stringValue)
            data.append(keyContainer.data)
            
            data.append(container.data)
        }
        
        return data
    }
}
