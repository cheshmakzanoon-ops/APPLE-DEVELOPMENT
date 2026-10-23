import Foundation

/// Original, hand-curated pairs. Similar enough to bluff, different enough to betray a tell.
/// Keep the common and alternate words culturally accessible and avoid named trademarks.
public enum MouthDeck {
    public static func entries(for category: MouthCategory) -> [MouthWordPair] {
        category == .all ? catalogue : catalogue.filter { $0.category == category }
    }

    private static let catalogue: [MouthWordPair] =
        everyday.map { MouthWordPair($0.0, $0.1, category: .everyday) }
        + afterHours.map { MouthWordPair($0.0, $0.1, category: .afterHours) }
        + food.map { MouthWordPair($0.0, $0.1, category: .food) }
        + sideways.map { MouthWordPair($0.0, $0.1, category: .sideways) }

    private static let everyday: [(String, String)] = [
        ("Bookshop", "Library"),
        ("Rooftop", "Balcony"),
        ("Umbrella", "Raincoat"),
        ("Backpack", "Suitcase"),
        ("Elevator", "Escalator"),
        ("Dentist", "Orthodontist"),
        ("Pharmacy", "Clinic"),
        ("Notebook", "Journal"),
        ("Train", "Tram"),
        ("Subway", "Bus"),
        ("Guesthouse", "Hotel"),
        ("Postcard", "Letter"),
        ("Password", "PIN code"),
        ("Mirror", "Window"),
        ("Curtains", "Blinds"),
        ("Laundry", "Dry cleaning"),
        ("Flashlight", "Lantern"),
        ("Wallet", "Purse"),
        ("Keys", "Keycard"),
        ("Slippers", "Socks"),
        ("Alarm clock", "Timer"),
        ("Blanket", "Duvet"),
        ("Tote bag", "Shopping basket"),
        ("Couch", "Armchair"),
        ("Bookmark", "Sticky note"),
        ("Lawn", "Garden"),
        ("Thermostat", "Radiator"),
        ("Parking lot", "Garage"),
        ("Staircase", "Ladder"),
        ("Puddle", "Pond")
    ]

    private static let afterHours: [(String, String)] = [
        ("Karaoke", "Open mic"),
        ("House party", "Dinner party"),
        ("Nightclub", "Cocktail bar"),
        ("Concert", "Music festival"),
        ("Bouncer", "Security guard"),
        ("Wristband", "Ticket"),
        ("Disco ball", "Spotlight"),
        ("DJ", "Drummer"),
        ("Afterparty", "Pre-game"),
        ("Toast", "Speech"),
        ("Dance floor", "Stage"),
        ("Cocktail", "Mocktail"),
        ("Champagne", "Sparkling wine"),
        ("Photo booth", "Selfie"),
        ("Blind date", "Speed dating"),
        ("Hotel lobby", "Airport lounge"),
        ("Rooftop bar", "Pub"),
        ("Jukebox", "Playlist"),
        ("Encore", "Rehearsal"),
        ("Doorman", "Host"),
        ("Dress code", "Uniform"),
        ("Midnight", "Sunrise"),
        ("Cab ride", "Night bus"),
        ("Confetti", "Glitter"),
        ("Billiards", "Darts"),
        ("Neon sign", "Marquee"),
        ("Secret admirer", "Crush"),
        ("Mascot", "Costume"),
        ("Applause", "Cheering"),
        ("Whisper", "Rumor")
    ]

    private static let food: [(String, String)] = [
        ("Croissant", "Brioche"),
        ("Espresso", "Americano"),
        ("Pickle", "Olive"),
        ("Toast", "Bagel"),
        ("Burrito", "Wrap"),
        ("Ramen", "Pho"),
        ("Sorbet", "Gelato"),
        ("Waffle", "Pancake"),
        ("Muffin", "Cupcake"),
        ("Dumpling", "Ravioli"),
        ("Lemonade", "Iced tea"),
        ("Pesto", "Salsa"),
        ("Oatmeal", "Porridge"),
        ("Nachos", "Chips"),
        ("Brownie", "Fudge"),
        ("Hot dog", "Sausage roll"),
        ("Risotto", "Paella"),
        ("Sushi", "Poke bowl"),
        ("Mashed potato", "Baked potato"),
        ("Cottage cheese", "Ricotta"),
        ("Pretzel", "Breadstick"),
        ("Cinnamon roll", "Danish pastry"),
        ("Peanut butter", "Almond butter"),
        ("Custard", "Pudding"),
        ("Milkshake", "Smoothie"),
        ("Popcorn", "Puffed rice"),
        ("Herbal tea", "Green tea"),
        ("Sourdough", "Baguette"),
        ("Taco", "Quesadilla"),
        ("Caramel", "Butterscotch")
    ]

    private static let sideways: [(String, String)] = [
        ("Astronaut", "Deep-sea diver"),
        ("Lighthouse", "Watchtower"),
        ("Mirage", "Hologram"),
        ("Campfire", "Fireplace"),
        ("Compass", "Treasure map"),
        ("Ghost", "Shadow"),
        ("Time machine", "Teleportation"),
        ("Secret passage", "Trapdoor"),
        ("Castle", "Fortress"),
        ("Museum", "Aquarium"),
        ("Meteor", "Firework"),
        ("Puppet", "Mannequin"),
        ("Labyrinth", "Maze"),
        ("Crystal ball", "Telescope"),
        ("Detective", "Spy"),
        ("Submarine", "Spaceship"),
        ("Treasure chest", "Safe"),
        ("Volcano", "Geyser"),
        ("Robot", "Cyborg"),
        ("Cave", "Tunnel"),
        ("Origami", "Paper airplane"),
        ("Carnival", "Circus"),
        ("Pirate", "Smuggler"),
        ("Secret society", "Fan club"),
        ("Prophecy", "Prediction"),
        ("Costume party", "Masquerade"),
        ("Escape room", "Puzzle box"),
        ("Magician", "Hypnotist"),
        ("Storm", "Tornado"),
        ("Jungle", "Rainforest")
    ]
}
