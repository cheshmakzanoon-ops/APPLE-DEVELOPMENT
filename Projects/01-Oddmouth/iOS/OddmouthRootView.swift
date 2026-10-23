import SwiftUI
import Combine
import SharedCore

/// Project 01 — one-phone, offline party game. All decisions stay on-device.
struct OddmouthRootView: View {
    @State private var names = ["", "", "", ""]
    @State private var category: MouthCategory = .all
    @State private var includeBlank = false
    @State private var crossExamination = true
    @State private var clueDuration = 120
    @State private var selectedHouseID: UUID?
    @State private var housePacks = MouthHouseLibrary.load()
    @State private var isEditingDeck = false
    @State private var isImportingDeck = false
    @State private var importDeckCode = ""
    @State private var importErrorMessage: String?
    @State private var editingDeckID: UUID?
    @State private var draftDeckName = ""
    @State private var draftDeckSource = ""
    @State private var deckErrorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var savedSession: MouthSessionSnapshot?
    @State private var hasCheckedResume = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var game: MouthGame?
    @State private var isWordShowing = false
    @State private var didPeek = false
    @State private var selectedVote: UUID?
    @State private var selectedNomination: UUID?
    @State private var isBallotReady = false
    @State private var secondsRemaining = 120
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
            guard scenePhase == .active,
                  (game?.round?.stage == .clues || game?.round?.stage == .interrogation),
                  secondsRemaining > 0 else { return }
            secondsRemaining -= 1
            if secondsRemaining % 10 == 0 { persistSession() }
        }
        .onAppear(perform: checkForSavedSession)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                // Never leave a private role or an unfinished ballot on the app switcher.
                isWordShowing = false
                isBallotReady = false
                selectedVote = nil
                selectedNomination = nil
                persistSession()
            }
        }
        .sheet(isPresented: $isEditingDeck) {
            houseDeckEditor
        }
        .sheet(isPresented: $isImportingDeck) {
            houseDeckImporter
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
            case .nominating: ballotScreen(round, nomination: true)
            case .interrogation: interrogationScreen(round)
            case .voting: ballotScreen(round, nomination: false)
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

            if let savedSession {
                MouthPanel(color: MouthColors.blue) {
                    MouthTag(text: "UNFINISHED BUSINESS", fill: MouthColors.paper)
                    Text("Your last table is still here.")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                    Text("Round \(savedSession.game.roundNumber) • \(savedSession.game.players.count) players. Continue from the exact moment you left.")
                        .font(.system(size: 14, weight: .medium))
                    Button(action: resumeSavedSession) {
                        Label("RESUME THE TABLE", systemImage: "arrow.uturn.forward")
                    }
                    .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))
                    Button("DISCARD THE OLD SESSION") {
                        MouthSessionStore.clear()
                        self.savedSession = nil
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                }
            }

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
                        Button(pack.rawValue) {
                            category = pack
                            selectedHouseID = nil
                        }
                    }
                    if !housePacks.isEmpty {
                        Divider()
                        ForEach(housePacks) { pack in
                            Button("HOUSE / \(pack.name)") { selectedHouseID = pack.id }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text(selectedHousePack.map { "HOUSE / \($0.name)" } ?? category.rawValue)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(15)
                    .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                }

                if let house = selectedHousePack {
                    Text("\(house.pairs.count) pairs written by your table. Stored on this device.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MouthColors.muted)
                }

                HStack {
                    Button {
                        showNewHouseDeck()
                    } label: {
                        Label("MAKE A DECK", systemImage: "square.and.pencil")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    Spacer()
                    Button {
                        importDeckCode = ""
                        isImportingDeck = true
                    } label: {
                        Label("IMPORT CODE", systemImage: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                }
                if let house = selectedHousePack {
                    Button {
                        showEditHouseDeck(house)
                    } label: {
                        Label("EDIT / SHARE \(house.name.uppercased())",
                              systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
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

                Divider()
                Toggle(isOn: $crossExamination) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("THE HOT SEAT")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("Private nominations → one timed defense → a fresh final vote.")
                            .font(.system(size: 12))
                            .foregroundStyle(MouthColors.muted)
                    }
                }
                .tint(MouthColors.red)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CLUE TIMER")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("Shared by everyone giving clues.")
                            .font(.system(size: 12))
                            .foregroundStyle(MouthColors.muted)
                    }
                    Spacer()
                    Menu {
                        ForEach([90, 120, 180, 240], id: \.self) { seconds in
                            Button("\(seconds / 60):\(seconds % 60 == 0 ? "00" : "30")") {
                                clueDuration = seconds
                            }
                        }
                    } label: {
                        MouthTag(text: "\(clueDuration)s", fill: MouthColors.lime)
                    }
                }
            }

            Button(action: startGame) {
                Label("DEAL THE WORDS", systemImage: "arrow.right")
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.red))
            .disabled(savedSession != nil)
            .opacity(savedSession == nil ? 1 : 0.45)

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
                    round.clueIndex + 1 == round.clueOrder.count
                        ? (round.crossExamination ? "START SECRET NOMINATIONS" : "START PRIVATE VOTING")
                        : "NEXT SPEAKER",
                    systemImage: "arrow.right"
                )
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))
        }
    }

    // MARK: - The two private ballots

    private func ballotScreen(_ round: MouthRound, nomination: Bool) -> some View {
        let ballotCount = nomination ? round.nominations.count : round.votes.count
        let voter = game!.players[ballotCount]
        let candidates = game!.players.filter { $0.id != voter.id }
        let selection = nomination ? selectedNomination : selectedVote

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: nomination
                    ? "SECRET NOMINATION \(ballotCount + 1) OF \(game!.players.count)"
                    : "FINAL BALLOT \(ballotCount + 1) OF \(game!.players.count)",
                title: isBallotReady ? "\(voter.name), who's off?" : "Only \(voter.name) should look.",
                subtitle: nomination
                    ? "The first ballot chooses who must defend their clue. Nobody sees individual nominations."
                    : "You've heard the defense. You can change your mind. This vote decides the round."
            )

            if !isBallotReady {
                MouthPanel(color: MouthColors.lime) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 39, weight: .black))
                    Text("PASS THE PHONE")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                    Text("Ready, \(voter.name)?")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text("Everyone else, look away. Your choices will be hidden as soon as you lock them.")
                        .font(.system(size: 15, weight: .medium))
                    Button {
                        isBallotReady = true
                    } label: {
                        Label("I'M \(voter.name.uppercased())", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(MouthButtonStyle(fill: MouthColors.pale))
                }
            } else {
                MouthPanel {
                    Text(nomination ? "WHO'S GOING IN THE HOT SEAT?" : "MAKE YOUR FINAL CALL")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                    ForEach(candidates) { candidate in
                        Button {
                            if nomination {
                                selectedNomination = candidate.id
                            } else {
                                selectedVote = candidate.id
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selection == candidate.id
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
                                selection == candidate.id ? MouthColors.lime : MouthColors.paper,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == candidate.id ? [.isSelected] : [])
                    }
                }

                Button {
                    if nomination { lockNomination() } else { lockVote() }
                } label: {
                    Label(nomination ? "LOCK MY NOMINATION" : "LOCK MY FINAL VOTE",
                          systemImage: "lock.fill")
                }
                .buttonStyle(MouthButtonStyle(fill: MouthColors.red))
                .disabled(selection == nil)
                .opacity(selection == nil ? 0.45 : 1)

                Text("No self-votes. Your selection cannot be changed after locking. Only the totals appear at the end.")
                    .font(.system(size: 13))
                    .foregroundStyle(MouthColors.muted)
            }
        }
    }

    // MARK: - The hot seat

    private func interrogationScreen(_ round: MouthRound) -> some View {
        let name = round.nomineeID.flatMap { game!.player(for: $0)?.name } ?? "Someone"

        return VStack(alignment: .leading, spacing: 22) {
            MouthSectionHeading(
                kicker: "THE HOT SEAT / 30 SECONDS",
                title: "\(name), explain yourself.",
                subtitle: "The room privately picked one person to question. Then everybody gets a completely fresh vote."
            )

            MouthPanel(color: MouthColors.red) {
                MouthTag(text: "THE FOLLOW-UP", fill: MouthColors.paper)
                Text(round.challenge.headline)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(-1)
                Text(round.challenge.instruction)
                    .font(.system(size: 18, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            MouthPanel {
                HStack(spacing: 13) {
                    Image(systemName: "timer")
                        .font(.system(size: 30, weight: .bold))
                    Text(timeLabel)
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .foregroundStyle(secondsRemaining == 0 ? MouthColors.red : MouthColors.ink)
                    Spacer()
                    MouthTag(text: "DEFEND", fill: MouthColors.lime)
                }
                if round.nominationWasTie {
                    Text("The nominations were tied. This round's speaking order broke the tie.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MouthColors.muted)
                }
                Text("Give the speaker their moment. No names or vote totals are revealed until the end.")
                    .font(.system(size: 14, weight: .medium))
            }

            Button(action: finishInterrogation) {
                Label("START THE FINAL BALLOT", systemImage: "arrow.right")
            }
            .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))
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

            if round.crossExamination {
                MouthPanel(color: MouthColors.blue) {
                    MouthTag(text: "THE SECOND OPINION", fill: MouthColors.paper)
                    Text("\(round.changedTheirMindCount) changed their mind.")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                    Text("Initial nominations vs. final votes. We only show totals, never who voted for whom.")
                        .font(.system(size: 13, weight: .medium))
                    HStack {
                        Text("PLAYER")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("FIRST")
                            .frame(width: 48)
                        Text("FINAL")
                            .frame(width: 48)
                    }
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    ForEach(game!.players) { person in
                        HStack {
                            Text(person.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            if round.nomineeID == person.id {
                                Image(systemName: "flame.fill")
                                    .accessibilityLabel("Hot seat")
                            }
                            Spacer()
                            Text("\(round.nominationCount(for: person.id))")
                                .frame(width: 48)
                            Text("\(round.voteCount(for: person.id))")
                                .frame(width: 48)
                        }
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        Divider().overlay(MouthColors.ink.opacity(0.12))
                    }
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
                selectedNomination = nil
                isBallotReady = false
                savedSession = nil
                MouthSessionStore.clear()
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

    // MARK: - House decks

    private var selectedHousePack: MouthHousePack? {
        housePacks.first { $0.id == selectedHouseID }
    }

    private var houseDeckEditor: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    MouthSectionHeading(
                        kicker: "WRITTEN BY YOUR TABLE",
                        title: editingDeckID == nil ? "Make a scene." : "Rewrite the rules.",
                        subtitle: "Your own private word pairs. Make them about friends, local places, hobbies, or any in-joke."
                    )

                    MouthPanel {
                        Text("DECK NAME")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        TextField("e.g. Our Friday Nights", text: $draftDeckName)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .padding(12)
                            .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                        Text("ONE PAIR PER LINE")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        Text("Write the ordinary word first, then |, then the nearby odd one.")
                            .font(.system(size: 14, weight: .medium))
                        TextEditor(text: $draftDeckSource)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 250)
                            .padding(10)
                            .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Word pairs, one per line, separated by a vertical bar")
                        Text("For example:\nVinyl | Cassette\nJazz club | Concert hall\nBirthday | Anniversary\n\n3–120 pairs, up to 40 characters per phrase.")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(MouthColors.muted)
                    }

                    Button(action: saveHouseDeck) {
                        Label(editingDeckID == nil ? "SAVE MY DECK" : "SAVE CHANGES",
                              systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(MouthButtonStyle(fill: MouthColors.lime))

                    if let editingDeckID,
                       let deck = housePacks.first(where: { $0.id == editingDeckID }),
                       let code = try? MouthHouseTransfer.export(deck) {
                        ShareLink(item: code) {
                            Label("SHARE SAVED VERSION", systemImage: "square.and.arrow.up.fill")
                        }
                        .buttonStyle(MouthButtonStyle(fill: MouthColors.blue))
                        Text("Save changes before sharing. The portable code works in Messages, AirDrop, or any app you choose.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MouthColors.muted)
                    }

                    if editingDeckID != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("DELETE THIS HOUSE DECK")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    Text("Stored only on this device. No upload or tracking. Use your phone's normal backups to keep these decks.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MouthColors.muted)
                }
                .padding(24)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
            }
            .background(MouthColors.paper.ignoresSafeArea())
            .foregroundStyle(MouthColors.ink)
            .navigationTitle(editingDeckID == nil ? "New house deck" : "Edit house deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isEditingDeck = false }
                }
            }
            .confirmationDialog(
                "Delete this deck? This can't be undone.",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete deck", role: .destructive) {
                    guard let editingDeckID,
                          let pack = housePacks.first(where: { $0.id == editingDeckID }) else { return }
                    deleteHouseDeck(pack)
                }
            }
            .alert(
                "Check this deck.",
                isPresented: Binding(
                    get: { deckErrorMessage != nil },
                    set: { if !$0 { deckErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { deckErrorMessage = nil }
            } message: {
                Text(deckErrorMessage ?? "")
            }
        }
    }

    private var houseDeckImporter: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    MouthSectionHeading(
                        kicker: "THE DECK CHANGES HANDS",
                        title: "Someone brought new words.",
                        subtitle: "Paste the code a friend shared. It imports a new copy of their house deck, which you can edit freely."
                    )

                    MouthPanel(color: MouthColors.lime) {
                        Text("PASTE AN ODDMOUTH DECK CODE")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        TextEditor(text: $importDeckCode)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                            .padding(10)
                            .background(MouthColors.paper, in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Shared house deck code")
                        Text("Codes begin with ODD1:. Nothing is uploaded. Imported decks stay on this iPhone or iPad.")
                            .font(.system(size: 13, weight: .medium))
                    }

                    Button(action: importHouseDeck) {
                        Label("ADD DECK TO THE TABLE", systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(MouthButtonStyle(fill: MouthColors.red))
                    .disabled(importDeckCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(24)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
            }
            .background(MouthColors.paper.ignoresSafeArea())
            .foregroundStyle(MouthColors.ink)
            .navigationTitle("Import house deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isImportingDeck = false }
                }
            }
            .alert(
                "Couldn't read that deck.",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }

    private func importHouseDeck() {
        do {
            let deck = try MouthHouseTransfer.importCode(importDeckCode)
            var updated = housePacks
            updated.append(deck)
            try MouthHouseLibrary.save(updated)
            housePacks = updated
            selectedHouseID = deck.id
            isImportingDeck = false
            importDeckCode = ""
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func showNewHouseDeck() {
        editingDeckID = nil
        draftDeckName = ""
        draftDeckSource = ""
        isEditingDeck = true
    }

    private func showEditHouseDeck(_ pack: MouthHousePack) {
        editingDeckID = pack.id
        draftDeckName = pack.name
        draftDeckSource = pack.editorText
        isEditingDeck = true
    }

    private func saveHouseDeck() {
        do {
            let pack = try MouthHousePack(id: editingDeckID ?? UUID(),
                                          name: draftDeckName, source: draftDeckSource)
            var proposed = housePacks
            if let index = proposed.firstIndex(where: { $0.id == pack.id }) {
                proposed[index] = pack
            } else {
                proposed.append(pack)
            }
            try MouthHouseLibrary.save(proposed)
            housePacks = proposed
            selectedHouseID = pack.id
            isEditingDeck = false
        } catch {
            deckErrorMessage = error.localizedDescription
        }
    }

    private func deleteHouseDeck(_ pack: MouthHousePack) {
        do {
            let proposed = housePacks.filter { $0.id != pack.id }
            try MouthHouseLibrary.save(proposed)
            housePacks = proposed
            if selectedHouseID == pack.id { selectedHouseID = nil }
            isEditingDeck = false
        } catch {
            deckErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Crash-safe, local-only match recovery

    private func checkForSavedSession() {
        guard !hasCheckedResume else { return }
        hasCheckedResume = true
        savedSession = MouthSessionStore.load()
    }

    private func resumeSavedSession() {
        guard let snapshot = savedSession else { return }
        game = snapshot.game
        category = snapshot.category
        includeBlank = snapshot.includeBlank
        crossExamination = snapshot.crossExamination
        clueDuration = snapshot.clueDuration
        secondsRemaining = snapshot.secondsRemaining
        selectedHouseID = snapshot.selectedHouseID
        isWordShowing = false
        didPeek = false
        selectedVote = nil
        selectedNomination = nil
        isBallotReady = false
        savedSession = nil
    }

    private func persistSession() {
        guard let game else { return }
        let snapshot = MouthSessionSnapshot(
            game: game, category: category, includeBlank: includeBlank,
            crossExamination: crossExamination, clueDuration: clueDuration,
            secondsRemaining: secondsRemaining, selectedHouseID: selectedHouseID
        )
        do {
            try MouthSessionStore.save(snapshot)
        } catch {
            // Session persistence is best-effort; never interrupt an active party.
        }
    }

    // MARK: - Session commands

    private func startGame() {
        guard savedSession == nil else { return }
        let players = names.enumerated().map { index, raw -> MouthPlayer in
            let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return MouthPlayer(name: cleaned.isEmpty ? "Player \(index + 1)" : cleaned)
        }
        do {
            var newGame = try MouthGame(players: players)
            try newGame.startRound(
                category: category,
                includeBlank: includeBlank && players.count >= 5,
                crossExamination: crossExamination,
                customPairs: selectedHousePack?.gamePairs
            )
            game = newGame
            isWordShowing = false
            didPeek = false
            isBallotReady = false
            selectedVote = nil
            selectedNomination = nil
            secondsRemaining = clueDuration
            persistSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func advanceReveal() {
        guard var session = game, session.advanceReveal() else { return }
        game = session
        isWordShowing = false
        didPeek = false
        if session.round?.stage == .clues { secondsRemaining = clueDuration }
        persistSession()
    }

    private func advanceClue() {
        guard var session = game, session.advanceClue() else { return }
        game = session
        selectedNomination = nil
        isBallotReady = false
        persistSession()
    }

    private func lockNomination() {
        guard var session = game,
              let round = session.round,
              round.stage == .nominating,
              isBallotReady,
              let target = selectedNomination else { return }
        let voter = session.players[round.nominations.count]
        do {
            try session.nominate(from: voter.id, for: target)
            game = session
            selectedNomination = nil
            isBallotReady = false
            if session.round?.stage == .interrogation { secondsRemaining = 30 }
            persistSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishInterrogation() {
        guard var session = game, session.finishInterrogation() else { return }
        game = session
        selectedVote = nil
        isBallotReady = false
        persistSession()
    }

    private func lockVote() {
        guard var session = game,
              let round = session.round,
              round.stage == .voting,
              isBallotReady,
              let target = selectedVote else { return }
        let voter = session.players[round.votes.count]
        do {
            try session.castVote(from: voter.id, for: target)
            game = session
            selectedVote = nil
            isBallotReady = false
            persistSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nextRound() {
        guard var session = game else { return }
        do {
            try session.startRound(
                category: category,
                includeBlank: includeBlank && session.players.count >= 5,
                crossExamination: crossExamination,
                customPairs: selectedHousePack?.gamePairs
            )
            game = session
            secondsRemaining = clueDuration
            isWordShowing = false
            didPeek = false
            selectedVote = nil
            selectedNomination = nil
            isBallotReady = false
            persistSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
