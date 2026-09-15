import SwiftUI

/// Role: Wash. Twist screen. Neighbor-bleed wash — lerp toward yesterday, then wash-runs.
struct WashBleedView: View {
    @ObservedObject var folio: AlmanacFolio
    var onPaint: () -> Void
    var fillsCanvas: Bool

    init(folio: AlmanacFolio, onPaint: @escaping () -> Void = {}, fillsCanvas: Bool = true) {
        self.folio = folio
        self.onPaint = onPaint
        self.fillsCanvas = fillsCanvas
    }

    init() {
        self.init(folio: FolioPreview.populated())
    }

    var body: some View {
        Group {
            if folio.strokes.isEmpty {
                FolioEmptyState(
                    image: "wfo_TwistHero",
                    headline: "No marks yet.",
                    line: "Mark how today felt. The year keeps it.",
                    actionTitle: "Mark today",
                    action: onPaint
                )
            } else {
                populated
            }
        }
        .padding(fillsCanvas ? FolioChrome.space(2) : 0)
        .frame(maxWidth: .infinity, maxHeight: fillsCanvas ? .infinity : nil, alignment: .topLeading)
        .background {
            if fillsCanvas {
                FolioChrome.Palette.background.ignoresSafeArea()
            }
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            Image("wfo_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: FolioChrome.space(16))
                .accessibilityHidden(true)
            Text("Neighbor-bleed wash")
                .font(FolioType.Step.title.font)
                .foregroundStyle(FolioChrome.Palette.ink)
            Text("Today leans toward yesterday, so a stretch reads as one wash. A lone day stays the state you picked.")
                .font(FolioType.Step.body.font)
                .foregroundStyle(FolioChrome.Palette.muted)
            HStack {
                Text("Bleed")
                    .folioText(.body)
                    .lineLimit(1)
                Spacer(minLength: FolioChrome.space(1))
                Text(FolioFigures.bleed(folio.bleedAmount))
                    .folioText(.figure)
                    .layoutPriority(1)
            }
            HStack {
                Text("Wash runs")
                    .folioText(.body)
                    .lineLimit(1)
                Spacer(minLength: FolioChrome.space(1))
                Text(FolioFigures.integer(folio.washRuns.count))
                    .folioText(.figure)
                    .layoutPriority(1)
            }
        }
    }
}
