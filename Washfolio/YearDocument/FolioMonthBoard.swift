import SwiftUI

/// Role: Year document. One large month. Every day is a 44pt mark, not a year chip.
struct FolioMonthBoard: View {
    var frame: FolioGridFrame
    var month: Int
    var selectedDay: Int?
    var focusTone: Int?
    var onSelect: (FolioGridCell) -> Void

    var body: some View {
        let days = frame.cells.filter { $0.month == month }
        let leading = days.first?.weekdayColumn ?? 0
        let letters = FolioFigures.weekdayLetters()
        let slots: [FolioGridCell?] = Array(repeating: nil, count: leading) + days.map { Optional($0) }
        let weekRows = stride(from: 0, to: slots.count, by: 7).map { start in
            Array(slots[start ..< min(start + 7, slots.count)])
        }
        VStack(spacing: FolioChrome.space(1)) {
            HStack(spacing: FolioChrome.space(1)) {
                ForEach(Array(letters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .folioText(.footnote)
                        .foregroundStyle(FolioChrome.Palette.muted)
                        .frame(maxWidth: .infinity, minHeight: FolioChrome.space(3))
                }
            }
            ForEach(Array(weekRows.enumerated()), id: \.offset) { _, week in
                HStack(spacing: FolioChrome.space(1)) {
                    ForEach(0 ..< 7, id: \.self) { column in
                        if week.indices.contains(column), let cell = week[column] {
                            Button {
                                onSelect(cell)
                            } label: {
                                dayCell(cell)
                            }
                            .buttonStyle(.plain)
                            .disabled(cell.isFuture)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel(label(cell))
                            .accessibilityHint(cell.isFuture ? "Still ahead" : "Marks or shows this day")
                            .accessibilityAddTraits(cell.isToday ? .isSelected : [])
                            .accessibilityIdentifier("folio.month.day.\(cell.dayOfMonth)")
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("folio.month")
    }

    private func dayCell(_ cell: FolioGridCell) -> some View {
        let faded = focusTone != nil && cell.painted && cell.toneIndex != focusTone
        let selected = selectedDay == cell.dayOfYear || cell.isToday
        return VStack(spacing: 2) {
            Text(FolioFigures.integer(cell.dayOfMonth))
                .folioText(.title)
                .foregroundStyle(cell.isFuture ? FolioChrome.Palette.muted : FolioChrome.Palette.ink)
            Text(cell.painted ? cell.spokenName : (cell.isFuture ? "—" : "Open"))
                .folioText(.footnote)
                .foregroundStyle(FolioChrome.Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill(cell).opacity(faded ? 0.2 : 1))
        .overlay {
            Rectangle().stroke(
                selected ? FolioChrome.Palette.accent : FolioChrome.Palette.ink.opacity(0.16),
                lineWidth: cell.isToday ? 2 : 1
            )
        }
        .contentShape(Rectangle())
        .opacity(cell.isFuture ? 0.45 : 1)
    }

    private func fill(_ cell: FolioGridCell) -> Color {
        if cell.painted {
            return Color(red: cell.red, green: cell.green, blue: cell.blue)
        }
        return FolioChrome.Palette.surface
    }

    private func label(_ cell: FolioGridCell) -> String {
        var parts = [
            FolioFigures.monthTitle(cell.month),
            FolioFigures.integer(cell.dayOfMonth),
            cell.spokenName,
        ]
        if cell.isToday { parts.append("today") }
        if cell.isFuture { parts.append("ahead") }
        return parts.joined(separator: ", ")
    }
}
