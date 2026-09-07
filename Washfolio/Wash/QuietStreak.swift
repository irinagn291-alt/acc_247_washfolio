import Foundation

/// Role: Wash. Quiet streak is consecutive painted days ending today or yesterday.
enum QuietStreak {
    static func length(painted: Set<Date>, now: Date, calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: now)
        let days = Set(painted.map { calendar.startOfDay(for: $0) })
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        let anchor: Date
        if days.contains(today) {
            anchor = today
        } else if days.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var cursor = anchor
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func length(dayOfYears: Set<Int>, today: Int, yesterday: Int?) -> Int {
        let anchor: Int
        if dayOfYears.contains(today) {
            anchor = today
        } else if let yesterday, dayOfYears.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var day = anchor
        while dayOfYears.contains(day) {
            count += 1
            day -= 1
            if day < 1 { break }
        }
        return count
    }
}
