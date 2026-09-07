import SwiftUI

/// Role: Year document. Empty folio copy: art, headline, line, one CTA.
struct FolioEmptyState: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: FolioChrome.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: FolioChrome.space(12), height: FolioChrome.space(12))
                .accessibilityHidden(true)
            Text(headline)
                .folioText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .folioText(.body)
                .foregroundStyle(FolioChrome.Palette.muted)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text(actionTitle)
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                    .background(FolioChrome.Palette.background)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(FolioChrome.space(2))
        .frame(maxWidth: .infinity)
        .background(FolioChrome.Palette.surface)
    }
}
