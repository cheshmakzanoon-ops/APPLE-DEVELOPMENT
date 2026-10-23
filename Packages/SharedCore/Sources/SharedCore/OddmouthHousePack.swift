import Foundation

/// Player-authored material. It never leaves the device, and it needs no account.
public struct MouthHousePair: Codable, Hashable, Sendable {
    public let common: String
    public let alternate: String

    public init(common: String, alternate: String) {
        self.common = common
        self.alternate = alternate
    }
}

public enum MouthHouseError: Error, Equatable, LocalizedError {
    case invalidName
    case invalidLine(Int)
    case identicalWords(Int)
    case duplicatePair(Int)
    case insufficientPairs
    case tooManyPairs

    public var errorDescription: String? {
        switch self {
        case .invalidName:
            "Name your deck using 2–36 characters."
        case .invalidLine(let number):
            "Line \(number) needs two words or phrases separated by | (40 characters max each)."
        case .identicalWords(let number):
            "Line \(number) needs two different words."
        case .duplicatePair(let number):
            "Line \(number) repeats a word pair."
        case .insufficientPairs:
            "A house deck needs at least 3 pairs. Add a few more."
        case .tooManyPairs:
            "A house deck can hold up to 120 pairs."
        }
    }
}

public struct MouthHousePack: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let pairs: [MouthHousePair]

    /// The editor accepts one "common | alternate" pair per line. Parsing is atomic:
    /// invalid content is never persisted and line numbers match the pasted text.
    public init(id: UUID = UUID(), name: String, source: String) throws {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...36).contains(title.count) else { throw MouthHouseError.invalidName }
        var parsed: [MouthHousePair] = []
        var keys: Set<String> = []
        for (index, raw) in source.components(separatedBy: .newlines).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            let chunks = line.components(separatedBy: "|")
            guard chunks.count == 2 else { throw MouthHouseError.invalidLine(index + 1) }
            let common = chunks[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let alternate = chunks[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard (1...40).contains(common.count), (1...40).contains(alternate.count),
                  !common.contains(where: \.isNewline),
                  !alternate.contains(where: \.isNewline) else {
                throw MouthHouseError.invalidLine(index + 1)
            }
            guard common.compare(alternate, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame else {
                throw MouthHouseError.identicalWords(index + 1)
            }
            let key = [common.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil),
                       alternate.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)]
                .sorted().joined(separator: "|")
            guard keys.insert(key).inserted else { throw MouthHouseError.duplicatePair(index + 1) }
            parsed.append(MouthHousePair(common: common, alternate: alternate))
            guard parsed.count <= 120 else { throw MouthHouseError.tooManyPairs }
        }
        guard parsed.count >= 3 else { throw MouthHouseError.insufficientPairs }
        self.id = id
        self.name = title
        self.pairs = parsed
    }

    public var editorText: String {
        pairs.map { "\($0.common) | \($0.alternate)" }.joined(separator: "\n")
    }

    public var gamePairs: [MouthWordPair] {
        pairs.map { MouthWordPair($0.common, $0.alternate, category: .all) }
    }
}

/// Deliberately simple local storage: no sync, cloud backend, identifiers, or telemetry.
/// The app never persists names or cards in this library.
public enum MouthHouseLibrary {
    private static let key = "oddmouth.housepacks.v1"

    public static func load(from defaults: UserDefaults = .standard) -> [MouthHousePack] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([MouthHousePack].self, from: data)) ?? []
    }

    public static func save(_ packs: [MouthHousePack], to defaults: UserDefaults = .standard) throws {
        let data = try JSONEncoder().encode(packs)
        defaults.set(data, forKey: key)
    }
}
