import Foundation
import SharedCore

/// An interrupted party can be resumed without an account or backend.
/// The entire state is private to this app's on-device container.
struct MouthSessionSnapshot: Codable {
    let game: MouthGame
    let category: MouthCategory
    let includeBlank: Bool
    let crossExamination: Bool
    let clueDuration: Int
    let secondsRemaining: Int
    let selectedHouseID: UUID?
}

enum MouthSessionStore {
    private static let key = "oddmouth.session.v1"

    static func load() -> MouthSessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(MouthSessionSnapshot.self, from: data)
    }

    static func save(_ snapshot: MouthSessionSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
