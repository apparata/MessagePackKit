//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

#if os(Linux)
let NSEC_PER_SEC: UInt64 = 1000000000
#endif
    
internal final class InternalSingleValueDecodingContainer: MessagePackDecodingContainer {
    
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var data: Data
    var index: Data.Index

    init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.data = data
        self.index = self.data.startIndex
    }
    
    func checkCanDecode<T>(_ type: T.Type, format: UInt8) throws {
        guard index <= data.endIndex else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
        }
        
        guard data[index] == format else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(type, context)
        }
    }
}

extension InternalSingleValueDecodingContainer: SingleValueDecodingContainer {
    
    func decodeNil() -> Bool {
        let format = try? readByte()
        return format == 0xc0
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        let format = try readByte()
        switch format {
        case 0xc2: return false
        case 0xc3: return true
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }
    
    func decode(_ type: String.Type) throws -> String {
        let length: Int
        let format = try readByte()
        switch format {
        case 0xa0...0xbf:
            length = Int(format - 0xa0)
        case 0xd9:
            length = Int(try read(UInt8.self))
        case 0xda:
            length = Int(try read(UInt16.self))
        case 0xdb:
            length = Int(try read(UInt32.self))
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
        
        let data = try read(length)
        guard let string = String(data: data, encoding: .utf8) else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Couldn't decode string with UTF-8 encoding")
            throw DecodingError.dataCorrupted(context)
        }
        
        return string
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        let format = try readByte()
        switch format {
        case 0xca:
            let bitPattern = try read(UInt32.self)
            return Double(bitPattern: UInt64(bitPattern))
        case 0xcb:
            let bitPattern = try read(UInt64.self)
            return Double(bitPattern: bitPattern)
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        let format = try readByte()
        switch format {
        case 0xca:
            let bitPattern = try read(UInt32.self)
            return Float(bitPattern: bitPattern)
        case 0xcb:
            guard let bitPattern = UInt32(exactly: try read(UInt32.self)) else {
                fallthrough
            }
            return Float(bitPattern: bitPattern)
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: BinaryInteger & Decodable {
        let format = try readByte()
        var value: T?
        
        switch format {
        case 0x00...0x7f:
            value = T(format)
        case 0xcc:
            value = T(exactly: try read(UInt8.self))
        case 0xcd:
            value = T(exactly: try read(UInt16.self))
        case 0xce:
            value = T(exactly: try read(UInt32.self))
        case 0xcf:
            value = T(exactly: try read(UInt64.self))
        case 0xd0:
            value = T(exactly: try read(Int8.self))
        case 0xd1:
            value = T(exactly: try read(Int16.self))
        case 0xd2:
            value = T(exactly: try read(Int32.self))
        case 0xd3:
            value = T(exactly: try read(Int64.self))
        case 0xe0...0xff:
            value = T(exactly: 0x1f & (format - 0xe0))
        default:
            value = nil
        }
        
        guard let integerValue = value else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(T.self, context)
        }
        
        return integerValue
    }
    
    func decode(_ type: Date.Type) throws -> Date {
        let format = try readByte()
        
        var seconds: TimeInterval
        var nanoseconds: TimeInterval
        
        switch format {
        case 0xd6:
            _ = try read(Int8.self) // -1
            nanoseconds = 0
            seconds = TimeInterval(try read(UInt32.self))
        case 0xd7:
            _ = try read(Int8.self) // -1
            let bitPattern = try read(UInt64.self)
            nanoseconds = TimeInterval(UInt32(bitPattern >> 34))
            seconds = TimeInterval(UInt32(bitPattern & 0x03_FF_FF_FF_FF))
        case 0xc7:
            _ = try read(Int8.self) // 12
            _ = try read(Int8.self) // -1
            nanoseconds = TimeInterval(try read(UInt32.self))
            seconds = TimeInterval(try read(Int64.self))
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
        
        let timeInterval = TimeInterval(seconds) + nanoseconds / Double(NSEC_PER_SEC)
        
        return Date(timeIntervalSince1970: timeInterval)
    }
    
    func decode(_ type: Data.Type) throws -> Data {
        let length: Int
        let format = try readByte()
        switch format {
        case 0xc4:
            length = Int(try read(UInt8.self))
        case 0xc5:
            length = Int(try read(UInt16.self))
        case 0xc6:
            length = Int(try read(UInt32.self))
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(UInt.self, context)
        }
        
        return self.data.subdata(in: index..<index.advanced(by: length))
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Data.Type:
            return try decode(Data.self) as! T
        case is Date.Type:
            return try decode(Date.self) as! T
        default:
            let decoder = InternalMessagePackDecoder(data: data)
            let value = try T(from: decoder)
            if let nextIndex = decoder.container?.index {
                index = nextIndex
            }
            
            return value
        }
    }
}
