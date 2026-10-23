import Foundation

// MARK: - Models

/// Pure game rules. No network, account, location, or UI framework is required.
public struct MouthPlayer: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum MouthCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All packs"
    case everyday = "Everyday"
    case afterHours = "After hours"
    case food = "Food fight"
    case sideways = "Sideways"

    public var id: String { rawValue }
}

public struct MouthWordPair: Hashable, Codable, Sendable, Identifiable {
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

public enum MouthRole: String, Codable, Sendable {
    case regular
    case oddmouth
    case blank
}

public enum MouthStage: String, Codable, Sendable, Equatable {
    case handoff
    case clues
    case nominating
    case interrogation
    case voting
    case results
}

/// Everyone must interpret the same unusual instruction while hiding what they know.
public enum MouthPressure: String, CaseIterable, Codable, Sendable {
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

/// The hot-seat player answers one concrete follow-up before everybody votes again.
/// Each challenge is independent of the word pair, so the defense cannot leak a card.
public enum MouthChallenge: String, CaseIterable, Codable, Sendable {
    case giveAnExample
    case explainTheClue
    case oppositeDay
    case oneSentence
    case oddlyPersonal
    case drawTheLine
    case ordinaryTuesday
    case showYourWork
    case worstPossible
    case nowConvinceUs
    case justAFeeling
    case noBacktracking

    public var headline: String {
        switch self {
        case .giveAnExample: "ONE EXAMPLE"
        case .explainTheClue: "EXPLAIN YOURSELF"
        case .oppositeDay: "OPPOSITE DAY"
        case .oneSentence: "ONE SENTENCE"
        case .oddlyPersonal: "MAKE IT PERSONAL"
        case .drawTheLine: "DRAW THE LINE"
        case .ordinaryTuesday: "JUST A TUESDAY"
        case .showYourWork: "SHOW YOUR WORK"
        case .worstPossible: "WORST CASE"
        case .nowConvinceUs: "CONVINCE THE ROOM"
        case .justAFeeling: "GUT FEELING"
        case .noBacktracking: "NO TAKEBACKS"
        }
    }

