import Foundation

/// Role: Stroke. One MoodEntry for one local startOfDay, keyed by ordinal day of year.
struct DayStroke: Hashable, Sendable, Codable, Identifiable {
    var dayOfYear: Int
    var year: Int
    var toneIndex: Int
    var wash: FolioInk

    var id: String { "\(year)-\(dayOfYear)" }
}

/// Role: Stroke. Stored wash colour after neighbor-bleed. Not a 1–5 score.
struct FolioInk: Hashable, Sendable, Codable {
    var red: Double
    var green: Double
    var blue: Double

    func lerped(toward other: FolioInk, amount: Double) -> FolioInk {
        FolioInk(
            red: Self.mix(red, other.red, amount),
            green: Self.mix(green, other.green, amount),
            blue: Self.mix(blue, other.blue, amount)
        )
    }

    private static func mix(_ from: Double, _ toward: Double, _ amount: Double) -> Double {
        from + (toward - from) * amount
    }
}

/// Role: Stroke. Failures of the paint verb and palette rewrite.
enum FolioError: Error, Equatable, Sendable {
    case invalidTone
    case invalidPalette
    case invalidBleed
    case invalidInk
    case dayOutsideYear
}
