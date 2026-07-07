import Foundation

public enum ProfileDocumentCodec {
    public static func encode(_ profiles: [TouchBarProfile]) throws -> Data {
        try JSONEncoder.touchDeck.encode(profiles)
    }

    public static func decode(_ data: Data) throws -> [TouchBarProfile] {
        try JSONDecoder.touchDeck.decode([TouchBarProfile].self, from: data)
    }
}

extension JSONDecoder {
    static var touchDeck: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }
}

extension JSONEncoder {
    static var touchDeck: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }
}
