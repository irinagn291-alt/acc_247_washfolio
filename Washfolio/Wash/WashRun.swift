import Foundation

/// Role: Wash. One contiguous painted run. Analytics read lengths, not a journal of chips.
struct WashRun: Hashable, Sendable, Equatable {
    var startDayOfYear: Int
    var length: Int
}

/// Role: Wash. Census of wash-runs. A gap ends the run; no broken-run theatre.
extension WashRun {
    var endDayOfYear: Int { startDayOfYear + length - 1 }

    func startDate(year: Int, calendar: Calendar = .current) -> Date? {
        FolioCalendar.date(year: year, dayOfYear: startDayOfYear, calendar: calendar)
    }

    func endDate(year: Int, calendar: Calendar = .current) -> Date? {
        FolioCalendar.date(year: year, dayOfYear: endDayOfYear, calendar: calendar)
    }

    func inks(from strokes: [Int: DayStroke]) -> [FolioInk] {
        (0 ..< length).compactMap { offset in
            strokes[startDayOfYear + offset]?.wash
        }
    }

    func spokenName(palette: [FolioSwatch], strokes: [Int: DayStroke]) -> String {
        let indices = (0 ..< length).compactMap { offset in
            strokes[startDayOfYear + offset]?.toneIndex
        }
        let unique = Set(indices)
        if unique.count == 1, let index = indices.first, palette.indices.contains(index) {
            return palette[index].spokenName
        }
        if let index = indices.last, palette.indices.contains(index) {
            return palette[index].spokenName
        }
        return "Wash"
    }
}

enum WashCensus {
    static func runs(in dayOfYears: Set<Int>) -> [WashRun] {
        let sorted = dayOfYears.sorted()
        var result: [WashRun] = []
        var index = 0
        while index < sorted.count {
            let start = sorted[index]
            var length = 1
            var expected = start + 1
            index += 1
            while index < sorted.count, sorted[index] == expected {
                length += 1
                expected += 1
                index += 1
            }
            result.append(WashRun(startDayOfYear: start, length: length))
        }
        return result
    }
}
