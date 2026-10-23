import Foundation

/// Portable, versioned deck text. Entirely client-side: no URL, service, token, or account.
/// The exported text is safe to paste into Messages, AirDrop, email, or notes.
public enum MouthHouseTransfer {
    private static let prefix = "ODD1:"
    private static let maxCodeLength = 64_000

    private struct Payload: Codable {
        let name: String
        let pairs: [MouthHousePair]
    }

    public static func export(_ deck: MouthHousePack) throws -> String {
        let payload = Payload(name: deck.name, pairs: deck.pairs)
        let data = try JSONEncoder().encode(payload)
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return prefix + encoded
    }

    /// Imported packs deliberately receive a new UUID. The text is treated as
    /// untrusted input and revalidated by the same house-deck editor rules.
    public static func importCode(_ text: String) throws -> MouthHousePack {
        let code = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.utf8.count <= maxCodeLength else { throw MouthTransferError.tooLong }
        guard code.hasPrefix(prefix) else { throw MouthTransferError.unsupportedFormat }
        let encoded = String(code.dropFirst(prefix.count))
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingCount = (4 - encoded.utf8.count % 4) % 4
        let padded = encoded + String(repeating: "=", count: paddingCount)
        guard let data = Data(base64Encoded: padded),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw MouthTransferError.damagedCode
        }
        let lines = payload.pairs.map { "\($0.common) | \($0.alternate)" }
            .joined(separator: "\n")
        return try MouthHousePack(name: payload.name, source: lines)
    }
}

public enum MouthTransferError: Error, LocalizedError, Equatable {
    case unsupportedFormat
    case damagedCode
    case tooLong

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat: "This doesn't look like an Oddmouth deck code."
        case .damagedCode: "The deck code is incomplete or damaged. Ask your friend to share it again."
        case .tooLong: "The pasted deck is too large to import."
        }
    }
}
