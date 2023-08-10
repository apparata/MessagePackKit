import XCTest
@testable import MessagePackKit

class MessagePackKitBigPayloadTests: XCTestCase {
    
    var encoder: MessagePackEncoder!
    var decoder: MessagePackDecoder!
    
    override func setUp() {
        self.encoder = MessagePackEncoder()
        self.decoder = MessagePackDecoder()
    }
    
    func testPayload() {
        let payload = Payload(randomNumbers: (0...100000).map { $0 }, text: "Stuff")
        let data = try! MessagePackEncoder().encode(payload)
        let decodedPayload = try! MessagePackDecoder().decode(Payload.self, from: data)
        XCTAssertEqual("Stuff", decodedPayload.text)
    }
    
    static var allTests = [
        ("testPayload", testPayload)
    ]
}

fileprivate struct Payload: Codable {
    let randomNumbers: [Int]
    let text: String
}
