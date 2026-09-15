import Foundation

/// Role: Year document. One counted state. Colour is never the only signal.
struct FolioStateCount: Equatable, Sendable, Identifiable {
    var toneIndex: Int
    var spokenName: String
    var count: Int
    var red: Double
    var green: Double
    var blue: Double

    var id: Int { toneIndex }
}

/// Role: Year document. One readable line about the open month. Not a journal.
struct FolioInsight: Equatable, Sendable {
    var headline: String
    var markedMonth: Int
    var elapsedMonth: Int
    var unmarkedMonth: Int
    var dominantName: String?
    var weekMarked: Int
    var lastWeekMarked: Int
}

/// Role: Year document. Census of marks. Counts and stretches, never a feed.
enum FolioCensus {
    static func insight(
        year: Int,
        strokes: [DayStroke],
        palette: [FolioSwatch],
        now: Date,
        month: Int? = nil,
        calendar: Calendar = .current
    ) -> FolioInsight {
        let nowMonth = FolioCalendar.month(now, calendar: calendar)
        let nowYear = FolioCalendar.year(of: now, calendar: calendar)
        let month = FolioCalendar.clampMonth(month ?? nowMonth)
        let today = FolioCalendar.dayOfMonth(now, calendar: calendar)
        let monthLength = FolioCalendar.daysInMonth(month, year: year, calendar: calendar)
        let monthStrokes = strokes.filter { stroke in
            guard let date = FolioCalendar.date(year: year, dayOfYear: stroke.dayOfYear, calendar: calendar) else {
                return false
            }
            return FolioCalendar.month(date, calendar: calendar) == month
        }
        let tallies = counts(strokes: monthStrokes, palette: palette)
        let dominant = tallies.max(by: { $0.count < $1.count })
        let elapsed: Int
        if year == nowYear, month == nowMonth {
            elapsed = today
        } else if year < nowYear || (year == nowYear && month < nowMonth) {
            elapsed = monthLength
        } else {
            elapsed = 0
        }
        let unmarked = max(elapsed - monthStrokes.count, 0)
        let week = markedDays(endingOn: now, length: 7, year: year, strokes: strokes, calendar: calendar)
        let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: FolioCalendar.startOfDay(now, calendar: calendar))
        let prior = lastWeekEnd.map {
            markedDays(endingOn: $0, length: 7, year: year, strokes: strokes, calendar: calendar)
        } ?? 0
        let monthName = FolioFigures.monthName(month, calendar: calendar)
        let headline: String
        if elapsed == 0 {
            headline = "\(monthName) is still ahead."
        } else if strokes.isEmpty {
            headline = "Mark how today felt."
        } else if unmarked > 0 {
            if let name = dominant?.spokenName {
                headline = "\(FolioFigures.integer(unmarked)) open in \(monthName) · mostly \(name)"
            } else {
                headline = "\(FolioFigures.integer(unmarked)) open in \(monthName)"
            }
        } else if let name = dominant?.spokenName {
            headline = "\(monthName) is mostly \(name)"
        } else {
            headline = "The year is taking shape."
        }
        return FolioInsight(
            headline: headline,
            markedMonth: monthStrokes.count,
            elapsedMonth: elapsed,
            unmarkedMonth: unmarked,
            dominantName: dominant?.spokenName,
            weekMarked: week,
            lastWeekMarked: prior
        )
    }

    static func counts(strokes: [DayStroke], palette: [FolioSwatch]) -> [FolioStateCount] {
        var bag: [Int: Int] = [:]
        for stroke in strokes {
            bag[stroke.toneIndex, default: 0] += 1
        }
        return bag.keys.sorted().compactMap { index in
            guard palette.indices.contains(index), let count = bag[index], count > 0 else { return nil }
            let swatch = palette[index]
            return FolioStateCount(
                toneIndex: index,
                spokenName: swatch.spokenName,
                count: count,
                red: swatch.ink.red,
                green: swatch.ink.green,
                blue: swatch.ink.blue
            )
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count { return lhs.toneIndex < rhs.toneIndex }
            return lhs.count > rhs.count
        }
    }

    static func longestByState(
        runs: [WashRun],
        strokes: [Int: DayStroke],
        palette: [FolioSwatch]
    ) -> [FolioStateCount] {
        var best: [Int: Int] = [:]
        for run in runs {
            let nameIndex: Int
            let indices = (0 ..< run.length).compactMap { strokes[run.startDayOfYear + $0]?.toneIndex }
            if Set(indices).count == 1, let index = indices.first {
                nameIndex = index
            } else if let index = indices.last {
                nameIndex = index
            } else {
                continue
            }
            best[nameIndex] = max(best[nameIndex] ?? 0, run.length)
        }
        return best.keys.sorted().compactMap { index in
            guard palette.indices.contains(index), let length = best[index] else { return nil }
            let swatch = palette[index]
            return FolioStateCount(
                toneIndex: index,
                spokenName: swatch.spokenName,
                count: length,
                red: swatch.ink.red,
                green: swatch.ink.green,
                blue: swatch.ink.blue
            )
        }
        .sorted { $0.count > $1.count }
    }

    static func markedDays(
        endingOn date: Date,
        length: Int,
        year: Int,
        strokes: [DayStroke],
        calendar: Calendar
    ) -> Int {
        let end = FolioCalendar.startOfDay(date, calendar: calendar)
        let painted = Set(strokes.map(\.dayOfYear))
        var count = 0
        for offset in 0 ..< length {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { continue }
            guard FolioCalendar.year(of: day, calendar: calendar) == year else { continue }
            guard let ordinal = FolioCalendar.dayOfYear(day, calendar: calendar) else { continue }
            if painted.contains(ordinal) { count += 1 }
        }
        return count
    }

    static func openDays(
        month: Int,
        frame: FolioGridFrame
    ) -> [FolioGridCell] {
        frame.cells.filter { cell in
            cell.month == month && !cell.painted && !cell.isFuture
        }
    }
}
