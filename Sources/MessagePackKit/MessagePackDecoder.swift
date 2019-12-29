//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

/// Encodes objects and values from the MessagePack format.
public final class MessagePackDecoder {
    
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    public init() {
        //
    }
        
    /// Decodes a value of specified type from MessagePack data.
    ///
    /// - parameter type: Type of value to decode.
    /// - parameter data: MessagePack data to decode from.
    /// - throws: `DecodingError.dataCorrupted(_:)` if data is not MessagePack.
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let decoder = InternalMessagePackDecoder(data: data)
        decoder.userInfo = self.userInfo
        
        switch type {
        case is Data.Type:
            let box = try Box<Data>(from: decoder)
            return box.value as! T
        case is Date.Type:
            let box = try Box<Date>(from: decoder)
            return box.value as! T
        default:
            return try T(from: decoder)
        }
    }
}
