//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

// MARK: - MessagePackEncoder

/// Encodes objects and values in the MessagePack format.
public final class MessagePackEncoder {
    
    public init() {
        //
    }

    /// Encodes the value in MessagePack format.
    ///
    /// Example:
    ///
    /// ```
    /// struct Vehicle: Codable {
    ///     var manufacturer: String
    ///     var model: String
    ///     var wheels: Int
    /// }
    ///
    /// let vehicle = Car(manufacturer: "Volvo",
    ///                   model: "XC70",
    ///                   wheels: 4)
    ///
    /// let encoder = MessagePackEncoder()
    /// let data = try! encoder.encode(vehicle)
    /// print(data.map { String(format:"%2X", $0) })
    /// ```
    ///
    public func encode(_ value: Encodable) throws -> Data {
        let encoder = InternalMessagePackEncoder()
        try value.encode(to: encoder)
        return encoder.data
    }
}
