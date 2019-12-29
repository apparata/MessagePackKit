import XCTest
@testable import MessagePackKit

class MessagePackKitPerformanceTests: XCTestCase {
    
    var encoder: MessagePackEncoder!
    var decoder: MessagePackDecoder!
    
    override func setUp() {
        encoder = MessagePackEncoder()
        decoder = MessagePackDecoder()
    }
    
    func testPerformance() {
        let count = 100
        let values = [Airport](repeating: .example, count: count)
        
        measure {
            let encoded = try! encoder.encode(values)
            let decoded = try! decoder.decode([Airport].self, from: encoded)
            XCTAssertEqual(decoded.count, count)
        }
    }
}
