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
        FolioSwatch(spokenName: "Gall", ink: FolioInk(red: 0.12, green: 0.10, blue: 0.08)),
        FolioSwatch(spokenName: "Soot", ink: FolioInk(red: 0.22, green: 0.20, blue: 0.18)),
        FolioSwatch(spokenName: "Umber", ink: FolioInk(red: 0.40, green: 0.28, blue: 0.16)),
        FolioSwatch(spokenName: "Ochre", ink: FolioInk(red: 0.72, green: 0.52, blue: 0.22)),
        FolioSwatch(spokenName: "Rust", ink: FolioInk(red: 0.62, green: 0.28, blue: 0.16)),
        FolioSwatch(spokenName: "Rubric", ink: FolioInk(red: 0.61, green: 0.17, blue: 0.16)),
        FolioSwatch(spokenName: "Lake", ink: FolioInk(red: 0.55, green: 0.22, blue: 0.32)),
        FolioSwatch(spokenName: "Indigo", ink: FolioInk(red: 0.22, green: 0.24, blue: 0.38)),
        FolioSwatch(spokenName: "Slate", ink: FolioInk(red: 0.32, green: 0.38, blue: 0.42)),
        FolioSwatch(spokenName: "Moss", ink: FolioInk(red: 0.28, green: 0.38, blue: 0.26)),
        FolioSwatch(spokenName: "Pearl", ink: FolioInk(red: 0.78, green: 0.72, blue: 0.64)),
        FolioSwatch(spokenName: "Ivory", ink: FolioInk(red: 0.90, green: 0.84, blue: 0.72)),
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
