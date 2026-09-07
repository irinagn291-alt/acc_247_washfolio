import SwiftUI
import UIKit

/// Role: Year document chrome. Typed rag-paper tokens. Hex lives only here.
enum FolioChrome {
    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("accent")
        static let muted = Color("muted")
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
            case .display: .system(.title, design: .serif).weight(.semibold)
            case .title: .system(.title2, design: .serif).weight(.semibold)
            case .body: .system(.body, design: .serif)
            case .caption: .system(.caption, design: .serif)
            case .figure: .system(.title3, design: .serif).weight(.semibold)
            case .footnote: .system(.footnote, design: .serif)
            }
        }
    }

    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let radius: CGFloat = 0
    static let motion: Animation = .easeInOut(duration: 0.28)

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }

    static let contact = URL(string: "https://washfolio.pro/contact-us")!
}

extension FolioInk {
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

struct FolioBleedSlider: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let thumb: CGFloat = 28
            let travel = max(width - thumb, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FolioChrome.Palette.surface)
                    .frame(height: 8)
                Capsule()
                    .fill(FolioChrome.Palette.accent)
                    .frame(width: max(8, thumb + travel * value), height: 8)
                Circle()
                    .fill(FolioChrome.Palette.ink)
                    .frame(width: thumb, height: thumb)
                    .offset(x: travel * value)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    value = min(1, max(0, drag.location.x / width))
                }
            )
        }
        .frame(height: FolioChrome.tap)
        .accessibilityLabel("Bleed amount")
        .accessibilityValue(FolioFigures.bleed(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(1, value + 0.05)
            case .decrement: value = max(0, value - 0.05)
            default: break
            }
        }
    }
}

struct FolioSheetChrome: View {
    var title: String
    var closeLabel: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: FolioChrome.space(1)) {
            Text(title)
                .folioText(.title)
                .lineLimit(1)
            Spacer(minLength: FolioChrome.space(1))
            Button(action: onClose) {
                Text("Done")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .padding(.horizontal, FolioChrome.space(1))
                    .frame(minWidth: FolioChrome.tap, minHeight: FolioChrome.tap)
                    .background(FolioChrome.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(closeLabel)
        }
    }
}

extension View {
    func folioText(_ step: FolioChrome.Step) -> some View {
        font(step.font)
            .foregroundStyle(FolioChrome.Palette.ink)
    }

    func folioTap() -> some View {
        frame(minWidth: FolioChrome.tap, minHeight: FolioChrome.tap)
            .contentShape(Rectangle())
    }

    func folioLabelHit() -> some View {
        frame(minWidth: FolioChrome.tap, minHeight: FolioChrome.tap)
            .contentShape(Rectangle())
    }

    func folioRowHit() -> some View {
        frame(maxWidth: .infinity, minHeight: FolioChrome.tap, alignment: .leading)
            .contentShape(Rectangle())
    }
}
