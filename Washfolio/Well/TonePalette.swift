import Foundation

/// Role: Well. One spoken swatch in the twelve-tone well. Colour is never the only signal.
struct FolioSwatch: Hashable, Sendable, Codable, Identifiable {
    var spokenName: String
    var ink: FolioInk

    var id: String { spokenName }
}

/// Role: Well. The twelve-tone well. Palette rewrite must keep twelve named inks.
enum ToneWell {
    static let toneCount = 12
    static let defaultBleed = 0.35

    static let defaultPalette: [FolioSwatch] = [
        FolioSwatch(spokenName: "Dead", ink: FolioInk(red: 0.12, green: 0.10, blue: 0.08)),
        FolioSwatch(spokenName: "Heavy", ink: FolioInk(red: 0.22, green: 0.20, blue: 0.18)),
        FolioSwatch(spokenName: "Drained", ink: FolioInk(red: 0.40, green: 0.28, blue: 0.16)),
        FolioSwatch(spokenName: "Restless", ink: FolioInk(red: 0.72, green: 0.52, blue: 0.22)),
        FolioSwatch(spokenName: "Wired", ink: FolioInk(red: 0.62, green: 0.28, blue: 0.16)),
        FolioSwatch(spokenName: "Lit", ink: FolioInk(red: 0.61, green: 0.17, blue: 0.16)),
        FolioSwatch(spokenName: "Tender", ink: FolioInk(red: 0.55, green: 0.22, blue: 0.32)),
        FolioSwatch(spokenName: "Focused", ink: FolioInk(red: 0.22, green: 0.24, blue: 0.38)),
        FolioSwatch(spokenName: "Steady", ink: FolioInk(red: 0.32, green: 0.38, blue: 0.42)),
        FolioSwatch(spokenName: "Calm", ink: FolioInk(red: 0.28, green: 0.38, blue: 0.26)),
        FolioSwatch(spokenName: "Clear", ink: FolioInk(red: 0.78, green: 0.72, blue: 0.64)),
        FolioSwatch(spokenName: "Rest", ink: FolioInk(red: 0.90, green: 0.84, blue: 0.72)),
    ]

    static let legacyInkNames = [
        "Gall", "Soot", "Umber", "Ochre", "Rust", "Rubric",
        "Lake", "Indigo", "Slate", "Moss", "Pearl", "Ivory",
    ]

    static func validated(_ palette: [FolioSwatch]) throws -> [FolioSwatch] {
        guard palette.count == toneCount else { throw FolioError.invalidPalette }
        var names = Set<String>()
        for swatch in palette {
            let name = swatch.spokenName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, names.insert(name).inserted else { throw FolioError.invalidPalette }
            try validate(swatch.ink)
        }
        return palette
    }

    static func validate(_ ink: FolioInk) throws {
        for channel in [ink.red, ink.green, ink.blue] {
            guard channel.isFinite, (0 ... 1).contains(channel) else { throw FolioError.invalidInk }
        }
    }

    static func settingBleed(_ amount: Double) throws -> Double {
        guard amount.isFinite, (0 ... 1).contains(amount) else { throw FolioError.invalidBleed }
        return amount
    }
}
