import Foundation

/// Role: Year document. In-memory folios for previews and no-argument screens.
enum FolioPreview {
    @MainActor
    static func make(year: Int = Calendar.current.component(.year, from: Date()), now: Date = Date()) -> AlmanacFolio {
        let suite = "wfo.preview.\(UUID().uuidString)"
        UserDefaults(suiteName: suite)?.set(true, forKey: FolioKey.demo)
        return AlmanacFolio(
            store: FolioStore(suiteName: suite, writeDelayNanoseconds: 0),
            now: { now },
            year: year
        )
    }

    @MainActor
    static func empty() -> AlmanacFolio {
        make()
    }

    @MainActor
    static func populated() -> AlmanacFolio {
        let now = Date()
        let year = FolioCalendar.year(of: now)
        let folio = make(year: year, now: now)
        let calendar = Calendar.current
        for offset in [3, 2, 1, 0] {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            try? folio.commit(toneIndex: (4 + (3 - offset)) % ToneWell.toneCount, on: day)
        }
        return folio
    }

    @MainActor
    static func warning() -> AlmanacFolio {
        let suite = "wfo.preview.warn.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)
        defaults?.set(true, forKey: FolioKey.demo)
        defaults?.set(Data("nope".utf8), forKey: FolioKey.snapshot)
        return AlmanacFolio(
            store: FolioStore(suiteName: suite, writeDelayNanoseconds: 0),
            year: FolioCalendar.year(of: Date())
        )
    }
}
