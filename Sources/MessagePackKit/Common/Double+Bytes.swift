//
// See LICENSE and ATTRIBUTIONS files for copyright and licensing information.
//

import Foundation

internal extension Double {
    
    init(bytes: [UInt8]) {
        self.init(bitPattern: UInt64(bytes: bytes))
    }

    var bytes: [UInt8] {
        return self.bitPattern.bytes
    }
}
