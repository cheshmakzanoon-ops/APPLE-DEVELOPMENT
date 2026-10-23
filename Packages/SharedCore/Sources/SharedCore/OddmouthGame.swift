import Foundation

// MARK: - Models

/// Pure game rules. No network, account, location, or UI framework is required.
public struct MouthPlayer: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum MouthCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All packs"
    case everyday = "Everyday"
    case afterHours = "After hours"
    case food = "Food fight"
    case sideways = "Sideways"

    public var id: String { rawValue }
}

public struct MouthWordPair: Hashable, Sendable, Identifiable {
    public let common: String
    public let alternate: String
    public let category: MouthCategory

    public var id: String { "\(common.lowercased())|\(alternate.lowercased())" }

    public init(_ common: String, _ alternate: String, category: MouthCategory) {
        self.common = common
        self.alternate = alternate
        self.category = category
    }
}

public enum MouthRole: String, Sendable {
    case regular
    case oddmouth
    case blank
}

public enum MouthStage: Sendable, Equatable {
    case handoff
    case clues
    case voting
    case results
}

/// Everyone must interpret the same unusual instruction while hiding what they know.
public enum MouthPressure: String, CaseIterable, Sendable {
    case threeWords
    case aMemory
    case aQuestion
    case badAdvertisement
    case theSound
    case suspiciouslySpecific
    case noNames
    case bigDrama
    case tellAChild

    public var headline: String {
        switch self {
        case .threeWords: "THREE WORDS"
        case .aMemory: "FLASHBACK"
        case .aQuestion: "QUESTION MARK"
        case .badAdvertisement: "SELL IT BADLY"
        case .theSound: "SOUND CHECK"
        case .suspiciouslySpecific: "ODDLY SPECIFIC"
        case .noNames: "NO NAMING NAMES"
        case .bigDrama: "FULL DRAMA"
        case .tellAChild: "SMALL TALK"
        }
    }

    public var instruction: String {
        switch self {
        case .threeWords: "Your clue must be exactly three words."
        case .aMemory: "Give a clue as if recalling a real memory."
        case .aQuestion: "Your entire clue must be a question."
        case .badAdvertisement: "Pitch your word like a terrible commercial."
        case .theSound: "Describe a sound connected to your word."
        case .suspiciouslySpecific: "Offer an unreasonably specific detail."
        case .noNames: "Don't use names of people, brands, or places."
        case .bigDrama: "Speak as though everything depends on your clue."
        case .tellAChild: "Explain it as though speaking to a five-year-old."
        }
    }
}

public enum MouthGameError: Error, Equatable, LocalizedError {
    case playerCount
    case duplicateNames
    case emptyDeck
    case unfinishedRound
    case wrongStage
    case invalidVote

    public var errorDescription: String? {
        switch self {
        case .playerCount: "You need between 3 and 12 players."
        case .duplicateNames: "Every player needs a different name."
        case .emptyDeck: "There are no cards in this pack."
        case .unfinishedRound: "Finish the current round before dealing again."
        case .wrongStage: "That action isn't available yet."
        case .invalidVote: "Pick another player, and vote only once."
        }
    }
}

public struct MouthRound: Sendable {
    public let wordPair: MouthWordPair
    public let pressure: MouthPressure
    public let roles: [UUID: MouthRole]
    public let clueOrder: [UUID]
    public private(set) var stage: MouthStage = .handoff
    public private(set) var revealIndex: Int = 0
    public private(set) var clueIndex: Int = 0
    public private(set) var votes: [UUID: UUID] = [:]
    public private(set) var eliminatedID: UUID?
    public private(set) var isTie = false

    public func role(for playerID: UUID) -> MouthRole? {
        roles[playerID]
    }

    public func privateWord(for playerID: UUID) -> String? {
        guard let role = roles[playerID] else { return nil }
        switch role {
        case .regular: wordPair.common
        case .oddmouth: wordPair.alternate
        case .blank: nil
        }
    }

    public func voteCount(for playerID: UUID) -> Int {
        votes.values.filter { $0 == playerID }.count
    }

    fileprivate init(pair: MouthWordPair, pressure: MouthPressure,
                     roles: [UUID: MouthRole], clueOrder: [UUID]) {
        self.wordPair = pair
        self.pressure = pressure
        self.roles = roles
        self.clueOrder = clueOrder
    }

    fileprivate mutating func nextReveal(totalPlayers: Int) {
        revealIndex += 1
        if revealIndex >= totalPlayers { stage = .clues }
    }

