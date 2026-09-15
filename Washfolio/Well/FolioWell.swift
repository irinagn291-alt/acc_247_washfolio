import SwiftUI

/// Role: Well. In-place radial overlay on FolioCanvas. Binds to the same year document.
struct FolioWell: View {
    var palette: [FolioSwatch]
    var title: String = "How was today?"
    var line: String = "Pick a state. Not a score."
    var onPick: (Int) -> Void
    var onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            FolioChrome.Palette.ink.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("Dismiss the well")
            VStack(spacing: FolioChrome.space(1)) {
                Text(title)
                    .font(FolioChrome.Step.title.font)
                    .foregroundStyle(FolioChrome.Palette.background)
                    .multilineTextAlignment(.center)
                Text(line)
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.background)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
            }
            .padding(.top, FolioChrome.space(8))
            .allowsHitTesting(false)
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 + FolioChrome.space(2))
                let radius = min(geo.size.width, geo.size.height) * 0.38
                ZStack {
                    Image("wfo_ControlFace")
                        .resizable()
                        .scaledToFit()
                        .frame(width: FolioChrome.space(8), height: FolioChrome.space(8))
                        .position(center)
                        .accessibilityHidden(true)
                    ForEach(Array(palette.enumerated()), id: \.element.id) { index, swatch in
                        let angle = (Double(index) / Double(ToneWell.toneCount)) * 2 * Double.pi - Double.pi / 2
                        Button {
                            onPick(index)
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(swatch.ink.color)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Circle().stroke(FolioChrome.Palette.background.opacity(0.85), lineWidth: 1)
                                    }
                                Text(swatch.spokenName)
                                    .folioText(.footnote)
                                    .foregroundStyle(FolioChrome.Palette.background)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(width: FolioChrome.tap + 8, height: FolioChrome.tap + 16)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(swatch.spokenName)
                        .position(
                            x: center.x + CGFloat(cos(angle)) * radius,
                            y: center.y + CGFloat(sin(angle)) * radius
                        )
                    }
                }
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
    }
}
