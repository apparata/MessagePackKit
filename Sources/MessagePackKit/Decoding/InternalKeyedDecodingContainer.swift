//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal final class InternalKeyedDecodingContainer<Key>: MessagePackDecodingContainer where Key: CodingKey {
    
    lazy var nestedContainers: [String: MessagePackDecodingContainer] = {
        guard let count = count else {
            return [:]
        }
        
        var nestedContainers: [String: MessagePackDecodingContainer] = [:]
        
        let unkeyedContainer = InternalUnkeyedDecodingContainer(data: data.suffix(from: index), codingPath: codingPath, userInfo: userInfo)
        unkeyedContainer.count = count * 2
        
        do {
            var iterator = unkeyedContainer.nestedContainers.makeIterator()

            for _ in 0..<count {
                guard let keyContainer = iterator.next() as? InternalSingleValueDecodingContainer,
                    let container = iterator.next() else {
                    fatalError() // FIXME
                }
                
                let key = try keyContainer.decode(String.self)
                container.codingPath += [AnyCodingKey(stringValue: key)!]
                nestedContainers[key] = container
            }
        } catch {
            fatalError("\(error)") // FIXME
        }
        
        index = unkeyedContainer.index
        
        return nestedContainers
    }()
    
    lazy var count: Int? = {
        do {
            let format = try readByte()
            switch format {
            case 0x80...0x8f:
                return Int(format & 0x0F)
            case 0xde:
                return Int(try read(UInt16.self))
            case 0xdf:
                return Int(try read(UInt32.self))
            default:
                return nil
            }
        } catch {
            return nil
        }
    }()

    var data: Data
    var index: Data.Index
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.data = data
        self.index = self.data.startIndex
    }
    
    func checkCanDecodeValue(forKey key: Key) throws {
        guard self.contains(key) else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "key not found: \(key)")
            throw DecodingError.keyNotFound(key, context)
        }
    }
}

extension InternalKeyedDecodingContainer: KeyedDecodingContainerProtocol {
    
    var allKeys: [Key] {
        nestedContainers.keys.map{ Key(stringValue: $0)! }
    }
    
    func contains(_ key: Key) -> Bool {
        nestedContainers.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        let nestedContainer = nestedContainers[key.stringValue]

        switch nestedContainer {
        case let singleValueContainer as InternalSingleValueDecodingContainer:
            return singleValueContainer.decodeNil()
        case is InternalUnkeyedDecodingContainer,
             is InternalKeyedDecodingContainer<AnyCodingKey>:
            return false
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "cannot decode nil for key: \(key)")
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        try checkCanDecodeValue(forKey: key)
        
        let container = nestedContainers[key.stringValue]!
        let decoder = MessagePackDecoder()
        let value = try decoder.decode(T.self, from: container.data)
        
        return value
    }
    
 
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)
        
        guard let unkeyedContainer = nestedContainers[key.stringValue] as? InternalUnkeyedDecodingContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        
        return unkeyedContainer
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkCanDecodeValue(forKey: key)
        
        guard let keyedContainer = nestedContainers[key.stringValue] as? InternalKeyedDecodingContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        
        return KeyedDecodingContainer(keyedContainer)
    }
    
    func superDecoder() throws -> Decoder {
        return InternalMessagePackDecoder(data: data)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = InternalMessagePackDecoder(data: data)
        decoder.codingPath = [key]
        
        return decoder
    }
}
