import SwiftUI
import UIKit

/// Role: Year document. Root canvas. Observes AlmanacFolio; never copies the year.
struct FolioCanvas: View {
    @ObservedObject var folio: AlmanacFolio
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWell = false
    @State private var showWash = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var reviewConsumed = false
    @State private var commitError: FolioError?
    @State private var showSpinner = false

    init(folio: AlmanacFolio, handlesLaunch: Bool = true) {
        self.folio = folio
        self.handlesLaunch = handlesLaunch
    }

    init() {
        self.init(folio: FolioPreview.populated(), handlesLaunch: false)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            canvas(now: timeline.date)
        }
        .background(FolioChrome.Palette.background.ignoresSafeArea())
        .overlay {
            if showWell {
                FolioWell(palette: folio.palette, onPick: paint, onDismiss: { showWell = false })
            }
        }
        .sheet(isPresented: $showWash) {
            WashSheet(
                folio: folio,
                onPaint: { showWash = false; showWell = true },
                onRetry: { await folio.load() }
            )
            .presentationBackground(FolioChrome.Palette.background)
        }
        .sheet(isPresented: $showSettings) {
            FolioSettings(
                folio: folio,
                onRerunOnboarding: {
                    showSettings = false
                    showOnboarding = true
                },
                onDismiss: { showSettings = false }
            )
            .presentationBackground(FolioChrome.Palette.background)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            FolioOnboarding { _ in
                folio.markOnboardingComplete()
                showOnboarding = false
                applyReview()
            }
        }
        .task {
            guard handlesLaunch else { return }
            await bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { try? await folio.persistNow() }
            }
        }
        .animation(reduceMotion ? nil : FolioChrome.motion, value: showWell)
    }

    private func canvas(now current: Date) -> some View {
        let grid = FolioGrid.frame(from: folio, now: current)
        return VStack(spacing: FolioChrome.space(1)) {
            header(now: current)
            if folio.strokes.isEmpty, commitError == nil, folio.warning == nil {
                HStack(spacing: FolioChrome.space(1)) {
                    Image("wfo_EmptyHome")
                        .resizable()
                        .scaledToFit()
                        .frame(width: FolioChrome.space(5), height: FolioChrome.space(5))
                        .accessibilityHidden(true)
                    Text("The year is empty. The first stroke is yours.")
                        .folioText(.caption)
                        .foregroundStyle(FolioChrome.Palette.muted)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, FolioChrome.space(2))
            }
            ZStack {
                FolioYearBoard(frame: grid, onSelectToday: { showWell = true })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if folio.strokes.isEmpty, commitError == nil, folio.warning == nil {
                    VStack {
                        Spacer()
                        Button {
                            showWell = true
                        } label: {
                            Text("Paint today")
                                .folioText(.body)
                                .foregroundStyle(FolioChrome.Palette.accent)
                                .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                                .background(FolioChrome.Palette.surface)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, FolioChrome.space(2))
                        .padding(.bottom, FolioChrome.space(2))
                    }
                    .allowsHitTesting(true)
                }
                if let error = commitError {
                    banner(
                        text: commitCopy(error),
                        action: "Try again"
                    ) {
                        commitError = nil
                        showWell = true
                    }
                } else if let warning = folio.warning {
                    banner(text: warningCopy(warning), action: "Reload the folio") {
                        Task { await folio.load() }
                    }
                }
                if showSpinner {
                    ProgressView()
                        .tint(FolioChrome.Palette.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FolioChrome.Palette.background.opacity(0.55))
                        .accessibilityLabel("Loading the folio")
                }
            }
        }
        .safeAreaPadding(.bottom, FolioChrome.space(1))
    }

    private func header(now current: Date) -> some View {
        VStack(spacing: FolioChrome.space(1)) {
            Image("wfo_HeaderDecor")
                .resizable()
                .scaledToFill()
                .frame(height: FolioChrome.space(6))
                .clipped()
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: FolioChrome.space(1)) {
                Text(String(folio.year))
                    .folioText(.display)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text("Quiet \(FolioFigures.integer(folio.quietStreak(at: current)))")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Bleed \(FolioFigures.bleed(folio.bleedAmount))")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityLabel("Neighbor-bleed \(FolioFigures.bleed(folio.bleedAmount))")
                Spacer(minLength: FolioChrome.space(1))
                headerButton("Wash") { showWash = true }
                    .accessibilityLabel("Wash runs")
                headerButton("Folio") { showSettings = true }
                    .accessibilityLabel("Folio settings")
            }
            .padding(.horizontal, FolioChrome.space(2))
        }
    }

    private func headerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .folioText(.body)
                .foregroundStyle(FolioChrome.Palette.accent)
                .padding(.horizontal, FolioChrome.space(1))
                .frame(minWidth: FolioChrome.tap, minHeight: FolioChrome.tap)
                .background(FolioChrome.Palette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func banner(text: String, action: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: FolioChrome.space(1)) {
            Text(text)
                .folioText(.body)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text(action)
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
        .padding(FolioChrome.space(2))
    }

    private func paint(_ index: Int) {
        do {
            try folio.commit(toneIndex: index, on: Date())
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showWell = false
            commitError = nil
        } catch let error as FolioError {
            commitError = error
        } catch {
            commitError = .invalidTone
        }
    }

    private func bootstrap() async {
        showSpinner = false
        let spinner = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled { showSpinner = true }
        }
        await folio.load()
        spinner.cancel()
        showSpinner = false
        if folio.onboardingComplete {
            applyReview()
        } else {
            showOnboarding = true
        }
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let launch = FolioReview.consume(
            arguments: arguments,
            onboardingComplete: folio.onboardingComplete,
            consumed: &reviewConsumed
        ) else { return }
        FolioLaunch.bind(launch, wash: &showWash, settings: &showSettings)
    }

    private func warningCopy(_ warning: FolioWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "The folio was recovered from a spare leaf."
        case .startedEmpty:
            return "The folio could not be read. The year starts blank."
        }
    }

    private func commitCopy(_ error: FolioError) -> String {
        switch error {
        case .invalidTone: return "That tone is not in the well."
        case .invalidPalette: return "The twelve tones could not be rewritten."
        case .invalidBleed: return "Bleed must stay between none and full."
        case .invalidInk: return "That ink is outside the folio."
        case .dayOutsideYear: return "That day is outside this year."
        }
    }
}
