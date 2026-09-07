import SwiftUI

/// Role: Year document. One-shot cover. Skip still writes defaults and the completion flag.
struct FolioOnboarding: View {
    var onFinish: (Bool) -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(onFinish: @escaping (Bool) -> Void = { _ in }) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: FolioChrome.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: "wfo_Onboarding1",
                        title: "Paint the year",
                        line: "The folio is 365 cells. Empty days stay blank. Home is the year, not a list."
                    )
                case 1:
                    pageView(
                        image: "wfo_Onboarding2",
                        title: "Tap today",
                        line: "A twelve-spoke well opens on the canvas. Each tone has a spoken name."
                    )
                case 2:
                    pageView(
                        image: "wfo_Onboarding3",
                        title: "Watch it bleed",
                        line: "If yesterday has a stroke, today's ink leans toward it. An isolated day stays pure."
                    )
                default:
                    pageView(
                        image: "wfo_TwistHero",
                        title: "A wash, not a streak",
                        line: "Analytics count wash-run lengths. A gap restarts. Nothing punishes a missed day."
                    )
                }
            }
            .frame(maxHeight: .infinity)
            .animation(reduceMotion ? nil : FolioChrome.motion, value: page)
            HStack {
                Button("Skip") { onFinish(true) }
                    .folioText(.body)
                    .folioTap()
                Spacer()
                if page < 3 {
                    Button("Next") { page += 1 }
                        .folioText(.body)
                        .foregroundStyle(FolioChrome.Palette.accent)
                        .folioTap()
                } else {
                    Button("Open the year") { onFinish(false) }
                        .folioText(.body)
                        .foregroundStyle(FolioChrome.Palette.accent)
                        .folioTap()
                }
            }
            .padding(.horizontal, FolioChrome.space(2))
        }
        .padding(.vertical, FolioChrome.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FolioChrome.Palette.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: FolioChrome.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .accessibilityHidden(true)
            Text(title)
                .folioText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .folioText(.body)
                .foregroundStyle(FolioChrome.Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FolioChrome.space(3))
        }
    }
}
