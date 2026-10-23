import SwiftUI
import Combine
import SharedCore

/// Project 01 — one-phone, offline party game. All decisions stay on-device.
struct OddmouthRootView: View {
    @State private var names = ["", "", "", ""]
    @State private var category: MouthCategory = .all
    @State private var includeBlank = false
    @State private var game: MouthGame?
    @State private var isWordShowing = false
    @State private var didPeek = false
    @State private var selectedVote: UUID?
    @State private var secondsRemaining = 90
    @State private var errorMessage: String?

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .center) {
                    MouthWordmark()
                    Spacer()
                    if let game {
                        MouthTag(text: "ROUND \(game.roundNumber)", fill: MouthColors.blue)
                    } else {
                        MouthTag(text: "ONE PHONE / ALL FRIENDS")
                    }
                }

                activeScreen
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 670)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MouthColors.paper.ignoresSafeArea())
        .foregroundStyle(MouthColors.ink)
        .tint(MouthColors.ink)
        .onReceive(clock) { _ in
            if game?.round?.stage == .clues && secondsRemaining > 0 {
                secondsRemaining -= 1
            }
        }
        .alert(
            "Hold up.",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        if let round = game?.round {
            switch round.stage {
            case .handoff: handoffScreen(round)
            case .clues: clueScreen(round)
            case .voting: votingScreen(round)
            case .results: resultScreen(round)
            }
        } else {
            setupScreen
        }
    }

    // MARK: - Setup

    private var setupScreen: some View {
        VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "THE TABLE IS SET",
                title: "Someone has the wrong word.",
                subtitle: "Talk your way through the room. Catch the strange clue. Try not to get caught giving it."
            )

            MouthPanel(color: MouthColors.lime) {
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 27))
                    VStack(alignment: .leading, spacing: 7) {
                        Text("SAME ROOM. DIFFERENT REALITY.")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text("Most players see the same word. One gets a nearby word. Nobody knows who's bluffing. Each round adds a ridiculous clue constraint.")
                            .font(.system(size: 14, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            MouthPanel {
                HStack {
                    Text("WHO'S PLAYING?")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Spacer()
                    MouthTag(text: "\(names.count) players", fill: MouthColors.paper)
                }
                VStack(spacing: 10) {
                    ForEach(names.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(MouthColors.muted)
                                .frame(width: 32, alignment: .leading)
                            TextField("Player \(index + 1)", text: $names[index])
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .accessibilityLabel("Player \(index + 1) name")
                            if names.count > 3 {
                                Button {
                                    names.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(MouthColors.red)
                                }
                                .accessibilityLabel("Remove player \(index + 1)")
                            }
                        }
                        .padding(13)
                        .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                if names.count < 12 {
                    Button {
                        names.append("")
                    } label: {
                        Label("ADD SOMEONE", systemImage: "plus")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .padding(.top, 3)
                }
            }

            MouthPanel {
                Text("SET THE MOOD")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Menu {
                    ForEach(MouthCategory.allCases) { pack in
                        Button(pack.rawValue) { category = pack }
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text(category.rawValue)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(15)
                    .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                }

                Toggle(isOn: $includeBlank) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ADD A BLANK CARD")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("One extra person gets no word at all.")
                            .font(.system(size: 12))
                            .foregroundStyle(MouthColors.muted)
                    }
                }
                .disabled(names.count < 5)
                .tint(MouthColors.red)

                if names.count < 5 {
                    Text("Blank cards unlock with five or more players.")
                        .font(.caption)
                        .foregroundStyle(MouthColors.muted)
                }
            }

            Button(action: startGame) {
                Label("DEAL THE WORDS", systemImage: "arrow.right")
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.red))

            Text("Offline from the first card. No account, chat, tracking, or internet connection.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MouthColors.muted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Private reveal

    private func handoffScreen(_ round: MouthRound) -> some View {
        let person = game!.players[round.revealIndex]
        let privateWord = round.privateWord(for: person.id)

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "PRIVATE CARD \(round.revealIndex + 1) OF \(game!.players.count)",
                title: "Phone to \(person.name).",
                subtitle: "Everybody else: eyes away. This card belongs to one person."
            )

            MouthPanel(color: isWordShowing ? MouthColors.lime : MouthColors.pale) {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: isWordShowing ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 38, weight: .bold))
                    Text(isWordShowing ? "YOUR SECRET CARD" : "NO PEEKING")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(2)
                    if isWordShowing {
                        Text(privateWord ?? "NO WORD")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityAddTraits(.isStaticText)
                        Text(privateWord == nil
                             ? "You're flying blind. Listen closely and blend in."
                             : "Keep this to yourself. Don't say it out loud.")
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Only \(person.name) should reveal what's underneath.")
                            .font(.system(size: 15, weight: .semibold))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 236)
            }

            Button {
                isWordShowing.toggle()
                didPeek = true
            } label: {
                Label(
                    isWordShowing ? "HIDE MY WORD" : "REVEAL MY WORD",
                    systemImage: isWordShowing ? "eye.slash" : "eye"
                )
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))

            if didPeek {
                Button {
                    advanceReveal()
                } label: {
                    Label("PASS THE PHONE", systemImage: "arrow.right")
                }
                .buttonStyle(MouthButtonStyle(fill: MouthColors.pale))
                .disabled(isWordShowing)
                .opacity(isWordShowing ? 0.45 : 1)
            }
        }
    }

    // MARK: - Spoken clues

    private func clueScreen(_ round: MouthRound) -> some View {
        let person = game!.player(for: round.clueOrder[round.clueIndex])!

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "ROUND \(game!.roundNumber) / SPEAK UP",
                title: "Every clue leaves a fingerprint.",
                subtitle: "Go around the table. Don't say your word. Listen for someone who's almost right."
            )

            MouthPanel(color: MouthColors.red) {
                MouthTag(text: "THIS ROUND'S PRESSURE", fill: MouthColors.paper)
                Text(round.pressure.headline)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(-1)
                Text(round.pressure.instruction)
                    .font(.system(size: 17, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            MouthPanel {
                Text("THE FLOOR IS YOURS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(MouthColors.muted)
                Text(person.name)
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .tracking(-1.5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                HStack {
                    Label(timeLabel, systemImage: "timer")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundStyle(secondsRemaining == 0 ? MouthColors.red : MouthColors.ink)
                    Spacer()
                    Text("\(round.clueIndex + 1) / \(round.clueOrder.count)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(round.clueOrder.indices, id: \.self) { index in
                    let id = round.clueOrder[index]
                    HStack(spacing: 13) {
                        Text("\(index + 1).")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .frame(width: 28)
                        Text(game!.player(for: id)?.name ?? "Player")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        if index < round.clueIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MouthColors.muted)
                        } else if index == round.clueIndex {
                            MouthTag(text: "SPEAKING", fill: MouthColors.lime)
                        }
                    }
                    .padding(10)
                    .background(
                        index == round.clueIndex ? MouthColors.pale : .clear,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }

            Button(action: advanceClue) {
                Label(
                    round.clueIndex + 1 == round.clueOrder.count ? "START PRIVATE VOTING" : "NEXT SPEAKER",
                    systemImage: "arrow.right"
                )
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))
        }
    }

    // MARK: - Hidden ballots

    private func votingScreen(_ round: MouthRound) -> some View {
        let voter = game!.players[round.votes.count]
        let candidates = game!.players.filter { $0.id != voter.id }

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "SECRET BALLOT \(round.votes.count + 1) OF \(game!.players.count)",
                title: "\(voter.name), who's off?",
                subtitle: "Hand the phone to this voter. Choose the person with the strangest clue. Your choice stays hidden."
            )

            MouthPanel {
                Text("CAST ONE VOTE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                ForEach(candidates) { candidate in
                    Button {
                        selectedVote = candidate.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedVote == candidate.id
                                  ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(MouthColors.red)
                                .font(.title3)
                            Text(candidate.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(MouthColors.ink)
                            Spacer()
                        }
                        .padding(15)
                        .background(
                            selectedVote == candidate.id ? MouthColors.lime : MouthColors.paper,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedVote == candidate.id ? [.isSelected] : [])
                }
            }

            Button(action: lockVote) {
                Label("LOCK MY VOTE", systemImage: "lock.fill")
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.red))
            .disabled(selectedVote == nil)
            .opacity(selectedVote == nil ? 0.45 : 1)

            Text("No player can vote for themselves. Votes aren't displayed until everyone is done.")
                .font(.system(size: 13))
                .foregroundStyle(MouthColors.muted)
        }
    }

    // MARK: - Round outcome

    private func resultScreen(_ round: MouthRound) -> some View {
        let eliminatedName = round.eliminatedID.flatMap { game!.player(for: $0)?.name }

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "THE ROOM HAS SPOKEN",
                title: round.isTie ? "Nobody agrees." : "\(eliminatedName ?? "Someone") got the vote.",
                subtitle: round.isTie
                    ? "A dead heat. Nobody was eliminated."
                    : "Time to turn all the cards face up."
            )

            MouthPanel(color: MouthColors.lime) {
                Text("THE TWO WORDS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                HStack(alignment: .top, spacing: 15) {
                    wordResult(label: "MOST PLAYERS", word: round.wordPair.common)
                    Rectangle()
                        .fill(MouthColors.ink)
                        .frame(width: 1)
                    wordResult(label: "ODDMOUTH", word: round.wordPair.alternate)
                }
                .frame(maxWidth: .infinity)
            }

            MouthPanel {
                Text("EVERYONE'S CARD")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                ForEach(game!.players) { player in
                    HStack {
                        Text(player.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                        Text(roleLabel(round.role(for: player.id)))
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                round.role(for: player.id) == .regular
                                    ? MouthColors.muted : MouthColors.red
                            )
                    }
                    Divider().overlay(MouthColors.ink.opacity(0.1))
                }
            }

            MouthPanel(color: MouthColors.paper) {
                Text("THE SCOREBOARD")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                ForEach(game!.standings.indices, id: \.self) { index in
                    let person = game!.standings[index]
                    HStack {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(MouthColors.muted)
                            .frame(width: 30, alignment: .leading)
                        Text(person.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                        Text("\(game!.scores[person.id, default: 0])")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                    }
                }
                Text("2 points per correct suspicious vote. 3 points for each uncaught oddmouth or blank card.")
                    .font(.system(size: 12))
                    .foregroundStyle(MouthColors.muted)
            }

            Button(action: nextRound) {
                Label("ANOTHER ROUND", systemImage: "arrow.clockwise")
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.red))

            Button {
                game = nil
                isWordShowing = false
                didPeek = false
                selectedVote = nil
            } label: {
                Text("BACK TO THE TABLE SETUP")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }

    private func wordResult(label: String, word: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .monospaced))
            Text(word)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func roleLabel(_ role: MouthRole?) -> String {
        switch role {
        case .regular: "COMMON WORD"
        case .oddmouth: "ODDMOUTH"
        case .blank: "BLANK CARD"
        case .none: "UNKNOWN"
        }
    }

    private var timeLabel: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }

    // MARK: - Session commands

    private func startGame() {
        let players = names.enumerated().map { index, raw -> MouthPlayer in
            let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return MouthPlayer(name: cleaned.isEmpty ? "Player \(index + 1)" : cleaned)
        }
        do {
            var newGame = try MouthGame(players: players)
            try newGame.startRound(
                category: category,
                includeBlank: includeBlank && players.count >= 5
            )
            game = newGame
            isWordShowing = false
            didPeek = false
            selectedVote = nil
            secondsRemaining = 90
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func advanceReveal() {
        guard var session = game else { return }
        guard session.advanceReveal() else { return }
        game = session
        isWordShowing = false
        didPeek = false
        if session.round?.stage == .clues { secondsRemaining = 90 }
    }

    private func advanceClue() {
        guard var session = game else { return }
        guard session.advanceClue() else { return }
        game = session
    }

    private func lockVote() {
        guard var session = game,
              let round = session.round,
              round.stage == .voting,
              let target = selectedVote else { return }
        let voter = session.players[round.votes.count]
        do {
            try session.castVote(from: voter.id, for: target)
            game = session
            selectedVote = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nextRound() {
        guard var session = game else { return }
        do {
            try session.startRound(
                category: category,
                includeBlank: includeBlank && session.players.count >= 5
            )
            game = session
            secondsRemaining = 90
            isWordShowing = false
            didPeek = false
            selectedVote = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
