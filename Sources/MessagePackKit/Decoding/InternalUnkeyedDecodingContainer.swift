//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation
    
internal final class InternalUnkeyedDecodingContainer: MessagePackDecodingContainer {
    
    var codingPath: [CodingKey]
    
    var nestedCodingPath: [CodingKey] {
        codingPath + [AnyCodingKey(intValue: count ?? 0)!]
    }
    
    var userInfo: [CodingUserInfoKey: Any]
    
    var data: Data
    var index: Data.Index
    
    lazy var count: Int? = {
        do {
            let format = try readByte()
            switch format {
            case 0x90...0x9f:
                return Int(format & 0x0F)
            case 0xdc:
                return Int(try read(UInt16.self))
            case 0xdd:
                return Int(try read(UInt32.self))
            default:
                return nil
            }
        } catch {
            return nil
        }
    }()
    
    var currentIndex: Int = 0
    
    lazy var nestedContainers: [MessagePackDecodingContainer] = {
        guard let count = count else {
            return []
        }
        
        var nestedContainers: [MessagePackDecodingContainer] = []
        
        do {
            for _ in 0..<count {
                let container = try decodeContainer()
                nestedContainers.append(container)
            }
        } catch {
            fatalError("\(error)") // FIXME
        }
        
        currentIndex = 0
        
        return nestedContainers
    }()
    
    init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.data = data
        self.index = self.data.startIndex
    }
    
    var isAtEnd: Bool {
        guard let count = count else {
            return true
        }
        
        return currentIndex >= count
    }
    
    func checkCanDecodeValue() throws {
        guard !isAtEnd else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
        }
    }
}

extension InternalUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    func decodeNil() throws -> Bool {
        try checkCanDecodeValue()
        defer { currentIndex += 1 }

        let nestedContainer = nestedContainers[currentIndex]

        switch nestedContainer {
        case let singleValueContainer as InternalSingleValueDecodingContainer:
            return singleValueContainer.decodeNil()
        case is InternalUnkeyedDecodingContainer,
             is InternalKeyedDecodingContainer<AnyCodingKey>:
            return false
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "cannot decode nil for index: \(currentIndex)")
                       throw DecodingError.typeMismatch(Any?.self, context)
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try checkCanDecodeValue()
        defer { currentIndex += 1 }
        
        let container = nestedContainers[currentIndex]
        let decoder = MessagePackDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue()
        defer { currentIndex += 1 }

        let container = nestedContainers[currentIndex] as! InternalUnkeyedDecodingContainer
        
        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkCanDecodeValue()
        defer { currentIndex += 1 }

        let container = nestedContainers[currentIndex] as! InternalKeyedDecodingContainer<NestedKey>
        
        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        return InternalMessagePackDecoder(data: data)
    }
}

extension InternalUnkeyedDecodingContainer {
    
    func decodeContainer() throws -> MessagePackDecodingContainer {
        try checkCanDecodeValue()
        defer { currentIndex += 1 }
        
        let startIndex = index
        
        let length: Int
        let format = try self.readByte()
        switch format {
        case 0x00...0x7f,
             0xc0, 0xc2, 0xc3,
             0xe0...0xff:
            length = 0
        case 0xcc, 0xd0, 0xd4:
            length = 1
        case 0xcd, 0xd1, 0xd5:
            length = 2
        case 0xca, 0xce, 0xd2:
            length = 4
        case 0xcb, 0xcf, 0xd3:
            length = 8
        case 0xd6:
            length = 5
        case 0xd7:
            length = 9
        case 0xd8:
            length = 16
        case 0xa0...0xbf:
            length = Int(format - 0xa0)
        case 0xc4, 0xc7, 0xd9:
            length = Int(try read(UInt8.self))
        case 0xc5, 0xc8, 0xda:
            length = Int(try read(UInt16.self))
        case 0xc6, 0xc9, 0xdb:
            length = Int(try read(UInt32.self))
        case 0x80...0x8f, 0xde, 0xdf:
            let container = InternalKeyedDecodingContainer<AnyCodingKey>(data: self.data.suffix(from: startIndex), codingPath: nestedCodingPath, userInfo: self.userInfo)
            _ = container.nestedContainers // FIXME
            index = container.index
            
            return container
        case 0x90...0x9f, 0xdc, 0xdd:
            let container = InternalUnkeyedDecodingContainer(data: data.suffix(from: startIndex), codingPath: nestedCodingPath, userInfo: userInfo)
            _ = container.nestedContainers // FIXME

            index = container.index
            
            return container
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid format: \(format)")
        }
        
        let range: Range<Data.Index> = startIndex..<index.advanced(by: length)
        index = range.upperBound
        
        let container = InternalSingleValueDecodingContainer(data: data.subdata(in: range), codingPath: codingPath, userInfo: userInfo)

        return container
    }
}
