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
                        title: "Mark the day",
                        line: "One tap for how today felt. Missed a day? Mark it later. The year becomes weather, not a list."
                    )
                case 1:
                    pageView(
                        image: "wfo_Onboarding2",
                        title: "Twelve states",
                        line: "Dead, Lit, Focused, Rest — named states, not a 1 to 5 score. Colour is never the only signal."
                    )
                case 2:
                    pageView(
                        image: "wfo_Onboarding3",
                        title: "Days bleed",
                        line: "If yesterday has a mark, today leans toward it. A lone day stays exactly what you picked."
                    )
                default:
                    pageView(
                        image: "wfo_TwistHero",
                        title: "Washes, not streaks",
                        line: "A wash is how long a stretch lasted. A gap starts a new one. Missing a day is not a failure."
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