    fileprivate mutating func nextClue() {
        clueIndex += 1
        if clueIndex >= clueOrder.count { stage = .voting }
    }

    fileprivate mutating func recordVote(from voter: UUID, for target: UUID) {
        votes[voter] = target
    }

    fileprivate mutating func resolve() {
        let tallies = Dictionary(grouping: votes.values, by: { $0 }).mapValues(\.count)
        let highest = tallies.values.max() ?? 0
        let leaders = tallies.filter { $0.value == highest }
        isTie = leaders.count != 1
        eliminatedID = isTie ? nil : leaders.first?.key
        stage = .results
    }
}

/// A local, pass-the-phone session. Only the app view ever reveals private words.
public struct MouthGame: Sendable {
    public let players: [MouthPlayer]
    public private(set) var scores: [UUID: Int]
    public private(set) var round: MouthRound?
    public private(set) var roundNumber = 0
    private var previousPairID: String?

    public init(players: [MouthPlayer]) throws {
        guard (3...12).contains(players.count) else { throw MouthGameError.playerCount }
        let names = players.map { $0.name.lowercased() }
        guard !names.contains(where: { $0.isEmpty }),
              Set(names).count == players.count,
              Set(players.map(\.id)).count == players.count else {
            throw MouthGameError.duplicateNames
        }
        self.players = players
        self.scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    }

    public var standings: [MouthPlayer] {
        players.sorted {
            let left = scores[$0.id, default: 0]
            let right = scores[$1.id, default: 0]
            return left == right ? $0.name < $1.name : left > right
        }
    }

    public func player(for id: UUID) -> MouthPlayer? {
        players.first { $0.id == id }
    }

    public mutating func startRound(category: MouthCategory, includeBlank: Bool = false) throws {
        var generator = SystemRandomNumberGenerator()
        try startRound(category: category, includeBlank: includeBlank, using: &generator)
    }

    /// Inject the RNG in tests for reproducible secret assignments.
    public mutating func startRound<R: RandomNumberGenerator>(
        category: MouthCategory,
        includeBlank: Bool,
        using generator: inout R
    ) throws {
        if let round, round.stage != .results { throw MouthGameError.unfinishedRound }
        let candidates = MouthDeck.entries(for: category).filter { $0.id != previousPairID }
        guard let pair = candidates.randomElement(using: &generator) else {
            throw MouthGameError.emptyDeck
        }
        guard let pressure = MouthPressure.allCases.randomElement(using: &generator) else {
            throw MouthGameError.emptyDeck
        }
        let shuffled = players.shuffled(using: &generator)
        var roles = Dictionary(uniqueKeysWithValues: players.map { ($0.id, MouthRole.regular) })
        roles[shuffled[0].id] = .oddmouth
        if includeBlank && players.count >= 5 {
            roles[shuffled[1].id] = .blank
        }

        // Rotate who gives the first clue; preserve a predictable phone hand-off.
        let rotation = roundNumber % players.count
        let clueOrder = Array(players[rotation...].map(\.id))
            + Array(players[..<rotation].map(\.id))
        round = MouthRound(pair: pair, pressure: pressure, roles: roles, clueOrder: clueOrder)
        previousPairID = pair.id
        roundNumber += 1
    }

    @discardableResult
    public mutating func advanceReveal() -> Bool {
        guard var active = round, active.stage == .handoff else { return false }
        active.nextReveal(totalPlayers: players.count)
        round = active
        return true
    }

    @discardableResult
    public mutating func advanceClue() -> Bool {
        guard var active = round, active.stage == .clues else { return false }
        active.nextClue()
        round = active
        return true
    }

    public mutating func castVote(from voter: UUID, for target: UUID) throws {
        guard var active = round, active.stage == .voting else {
            throw MouthGameError.wrongStage
        }
        guard voter != target,
              players.contains(where: { $0.id == voter }),
              players.contains(where: { $0.id == target }),
              active.votes[voter] == nil else {
            throw MouthGameError.invalidVote
        }
        active.recordVote(from: voter, for: target)

        if active.votes.count == players.count {
            active.resolve()
            for (voterID, targetID) in active.votes
            where active.role(for: targetID) != .regular {
                scores[voterID, default: 0] += 2
            }
            for (playerID, role) in active.roles
            where role != .regular && playerID != active.eliminatedID {
                scores[playerID, default: 0] += 3
            }
        }
        round = active
    }
}
