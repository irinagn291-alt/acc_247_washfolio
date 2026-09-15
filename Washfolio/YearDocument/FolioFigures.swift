import Foundation

/// Role: Year document. Every displayed number goes through NumberFormatter.
enum FolioFigures {
    static func integer(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func bleed(_ value: Double, locale: Locale = .current) -> String {
        percent(value, locale: locale)
    }

    static func percent(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func monthTitle(_ month: Int, locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let symbols = formatter.monthSymbols ?? []
        let index = month - 1
        guard symbols.indices.contains(index) else { return monthName(month, locale: locale, calendar: calendar) }
        return symbols[index]
    }

    static func monthName(_ month: Int, locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let symbols = formatter.shortMonthSymbols ?? []
        let index = month - 1
        guard symbols.indices.contains(index) else { return "—" }
        return symbols[index]
    }

    static func weekdayLetters(calendar: Calendar = .current, locale: Locale = .current) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = max(0, calendar.firstWeekday - 1)
        return (0 ..< 7).map { symbols[(first + $0) % symbols.count] }
    }

    static func mediumDate(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter.string(from: date)
    }

    static func range(from start: Date, to end: Date, locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        if calendar.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        }
        return "\(formatter.string(from: start))–\(formatter.string(from: end))"
    }

    static func daysWord(_ count: Int, locale: Locale = .current) -> String {
        let number = integer(count, locale: locale)
        return count == 1 ? "\(number) day" : "\(number) days"
    }

    static func quiet(_ count: Int, locale: Locale = .current) -> String {
        let number = integer(count, locale: locale)
        return count == 1 ? "\(number) day in a row" : "\(number) days in a row"
    }
}
