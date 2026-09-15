import Foundation

/// Role: Year document. Day edges are startOfDay; storage key is ordinal day of year.
enum FolioCalendar {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func year(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: calendar.startOfDay(for: date))
    }

    static func dayOfYear(_ date: Date, calendar: Calendar = .current) -> Int? {
        calendar.ordinality(of: .day, in: .year, for: calendar.startOfDay(for: date))
    }

    static func daysInYear(_ year: Int, calendar: Calendar = .current) -> Int {
        var parts = DateComponents()
        parts.year = year
        parts.month = 1
        parts.day = 1
        guard let january = calendar.date(from: parts),
              let range = calendar.range(of: .day, in: .year, for: january)
        else {
            return 365
        }
        return range.count
    }

    static func date(year: Int, dayOfYear: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = year
        parts.month = 1
        parts.day = 1
        guard let january = calendar.date(from: parts) else { return nil }
        return calendar.date(byAdding: .day, value: dayOfYear - 1, to: january)
    }

    static func yesterday(of date: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))
    }

    static func date(year: Int, month: Int, day: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func month(_ date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.month, from: calendar.startOfDay(for: date))
    }

    static func dayOfMonth(_ date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: calendar.startOfDay(for: date))
    }

    static func daysInMonth(_ month: Int, year: Int, calendar: Calendar = .current) -> Int {
        guard let first = date(year: year, month: month, day: 1, calendar: calendar),
              let range = calendar.range(of: .day, in: .month, for: first)
        else {
            return 30
        }
        return range.count
    }

    static func weekdayColumn(of date: Date, calendar: Calendar = .current) -> Int {
        let weekday = calendar.component(.weekday, from: calendar.startOfDay(for: date))
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    static func clampMonth(_ month: Int) -> Int {
        min(12, max(1, month))
    }
}
