//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal protocol MessagePackDecodingContainer: class {
    
    var codingPath: [CodingKey] { get set }
    var userInfo: [CodingUserInfoKey: Any] { get }
    var data: Data { get set }
    var index: Data.Index { get set }
}

extension MessagePackDecodingContainer {
    
    func readByte() throws -> UInt8 {
        return try read(1).first!
    }
    
    func read(_ length: Int) throws -> Data {
        let nextIndex = index.advanced(by: length)
        guard nextIndex <= data.endIndex else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Unexpected end of data")
            throw DecodingError.dataCorrupted(context)
        }
        defer { index = nextIndex }
        
        return data.subdata(in: index..<nextIndex)
    }
    
    func read<T>(_ type: T.Type) throws -> T where T: FixedWidthInteger {
        let stride = MemoryLayout<T>.stride
        let bytes = [UInt8](try read(stride))
        return T(bytes: bytes)
    }
}
