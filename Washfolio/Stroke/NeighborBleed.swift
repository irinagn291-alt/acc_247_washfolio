import Foundation

/// Role: Stroke. Twist — commit lerps today's picked tone toward yesterday's wash.
enum NeighborBleed {
    static func blend(picked: FolioInk, yesterday: FolioInk?, amount: Double) -> FolioInk {
        guard let yesterday else { return picked }
        let t = min(1, max(0, amount))
        return picked.lerped(toward: yesterday, amount: t)
    }
}

/// Role: Stroke. Primary verb — one DayStroke per startOfDay, with neighbor-bleed.
enum FolioCommit {
    static func stroke(
        toneIndex: Int,
        on date: Date,
        year: Int,
        existing: [Int: DayStroke],
        palette: [FolioSwatch],
        bleedAmount: Double,
        calendar: Calendar
    ) throws -> DayStroke {
        guard palette.count == ToneWell.toneCount else { throw FolioError.invalidPalette }
        guard (0 ..< ToneWell.toneCount).contains(toneIndex) else { throw FolioError.invalidTone }
        guard bleedAmount.isFinite, (0 ... 1).contains(bleedAmount) else { throw FolioError.invalidBleed }
        guard FolioCalendar.year(of: date, calendar: calendar) == year else {
            throw FolioError.dayOutsideYear
        }
        guard let ordinal = FolioCalendar.dayOfYear(date, calendar: calendar),
              (1 ... FolioCalendar.daysInYear(year, calendar: calendar)).contains(ordinal)
        else {
            throw FolioError.dayOutsideYear
        }

        let picked = palette[toneIndex].ink
        let yesterday = yesterdayWash(on: date, year: year, existing: existing, calendar: calendar)
        let wash = NeighborBleed.blend(picked: picked, yesterday: yesterday, amount: bleedAmount)
        return DayStroke(dayOfYear: ordinal, year: year, toneIndex: toneIndex, wash: wash)
    }

    static func placing(_ stroke: DayStroke, into existing: [Int: DayStroke]) -> [Int: DayStroke] {
        var next = existing
        next[stroke.dayOfYear] = stroke
        return next
    }

    private static func yesterdayWash(
        on date: Date,
        year: Int,
        existing: [Int: DayStroke],
        calendar: Calendar
    ) -> FolioInk? {
        let start = FolioCalendar.startOfDay(date, calendar: calendar)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: start) else { return nil }
        guard FolioCalendar.year(of: yesterday, calendar: calendar) == year else { return nil }
        guard let ordinal = FolioCalendar.dayOfYear(yesterday, calendar: calendar) else { return nil }
        return existing[ordinal]?.wash
    }
}
