import Foundation

/// Role: Year document. ReviewScreen launch argument. Read once, only after onboarding.
enum FolioReview: String, Equatable, Sendable {
    case today
    case log
    case goals

    static func consume(
        arguments: [String],
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> FolioReview? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return FolioReview(rawValue: arguments[next])
    }
}

/// Role: Year document. Maps a consumed review key onto locked-canvas sheets.
enum FolioLaunch {
    static func bind(_ review: FolioReview, wash: inout Bool, settings: inout Bool) {
        switch review {
        case .today:
            wash = false
            settings = false
        case .log:
            wash = true
            settings = false
        case .goals:
            wash = false
            settings = true
        }
    }
}
