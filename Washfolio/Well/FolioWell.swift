import SwiftUI

/// Role: Well. In-place radial overlay on FolioCanvas. Binds to the same year document.
struct FolioWell: View {
    var palette: [FolioSwatch]
    var onPick: (Int) -> Void
    var onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            FolioChrome.Palette.ink.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("Dismiss the well")
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) * 0.36
                ZStack {
                    Image("wfo_ControlFace")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .position(center)
                        .accessibilityHidden(true)
                    ForEach(Array(palette.enumerated()), id: \.element.id) { index, swatch in
                        let angle = (Double(index) / Double(ToneWell.toneCount)) * 2 * Double.pi - Double.pi / 2
                        Button {
                            onPick(index)
                        } label: {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(swatch.ink.color)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Circle().stroke(FolioChrome.Palette.ink.opacity(0.35), lineWidth: 1)
                                    }
                                Text(swatch.spokenName)
                                    .folioText(.footnote)
                                    .lineLimit(1)
                            }
                            .frame(width: FolioChrome.tap, height: FolioChrome.tap + 8)
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
