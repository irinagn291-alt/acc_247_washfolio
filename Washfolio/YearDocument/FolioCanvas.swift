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
    @State private var inspected: FolioGridCell?
    @State private var markingDay: Int?
    @State private var focusTone: Int?
    @State private var confirmClear = false
    @State private var visibleMonth = Calendar.current.component(.month, from: Date())
    @State private var showYear = false

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FolioChrome.Palette.background.ignoresSafeArea())
        .overlay {
            if showWell {
                FolioWell(
                    palette: folio.palette,
                    title: wellTitle,
                    line: "Pick a state. Not a score.",
                    onPick: paint,
                    onDismiss: { showWell = false }
                )
            }
        }
        .sheet(isPresented: $showWash) {
            WashSheet(
                folio: folio,
                onPaint: { showWash = false; openWell(for: nil) },
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
        .sheet(isPresented: $showYear) {
            yearSheet
                .presentationBackground(FolioChrome.Palette.background)
        }
        .confirmationDialog("Clear this mark?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear mark", role: .destructive) { clearMark() }
            Button("Cancel", role: .cancel) {}
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

    private var wellTitle: String {
        if let markingDay,
           let date = FolioCalendar.date(year: folio.year, dayOfYear: markingDay)
        {
            return "How was \(FolioFigures.mediumDate(date))?"
        }
        return "How was today?"
    }

    private var yearSheet: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let grid = FolioGrid.frame(from: folio, now: timeline.date)
            VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
                FolioSheetChrome(title: "Year", closeLabel: "Close year") {
                    showYear = false
                }
                Text("Tap a month, or a day.")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
                FolioYearBoard(
                    frame: grid,
                    selectedDay: inspected?.dayOfYear,
                    focusTone: focusTone,
                    onSelectToday: {
                        jumpToToday(in: grid)
                        showYear = false
                    },
                    onInspect: { cell in
                        visibleMonth = cell.month
                        inspected = cell
                        showYear = false
                    },
                    onOpenMonth: { month in
                        visibleMonth = month
                        if inspected?.month != month {
                            inspected = nil
                        }
                        showYear = false
                    }
                )
            }
            .padding(FolioChrome.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(FolioChrome.Palette.background.ignoresSafeArea())
        }
    }

    private func canvas(now current: Date) -> some View {
        let grid = FolioGrid.frame(from: folio, now: current)
        let today = grid.cells.first(where: \.isToday)
        let shown = inspected ?? today
        let insight = folio.insight(at: current, month: visibleMonth)
        let counts = folio.stateCounts(inMonth: visibleMonth)
        let openDays = FolioCensus.openDays(month: visibleMonth, frame: grid)
        return ZStack {
            FolioMonthBoard(
                frame: grid,
                month: visibleMonth,
                selectedDay: shown?.dayOfYear,
                focusTone: focusTone,
                onSelect: handleDay
            )
            .padding(.horizontal, FolioChrome.space(2))
            .simultaneousGesture(monthSwipe)
            if let error = commitError {
                banner(
                    text: commitCopy(error),
                    action: "Try again"
                ) {
                    commitError = nil
                    openWell(for: shown)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                header(now: current, insight: insight)
                monthChrome(now: current, grid: grid, insight: insight)
                if !counts.isEmpty {
                    filterChips(counts)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if !openDays.isEmpty {
                    openRow(openDays)
                }
                dayDock(shown: shown, previous: priorCell(of: shown, in: grid))
            }
            .safeAreaPadding(.bottom, FolioChrome.space(1))
        }
    }

    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.width < -40 {
                shiftMonth(1)
            } else if value.translation.width > 40 {
                shiftMonth(-1)
            }
        }
    }

    private func monthChrome(now current: Date, grid: FolioGridFrame, insight: FolioInsight) -> some View {
        HStack(spacing: FolioChrome.space(1)) {
            navButton("Previous month", symbol: "‹") {
                shiftMonth(-1)
            }
            VStack(spacing: 2) {
                Text(FolioFigures.monthTitle(visibleMonth))
                    .folioText(.title)
                    .lineLimit(1)
                Text("\(FolioFigures.integer(insight.markedMonth)) marked · \(FolioFigures.integer(insight.unmarkedMonth)) open")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            navButton("Next month", symbol: "›") {
                shiftMonth(1)
            }
            headerButton("Today") { jumpToToday(in: grid) }
            headerButton("Year") { showYear = true }
                .accessibilityLabel("Year overview")
        }
        .padding(.horizontal, FolioChrome.space(2))
        .padding(.bottom, FolioChrome.space(1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(FolioFigures.monthTitle(visibleMonth)) \(FolioFigures.integer(FolioCalendar.year(of: current)))")
    }

    private func navButton(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .folioText(.title)
                .frame(width: FolioChrome.tap, height: FolioChrome.tap)
                .background(FolioChrome.Palette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func openRow(_ days: [FolioGridCell]) -> some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(1)) {
            Text("Open days")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FolioChrome.space(1)) {
                    ForEach(days, id: \.dayOfYear) { cell in
                        Button {
                            handleDay(cell)
                        } label: {
                            Text(FolioFigures.integer(cell.dayOfMonth))
                                .folioText(.body)
                                .frame(minWidth: FolioChrome.tap, minHeight: FolioChrome.tap)
                                .background(FolioChrome.Palette.surface)
                                .overlay {
                                    Rectangle().stroke(FolioChrome.Palette.ink.opacity(0.18), lineWidth: 1)
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open \(FolioFigures.monthTitle(cell.month)) \(FolioFigures.integer(cell.dayOfMonth))")
                    }
                }
            }
        }
        .padding(.horizontal, FolioChrome.space(2))
        .padding(.vertical, FolioChrome.space(1))
    }

    private func header(now current: Date, insight: FolioInsight) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image("wfo_HeaderDecor")
                .resizable()
                .scaledToFill()
                .frame(height: FolioChrome.space(11))
                .clipped()
                .accessibilityHidden(true)
            HStack(alignment: .center, spacing: FolioChrome.space(1)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(folio.year))
                        .folioText(.display)
                        .lineLimit(1)
                        .layoutPriority(1)
                    Text(insight.headline)
                        .folioText(.caption)
                        .foregroundStyle(FolioChrome.Palette.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel(
                            "\(insight.headline), \(FolioFigures.quiet(folio.quietStreak(at: current)))"
                        )
                }
                Spacer(minLength: FolioChrome.space(1))
                headerButton("Washes") { showWash = true }
                    .accessibilityLabel("Wash runs")
                headerButton("Settings") { showSettings = true }
                    .accessibilityLabel("Folio settings")
            }
            .padding(.horizontal, FolioChrome.space(2))
            .padding(.bottom, FolioChrome.space(1))
        }
    }

    private func filterChips(_ counts: [FolioStateCount]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FolioChrome.space(1)) {
                filterChip(title: "All", selected: focusTone == nil) {
                    focusTone = nil
                }
                ForEach(counts) { count in
                    filterChip(
                        title: "\(count.spokenName) \(FolioFigures.integer(count.count))",
                        selected: focusTone == count.toneIndex,
                        swatch: Color(red: count.red, green: count.green, blue: count.blue)
                    ) {
                        focusTone = focusTone == count.toneIndex ? nil : count.toneIndex
                    }
                }
            }
            .padding(.horizontal, FolioChrome.space(2))
            .padding(.bottom, FolioChrome.space(1))
        }
        .accessibilityLabel("Filter this month by state")
    }

    private func filterChip(title: String, selected: Bool, swatch: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    Circle()
                        .fill(swatch)
                        .frame(width: 10, height: 10)
                }
                Text(title)
                    .folioText(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, FolioChrome.space(1))
            .frame(minHeight: FolioChrome.tap - 8)
            .background(selected ? FolioChrome.Palette.surface : FolioChrome.Palette.background)
            .overlay {
                Rectangle()
                    .stroke(FolioChrome.Palette.ink.opacity(selected ? 0.45 : 0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func dayDock(shown: FolioGridCell?, previous: FolioGridCell?) -> some View {
        let markable = shown?.isFuture == false
        let painted = shown?.painted == true
        let canRepeat = markable && !painted && previous?.painted == true
        return HStack(alignment: .center, spacing: FolioChrome.space(1)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dockTitle(shown))
                    .folioText(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(dockLine(shown))
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if canRepeat {
                Button { repeatYesterday(on: shown) } label: {
                    Text("Same")
                        .folioText(.body)
                        .foregroundStyle(FolioChrome.Palette.ink)
                        .padding(.horizontal, FolioChrome.space(1))
                        .frame(minHeight: FolioChrome.tap)
                        .overlay {
                            Rectangle().stroke(FolioChrome.Palette.ink.opacity(0.22), lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Same as the day before")
            }
            if markable, painted {
                Button {
                    confirmClear = true
                } label: {
                    Text("Clear")
                        .folioText(.body)
                        .foregroundStyle(FolioChrome.Palette.ink)
                        .padding(.horizontal, FolioChrome.space(1))
                        .frame(minHeight: FolioChrome.tap)
                        .overlay {
                            Rectangle().stroke(FolioChrome.Palette.ink.opacity(0.22), lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear this mark")
            }
            if markable {
                Button { openWell(for: shown) } label: {
                    Text(painted ? "Change" : "Mark")
                        .folioText(.body)
                        .foregroundStyle(FolioChrome.Palette.background)
                        .padding(.horizontal, FolioChrome.space(2))
                        .frame(minHeight: FolioChrome.tap)
                        .background(FolioChrome.Palette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the states")
            }
        }
        .padding(.horizontal, FolioChrome.space(2))
        .padding(.vertical, FolioChrome.space(1))
        .frame(maxWidth: .infinity)
        .background(FolioChrome.Palette.surface)
    }

    private func dockTitle(_ cell: FolioGridCell?) -> String {
        guard let cell else { return "Today" }
        if let date = FolioCalendar.date(year: folio.year, dayOfYear: cell.dayOfYear) {
            return FolioFigures.mediumDate(date)
        }
        return "Day \(FolioFigures.integer(cell.dayOfYear))"
    }

    private func dockLine(_ cell: FolioGridCell?) -> String {
        guard let cell else { return "How was today?" }
        if cell.isFuture {
            return "This day is still ahead."
        }
        if cell.isToday {
            return cell.painted ? "Today felt \(cell.spokenName)." : "How was today?"
        }
        return cell.painted ? "This day felt \(cell.spokenName)." : "Missed day. You can still mark it."
    }

    private func headerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .folioText(.body)
                .foregroundStyle(FolioChrome.Palette.ink)
                .padding(.horizontal, FolioChrome.space(2))
                .frame(minHeight: FolioChrome.tap)
                .background(FolioChrome.Palette.background.opacity(0.88))
                .overlay {
                    Rectangle()
                        .stroke(FolioChrome.Palette.ink.opacity(0.22), lineWidth: 1)
                }
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

    private func priorCell(of cell: FolioGridCell?, in grid: FolioGridFrame) -> FolioGridCell? {
        guard let cell,
              let date = FolioCalendar.date(year: folio.year, dayOfYear: cell.dayOfYear),
              let prior = FolioCalendar.yesterday(of: date),
              FolioCalendar.year(of: prior) == folio.year,
              let ordinal = FolioCalendar.dayOfYear(prior)
        else { return nil }
        return grid.cells.first { $0.dayOfYear == ordinal }
    }

    private func shiftMonth(_ delta: Int) {
        visibleMonth = FolioCalendar.clampMonth(visibleMonth + delta)
        if inspected?.month != visibleMonth {
            inspected = nil
        }
    }

    private func jumpToToday(in grid: FolioGridFrame) {
        guard let today = grid.cells.first(where: \.isToday) else { return }
        visibleMonth = today.month
        inspected = today
    }

    private func handleDay(_ cell: FolioGridCell) {
        inspected = cell
        visibleMonth = cell.month
        if cell.isFuture { return }
        if !cell.painted {
            openWell(for: cell)
        }
    }

    private func repeatYesterday(on cell: FolioGridCell?) {
        let date = cell.flatMap { FolioCalendar.date(year: folio.year, dayOfYear: $0.dayOfYear) } ?? Date()
        do {
            try folio.repeatYesterday(on: date)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            commitError = nil
        } catch let error as FolioError {
            commitError = error
        } catch {
            commitError = .invalidTone
        }
    }

    private func openWell(for cell: FolioGridCell?) {
        if let cell, cell.isFuture { return }
        markingDay = cell?.dayOfYear
        showWell = true
    }

    private func paint(_ index: Int) {
        let date = markingDay.flatMap { FolioCalendar.date(year: folio.year, dayOfYear: $0) } ?? Date()
        do {
            try folio.commit(toneIndex: index, on: date)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showWell = false
            commitError = nil
            inspected = nil
            markingDay = nil
        } catch let error as FolioError {
            commitError = error
        } catch {
            commitError = .invalidTone
        }
    }

    private func clearMark() {
        guard let day = inspected?.dayOfYear ?? FolioCalendar.dayOfYear(Date()) else { return }
        folio.clear(dayOfYear: day)
        inspected = nil
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
        case .dayInFuture: return "That day is still ahead."
        }
    }
}

/// Role: Year document. Last seven days on the locked canvas. Tappable marks.
struct FolioWeekStrip: View {
    var cells: [FolioGridCell]
    var selectedDay: Int?
    var onSelect: (FolioGridCell) -> Void

    var body: some View {
        let letters = FolioFigures.weekdayLetters()
        HStack(spacing: FolioChrome.space(1)) {
            ForEach(cells, id: \.dayOfYear) { cell in
                Button {
                    onSelect(cell)
                } label: {
                    VStack(spacing: 4) {
                        Text(letters.indices.contains(cell.weekdayColumn) ? letters[cell.weekdayColumn] : "·")
                            .folioText(.footnote)
                            .foregroundStyle(FolioChrome.Palette.muted)
                        Rectangle()
                            .fill(cellFill(cell))
                            .frame(maxWidth: .infinity)
                            .frame(height: FolioChrome.space(3))
                            .overlay {
                                Rectangle().stroke(
                                    cell.isToday || selectedDay == cell.dayOfYear
                                        ? FolioChrome.Palette.accent
                                        : FolioChrome.Palette.ink.opacity(0.18),
                                    lineWidth: cell.isToday ? 2 : 1
                                )
                            }
                    }
                    .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(cell.isFuture)
                .accessibilityLabel(weekLabel(cell))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("This week")
    }

    private func cellFill(_ cell: FolioGridCell) -> Color {
        if cell.painted {
            return Color(red: cell.red, green: cell.green, blue: cell.blue)
        }
        return FolioChrome.Palette.surface
    }

    private func weekLabel(_ cell: FolioGridCell) -> String {
        var parts = [FolioFigures.integer(cell.dayOfMonth), cell.spokenName]
        if cell.isToday { parts.append("today") }
        return parts.joined(separator: ", ")
    }
}
