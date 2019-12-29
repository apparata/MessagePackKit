//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

struct AnyCodingKey: CodingKey, Equatable {
    
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }
    
    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init<Key>(_ base: Key) where Key: CodingKey {
        if let intValue = base.intValue {
            self.init(intValue: intValue)!
        } else {
            self.init(stringValue: base.stringValue)!
        }
    }
}

extension AnyCodingKey: Hashable {

    func hash(into hasher: inout Hasher) {
        if let value = intValue {
            hasher.combine(value)
        } else {
            hasher.combine(stringValue)
        }
    }
}
