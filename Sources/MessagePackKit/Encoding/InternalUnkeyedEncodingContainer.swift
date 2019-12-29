//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal class InternalUnkeyedEncodingContainer {
    
    struct Index: CodingKey {
        var intValue: Int?
        
        var stringValue: String {
            return "\(self.intValue!)"
        }
        
        init?(intValue: Int) {
            self.intValue = intValue
        }
        
        init?(stringValue: String) {
            return nil
        }
    }
        
    var count: Int {
        return storage.count
    }
    
    var codingPath: [CodingKey]
    
    var nestedCodingPath: [CodingKey] {
        return self.codingPath + [Index(intValue: self.count)!]
    }
    
    var userInfo: [CodingUserInfoKey: Any]
    
    private var storage: [MessagePackEncodingContainer] = []
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
}

extension InternalUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    
    func encodeNil() throws {
        var container = nestedSingleValueContainer()
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        var container = nestedSingleValueContainer()
        try container.encode(value)
    }

    func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        return InternalSingleValueEncodingContainer(codingPath: nestedCodingPath,
                                            userInfo: userInfo)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = InternalKeyedEndcodingContainer<NestedKey>(codingPath: nestedCodingPath,
                                                          userInfo: userInfo)
        storage.append(container)
        
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = InternalUnkeyedEncodingContainer(codingPath: nestedCodingPath,
                                                 userInfo: userInfo)
        storage.append(container)
        
        return container
    }

    func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }
}

extension InternalUnkeyedEncodingContainer: MessagePackEncodingContainer {
    var data: Data {
        var data = Data()
        
        let length = storage.count
        if let uint16 = UInt16(exactly: length) {
            if uint16 <= 15 {
                data.append(UInt8(0x90 + uint16))
            } else {
                data.append(0xdc)
                data.append(contentsOf: uint16.bytes)
            }
        } else if let uint32 = UInt32(exactly: length) {
            data.append(0xdd)
            data.append(contentsOf: uint32.bytes)
        } else {
            fatalError()
        }
        
        for container in storage {
            data.append(container.data)
        }
        
        return data
    }
}
