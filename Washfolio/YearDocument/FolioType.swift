import SwiftUI

/// Role: Year document. Almanac folio tokens. New York only. Hex lives only here.
enum FolioType {
    static let family = "New York"

    enum Hex {
        static let background = "#F4EBE0"
        static let surface = "#E8D9C4"
        static let ink = "#1A1510"
        static let accent = "#9B2C28"
        static let muted = "#5E4F3D"
    }

    enum Step: CaseIterable {
        case display
        case title
        case body
        case caption
        case figure
        case footnote

        var font: Font {
            switch self {
            case .display: .system(.largeTitle, design: .serif).weight(.semibold)
            case .title: .system(.title2, design: .serif).weight(.semibold)
            case .body: .system(.body, design: .serif)
            case .caption: .system(.caption, design: .serif)
            case .figure: .system(.title3, design: .serif).weight(.semibold)
            case .footnote: .system(.footnote, design: .serif)
            }
        }
    }
}
