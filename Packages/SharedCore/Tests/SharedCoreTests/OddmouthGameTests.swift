import Foundation
import XCTest
@testable import SharedCore

private struct FixedRandom: RandomNumberGenerator {
    private var value: UInt64 = 0x1248ABCD
    mutating func next() -> UInt64 {
        value &+= 0x9E3779B97F4A7C15
        var x = value
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        return x ^ (x >> 31)
    }
}

final class OddmouthGameTests: XCTestCase {
    private func players(_ count: Int) -> [MouthPlayer] {
        (1...count).map { MouthPlayer(name: "Player \($0)") }
    }

    private func started(_ count: Int = 5, blank: Bool = false) throws -> MouthGame {
        var game = try MouthGame(players: players(count))
        var random = FixedRandom()
        try game.startRound(category: .everyday, includeBlank: blank, using: &random)
        return game
    }

    private func enterVoting(_ game: inout MouthGame) {
        for _ in game.players { XCTAssertTrue(game.advanceReveal()) }
        for _ in game.players { XCTAssertTrue(game.advanceClue()) }
        XCTAssertEqual(game.round?.stage, .voting)
    }

    func testValidatesNamesAndPlayers() throws {
        XCTAssertThrowsError(try MouthGame(players: players(2))) {
            XCTAssertEqual($0 as? MouthGameError, .playerCount)
        }
        XCTAssertThrowsError(try MouthGame(players: players(13))) {
            XCTAssertEqual($0 as? MouthGameError, .playerCount)
        }
        XCTAssertThrowsError(try MouthGame(players: [
            MouthPlayer(name: "  Amy "), MouthPlayer(name: "amy"),
            MouthPlayer(name: "Jay")
        ])) {
            XCTAssertEqual($0 as? MouthGameError, .duplicateNames)
        }
        XCTAssertNoThrow(try MouthGame(players: players(12)))
    }

    func testExactlyOneOddmouthAndOptionalBlank() throws {
        let withoutBlank = try started()
        XCTAssertEqual(withoutBlank.round?.roles.values.filter { $0 == .oddmouth }.count, 1)
        XCTAssertEqual(withoutBlank.round?.roles.values.filter { $0 == .blank }.count, 0)
        let withBlank = try started(blank: true)
        XCTAssertEqual(withBlank.round?.roles.values.filter { $0 == .oddmouth }.count, 1)
        XCTAssertEqual(withBlank.round?.roles.values.filter { $0 == .blank }.count, 1)
        XCTAssertEqual(withBlank.round?.roles.count, 5)
    }

    func testPrivateWordsMatchRoles() throws {
        let game = try started(blank: true)
        let round = try XCTUnwrap(game.round)
        for person in game.players {
            switch round.role(for: person.id) {
            case .regular:
                XCTAssertEqual(round.privateWord(for: person.id), round.wordPair.common)
            case .oddmouth:
                XCTAssertEqual(round.privateWord(for: person.id), round.wordPair.alternate)
            case .blank:
                XCTAssertNil(round.privateWord(for: person.id))
            case .none:
                XCTFail("Missing private role")
            }
        }
    }

    func testEveryPlayerSeesTheirWordBeforeClueAndVoteStages() throws {
        var game = try started(4)
        XCTAssertEqual(game.round?.stage, .handoff)
        for _ in 0..<3 {
            XCTAssertTrue(game.advanceReveal())
            XCTAssertEqual(game.round?.stage, .handoff)
        }
        XCTAssertTrue(game.advanceReveal())
        XCTAssertEqual(game.round?.stage, .clues)
        XCTAssertFalse(game.advanceReveal())
        for _ in 0..<4 { XCTAssertTrue(game.advanceClue()) }
        XCTAssertEqual(game.round?.stage, .voting)
    }

    func testCannotCastSelfVoteOrVoteTwice() throws {
        var game = try started(4)
        let ids = game.players.map(\.id)
        XCTAssertThrowsError(try game.castVote(from: ids[0], for: ids[1]))
        enterVoting(&game)
        XCTAssertThrowsError(try game.castVote(from: ids[0], for: ids[0])) {
            XCTAssertEqual($0 as? MouthGameError, .invalidVote)
        }
        try game.castVote(from: ids[0], for: ids[1])
        XCTAssertThrowsError(try game.castVote(from: ids[0], for: ids[2])) {
            XCTAssertEqual($0 as? MouthGameError, .invalidVote)
        }
    }

    func testCorrectMajorityScoresVotersAndCatchesOddmouth() throws {
        var game = try started(4)
        enterVoting(&game)
        let oddmouthID = try XCTUnwrap(game.round?.roles.first { $0.value == .oddmouth }?.key)
        let innocents = game.players.map(\.id).filter { $0 != oddmouthID }
        for id in innocents { try game.castVote(from: id, for: oddmouthID) }
        try game.castVote(from: oddmouthID, for: innocents[0])
        XCTAssertEqual(game.round?.stage, .results)
        XCTAssertEqual(game.round?.eliminatedID, oddmouthID)
        XCTAssertEqual(game.scores[oddmouthID], 0)
        for id in innocents { XCTAssertEqual(game.scores[id], 2) }
    }

    func testTiedVoteMeansNoEliminationAndOddmouthSurvives() throws {
        var game = try started(4)
        enterVoting(&game)
        let ids = game.players.map(\.id)
        for index in ids.indices {
            try game.castVote(from: ids[index], for: ids[(index + 1) % ids.count])
        }
        XCTAssertEqual(game.round?.stage, .results)
        XCTAssertTrue(game.round?.isTie == true)
        XCTAssertNil(game.round?.eliminatedID)
        let oddmouthID = try XCTUnwrap(game.round?.roles.first { $0.value == .oddmouth }?.key)
        XCTAssertTrue((game.scores[oddmouthID] ?? 0) >= 3)
    }

    func testNextRoundPreservesScoreAndChangesPair() throws {
        var game = try started(3)
        let firstID = try XCTUnwrap(game.round?.wordPair.id)
        enterVoting(&game)
        let ids = game.players.map(\.id)
        for index in ids.indices {
            try game.castVote(from: ids[index], for: ids[(index + 1) % ids.count])
        }
        let previousScores = game.scores
        var generator = FixedRandom()
        try game.startRound(category: .everyday, includeBlank: false, using: &generator)
        XCTAssertNotEqual(game.round?.wordPair.id, firstID)
        XCTAssertEqual(game.roundNumber, 2)
        XCTAssertEqual(game.scores, previousScores)
    }

    func testPackContentHasUniquePairsAndCategories() {
        let cards = MouthDeck.entries(for: .all)
        XCTAssertGreaterThanOrEqual(cards.count, 100)
        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count)
        for category in MouthCategory.allCases where category != .all {
            let pack = MouthDeck.entries(for: category)
            XCTAssertGreaterThanOrEqual(pack.count, 20)
            XCTAssertTrue(pack.allSatisfy { $0.category == category })
        }
    }

    func testStartRequiresFinishedRound() throws {
        var game = try started()
        XCTAssertThrowsError(try game.startRound(category: .all)) {
            XCTAssertEqual($0 as? MouthGameError, .unfinishedRound)
        }
    }
}