    public var instruction: String {
        switch self {
        case .giveAnExample: "Give one specific example that fits your original clue."
        case .explainTheClue: "Explain the link between your clue and your secret word."
        case .oppositeDay: "Describe what your word definitely isn't."
        case .oneSentence: "You get one sentence. Make it count."
        case .oddlyPersonal: "Turn your clue into a very personal story."
        case .drawTheLine: "Explain what people usually confuse your word with."
        case .ordinaryTuesday: "Put your word into the most ordinary day imaginable."
        case .showYourWork: "Walk us through why you chose that exact clue."
        case .worstPossible: "Describe the worst possible version of your word."
        case .nowConvinceUs: "You've been nominated. Tell us why we are wrong."
        case .justAFeeling: "Explain your word using only a mood or feeling."
        case .noBacktracking: "Repeat your clue, then add one detail. No changing it."
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

public struct MouthRound: Codable, Sendable {
    public let wordPair: MouthWordPair
    public let pressure: MouthPressure
    public let roles: [UUID: MouthRole]
    public let clueOrder: [UUID]
    public let crossExamination: Bool
    public let challenge: MouthChallenge
    public private(set) var stage: MouthStage = .handoff
    public private(set) var revealIndex: Int = 0
    public private(set) var clueIndex: Int = 0
    public private(set) var nominations: [UUID: UUID] = [:]
    public private(set) var nomineeID: UUID?
    public private(set) var nominationWasTie = false
    public private(set) var votes: [UUID: UUID] = [:]
    public private(set) var eliminatedID: UUID?
    public private(set) var isTie = false

    public func role(for playerID: UUID) -> MouthRole? {
        roles[playerID]
    }

    public func privateWord(for playerID: UUID) -> String? {
        guard let role = roles[playerID] else { return nil }
        switch role {
        case .regular: return wordPair.common
        case .oddmouth: return wordPair.alternate
        case .blank: return nil
        }
    }

    public func voteCount(for playerID: UUID) -> Int {
        votes.values.filter { $0 == playerID }.count
    }

    public func nominationCount(for playerID: UUID) -> Int {
        nominations.values.filter { $0 == playerID }.count
    }

    public var changedTheirMindCount: Int {
        votes.filter { nominations[$0.key] != nil && nominations[$0.key] != $0.value }.count
    }

    fileprivate init(pair: MouthWordPair, pressure: MouthPressure,
                     roles: [UUID: MouthRole], clueOrder: [UUID],
                     crossExamination: Bool, challenge: MouthChallenge) {
        self.wordPair = pair
        self.pressure = pressure
        self.roles = roles
        self.clueOrder = clueOrder
        self.crossExamination = crossExamination
        self.challenge = challenge
    }

    fileprivate mutating func nextReveal(totalPlayers: Int) {
        revealIndex += 1
        if revealIndex >= totalPlayers { stage = .clues }
    }

    fileprivate mutating func nextClue() {
        clueIndex += 1
        if clueIndex >= clueOrder.count {
            stage = crossExamination ? .nominating : .voting
        }
    }

    fileprivate mutating func recordNomination(from voter: UUID, for target: UUID, totalPlayers: Int) {
        nominations[voter] = target
        guard nominations.count == totalPlayers else { return }
        let tallies = Dictionary(grouping: nominations.values, by: { $0 }).mapValues(\.count)
        let highest = tallies.values.max() ?? 0
        let leaders = Set(tallies.filter { $0.value == highest }.map(\.key))
        // Rotation order makes simultaneous nominations reproducible and fair over rounds.
        nomineeID = clueOrder.first { leaders.contains($0) }
        nominationWasTie = leaders.count > 1
        stage = .interrogation
    }

    fileprivate mutating func finishInterrogation() {
        stage = .voting
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
public struct MouthGame: Codable, Sendable {
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

    public mutating func startRound(
        category: MouthCategory,
        includeBlank: Bool = false,
        crossExamination: Bool = false,
        customPairs: [MouthWordPair]? = nil
    ) throws {
        var generator = SystemRandomNumberGenerator()
        try startRound(category: category, includeBlank: includeBlank,
                       crossExamination: crossExamination, customPairs: customPairs,
                       using: &generator)
    }

    /// Inject the RNG in tests for reproducible secret assignments.
    public mutating func startRound<R: RandomNumberGenerator>(
        category: MouthCategory,
        includeBlank: Bool,
        crossExamination: Bool = false,
        customPairs: [MouthWordPair]? = nil,
        using generator: inout R
    ) throws {
        if let round, round.stage != .results { throw MouthGameError.unfinishedRound }
        let candidates = (customPairs ?? MouthDeck.entries(for: category))
            .filter { $0.id != previousPairID }
        guard let pair = candidates.randomElement(using: &generator) else {
            throw MouthGameError.emptyDeck
        }
        guard let pressure = MouthPressure.allCases.randomElement(using: &generator),
              let challenge = MouthChallenge.allCases.randomElement(using: &generator) else {
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
        round = MouthRound(pair: pair, pressure: pressure, roles: roles,
                           clueOrder: clueOrder, crossExamination: crossExamination,
                           challenge: challenge)
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

    /// The first, private ballot chooses who must defend. It never affects scoring.
    public mutating func nominate(from voter: UUID, for target: UUID) throws {
        guard var active = round, active.stage == .nominating else {
            throw MouthGameError.wrongStage
        }
        guard voter != target,
              players.contains(where: { $0.id == voter }),
              players.contains(where: { $0.id == target }),
              active.nominations[voter] == nil else {
            throw MouthGameError.invalidVote
        }
        active.recordNomination(from: voter, for: target, totalPlayers: players.count)
        round = active
    }

    @discardableResult
    public mutating func finishInterrogation() -> Bool {
        guard var active = round, active.stage == .interrogation,
              active.nomineeID != nil else { return false }
        active.finishInterrogation()
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
