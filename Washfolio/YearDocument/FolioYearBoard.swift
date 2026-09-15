import SwiftUI
import UIKit

/// Role: Year document. Projection the representable reads. Owns none of the year.
struct FolioGridCell: Sendable, Equatable {
    var dayOfYear: Int
    var month: Int
    var dayOfMonth: Int
    var weekdayColumn: Int
    var weekRow: Int
    var painted: Bool
    var red: Double
    var green: Double
    var blue: Double
    var spokenName: String
    var toneIndex: Int?
    var isToday: Bool
    var isFuture: Bool
}

/// Role: Year document. One frame of the year grid, projected from AlmanacFolio.
struct FolioGridFrame: Sendable, Equatable {
    var year: Int
    var days: Int
    var today: Int
    var cells: [FolioGridCell]
}

enum FolioGrid {
    @MainActor
    static func frame(from folio: AlmanacFolio, now: Date, calendar: Calendar = .current) -> FolioGridFrame {
        let todayOrdinal = FolioCalendar.dayOfYear(now, calendar: calendar) ?? 1
        let yearNow = FolioCalendar.year(of: now, calendar: calendar)
        let days = folio.daysInYear
        var cells: [FolioGridCell] = []
        cells.reserveCapacity(days)
        for day in 1 ... days {
            let stroke = folio.strokesByDay[day]
            let date = FolioCalendar.date(year: folio.year, dayOfYear: day, calendar: calendar)
            let month = date.map { FolioCalendar.month($0, calendar: calendar) } ?? 1
            let dayOfMonth = date.map { FolioCalendar.dayOfMonth($0, calendar: calendar) } ?? day
            let weekdayColumn = date.map { FolioCalendar.weekdayColumn(of: $0, calendar: calendar) } ?? 0
            let first = FolioCalendar.date(year: folio.year, month: month, day: 1, calendar: calendar)
            let firstColumn = first.map { FolioCalendar.weekdayColumn(of: $0, calendar: calendar) } ?? 0
            let weekRow = (firstColumn + dayOfMonth - 1) / 7
            let name: String
            if let stroke, folio.palette.indices.contains(stroke.toneIndex) {
                name = folio.palette[stroke.toneIndex].spokenName
            } else {
                name = "Blank"
            }
            cells.append(
                FolioGridCell(
                    dayOfYear: day,
                    month: month,
                    dayOfMonth: dayOfMonth,
                    weekdayColumn: weekdayColumn,
                    weekRow: weekRow,
                    painted: stroke != nil,
                    red: stroke?.wash.red ?? 0,
                    green: stroke?.wash.green ?? 0,
                    blue: stroke?.wash.blue ?? 0,
                    spokenName: name,
                    toneIndex: stroke?.toneIndex,
                    isToday: day == todayOrdinal && yearNow == folio.year,
                    isFuture: yearNow == folio.year && day > todayOrdinal
                )
            )
        }
        return FolioGridFrame(year: folio.year, days: days, today: todayOrdinal, cells: cells)
    }
}

/// Role: Year document. Twelve-month almanac metrics so consecutive days sit side by side.
enum FolioYearLayout {
    static let gap: CGFloat = FolioChrome.space(1)
    static let labelHeight: CGFloat = 18
    static let weekHeight: CGFloat = 14
    static let wideWidth: CGFloat = 700

    struct Metrics: Equatable {
        var columns: Int
        var rows: Int
        var monthWidth: CGFloat
        var monthHeight: CGFloat
        var cellWidth: CGFloat
        var cellHeight: CGFloat
        var innerWidth: CGFloat
    }

    static func columns(for width: CGFloat) -> Int {
        width >= wideWidth ? 4 : 3
    }

    static func metrics(in size: CGSize) -> Metrics {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let columns = columns(for: width)
        let rows = Int(ceil(12.0 / Double(columns)))
        let monthWidth = (width - gap * CGFloat(columns - 1)) / CGFloat(columns)
        let monthHeight = (height - gap * CGFloat(rows - 1)) / CGFloat(rows)
        let cellWidth = max(monthWidth / 7, 1)
        let cellHeight = max((monthHeight - labelHeight - weekHeight) / 6, 1)
        return Metrics(
            columns: columns,
            rows: rows,
            monthWidth: monthWidth,
            monthHeight: monthHeight,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            innerWidth: cellWidth * 7
        )
    }

    static func minimumHeight(for width: CGFloat) -> CGFloat {
        let columns = columns(for: width)
        let rows = Int(ceil(12.0 / Double(columns)))
        let cellHeight: CGFloat = 16
        let monthHeight = labelHeight + weekHeight + cellHeight * 6
        return monthHeight * CGFloat(rows) + gap * CGFloat(rows - 1)
    }

    static func monthOrigin(month: Int, metrics: Metrics) -> CGPoint {
        let index = max(0, month - 1)
        let column = index % metrics.columns
        let row = index / metrics.columns
        return CGPoint(
            x: CGFloat(column) * (metrics.monthWidth + gap),
            y: CGFloat(row) * (metrics.monthHeight + gap)
        )
    }

    static func cellRect(_ cell: FolioGridCell, metrics: Metrics) -> CGRect {
        let origin = monthOrigin(month: cell.month, metrics: metrics)
        let pad = (metrics.monthWidth - metrics.innerWidth) / 2
        let inset: CGFloat = 1
        return CGRect(
            x: origin.x + pad + CGFloat(cell.weekdayColumn) * metrics.cellWidth + inset,
            y: origin.y + labelHeight + weekHeight + CGFloat(cell.weekRow) * metrics.cellHeight + inset,
            width: max(metrics.cellWidth - inset * 2, 1),
            height: max(metrics.cellHeight - inset * 2, 1)
        )
    }

    static func hit(at point: CGPoint, cells: [FolioGridCell], metrics: Metrics) -> FolioGridCell? {
        cells.first { cellRect($0, metrics: metrics).insetBy(dx: -1, dy: -1).contains(point) }
    }

    static func monthHeaderRect(month: Int, metrics: Metrics) -> CGRect {
        let origin = monthOrigin(month: month, metrics: metrics)
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: metrics.monthWidth,
            height: max(FolioChrome.tap, labelHeight + weekHeight)
        )
    }

    static func month(at point: CGPoint, metrics: Metrics) -> Int? {
        (1 ... 12).first { month in
            let origin = monthOrigin(month: month, metrics: metrics)
            return CGRect(
                x: origin.x,
                y: origin.y,
                width: metrics.monthWidth,
                height: metrics.monthHeight
            ).contains(point)
        }
    }
}

/// Role: Year document. SwiftUI year grid so snapshots flatten the 365-day board.
struct FolioYearBoard: View {
    var frame: FolioGridFrame
    var selectedDay: Int?
    var focusTone: Int?
    var onSelectToday: () -> Void
    var onInspect: (FolioGridCell) -> Void = { _ in }
    var onOpenMonth: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let fitted = FolioYearLayout.metrics(in: CGSize(width: width, height: max(geo.size.height, 1)))
            if fitted.cellHeight < 14, geo.size.height > 0 {
                let height = FolioYearLayout.minimumHeight(for: width)
                ScrollView {
                    board(metrics: FolioYearLayout.metrics(in: CGSize(width: width, height: height)))
                        .frame(width: width, height: height)
                }
            } else {
                board(metrics: fitted)
                    .frame(width: width, height: max(geo.size.height, 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("folio.year")
    }

    private func board(metrics: FolioYearLayout.Metrics) -> some View {
        let letters = FolioFigures.weekdayLetters()
        return ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for month in 1 ... 12 {
                    drawMonthChrome(month, letters: letters, metrics: metrics, in: &context)
                    drawMonthSlots(month, metrics: metrics, in: &context)
                }
                for cell in frame.cells {
                    drawDay(cell, metrics: metrics, in: &context)
                }
            }
            ForEach(1 ... 12, id: \.self) { month in
                let header = FolioYearLayout.monthHeaderRect(month: month, metrics: metrics)
                Button {
                    onOpenMonth(month)
                } label: {
                    Color.clear
                        .frame(width: header.width, height: header.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: header.midX, y: header.midY)
                .accessibilityLabel(FolioFigures.monthTitle(month))
                .accessibilityHint("Opens this month")
            }
            if let today = frame.cells.first(where: \.isToday) {
                let rect = FolioYearLayout.cellRect(today, metrics: metrics)
                Button(action: onSelectToday) {
                    Color.clear
                        .frame(
                            width: max(FolioChrome.tap, rect.width),
                            height: max(FolioChrome.tap, rect.height)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: rect.midX, y: rect.midY)
                .accessibilityLabel(
                    "Day \(FolioFigures.integer(today.dayOfYear)), \(today.spokenName), today"
                )
                    .accessibilityHint("Opens today's states")
            }
        }
        .contentShape(Rectangle())
        .gesture(
            SpatialTapGesture().onEnded { event in
                if let cell = FolioYearLayout.hit(
                    at: event.location,
                    cells: frame.cells,
                    metrics: metrics
                ) {
                    if cell.isToday {
                        onSelectToday()
                    } else {
                        onInspect(cell)
                    }
                    return
                }
                if let month = FolioYearLayout.month(at: event.location, metrics: metrics) {
                    onOpenMonth(month)
                }
            }
        )
        .accessibilityElement(children: .contain)
        .background {
            ForEach(frame.cells, id: \.dayOfYear) { cell in
                Color.clear
                    .accessibilityElement()
                    .accessibilityLabel(voiceLabel(cell))
                    .accessibilityAddTraits(cell.isToday ? .isButton : [])
                    .accessibilityHint(cell.isToday ? "Opens today's states" : "Shows this day")
                    .accessibilityAction {
                        if cell.isToday {
                            onSelectToday()
                        } else {
                            onInspect(cell)
                        }
                    }
            }
        }
    }

    private func drawMonthChrome(
        _ month: Int,
        letters: [String],
        metrics: FolioYearLayout.Metrics,
        in context: inout GraphicsContext
    ) {
        let origin = FolioYearLayout.monthOrigin(month: month, metrics: metrics)
        let pad = (metrics.monthWidth - metrics.innerWidth) / 2
        context.draw(
            Text(FolioFigures.monthName(month))
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundColor(FolioChrome.Palette.ink),
            at: CGPoint(x: origin.x + pad, y: origin.y + 8),
            anchor: .leading
        )
        for (index, letter) in letters.prefix(7).enumerated() {
            context.draw(
                Text(letter)
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(FolioChrome.Palette.muted),
                at: CGPoint(
                    x: origin.x + pad + CGFloat(index) * metrics.cellWidth + metrics.cellWidth / 2,
                    y: origin.y + FolioYearLayout.labelHeight + FolioYearLayout.weekHeight / 2
                ),
                anchor: .center
            )
        }
    }

    private func drawMonthSlots(
        _ month: Int,
        metrics: FolioYearLayout.Metrics,
        in context: inout GraphicsContext
    ) {
        let slot = FolioGridCell(
            dayOfYear: 0,
            month: month,
            dayOfMonth: 0,
            weekdayColumn: 0,
            weekRow: 0,
            painted: false,
            red: 0,
            green: 0,
            blue: 0,
            spokenName: "Blank",
            toneIndex: nil,
            isToday: false,
            isFuture: true
        )
        for weekRow in 0 ..< 6 {
            for weekdayColumn in 0 ..< 7 {
                var blank = slot
                blank.weekRow = weekRow
                blank.weekdayColumn = weekdayColumn
                let rect = FolioYearLayout.cellRect(blank, metrics: metrics)
                context.fill(
                    Path(rect),
                    with: .color(FolioChrome.Palette.surface.opacity(0.45))
                )
            }
        }
    }

    private func drawDay(_ cell: FolioGridCell, metrics: FolioYearLayout.Metrics, in context: inout GraphicsContext) {
        let rect = FolioYearLayout.cellRect(cell, metrics: metrics)
        let path = Path(rect)
        if cell.painted {
            let faded = focusTone != nil && cell.toneIndex != focusTone
            context.fill(
                path,
                with: .color(
                    Color(red: cell.red, green: cell.green, blue: cell.blue)
                        .opacity(faded ? 0.18 : 1)
                )
            )
        } else {
            let paper = FolioChrome.Palette.surface.opacity(cell.isFuture ? 0.35 : 0.7)
            context.fill(path, with: .color(paper))
        }
        if cell.isToday {
            context.stroke(path, with: .color(FolioChrome.Palette.accent), lineWidth: 2)
        } else if selectedDay == cell.dayOfYear {
            context.stroke(path, with: .color(FolioChrome.Palette.ink), lineWidth: 1.5)
        }
    }

    private func voiceLabel(_ cell: FolioGridCell) -> String {
        var parts = [
            FolioFigures.monthName(cell.month),
            FolioFigures.integer(cell.dayOfMonth),
            cell.spokenName,
        ]
        if cell.isToday {
            parts.append("today")
        }
        return parts.joined(separator: ", ")
    }
}

enum FolioYearPixels {
    static func paper() -> UIColor {
        UIColor(named: "surface") ?? UIColor(red: 232 / 255, green: 217 / 255, blue: 196 / 255, alpha: 1)
    }

    static func hairline() -> UIColor {
        (UIColor(named: "ink") ?? UIColor(red: 26 / 255, green: 21 / 255, blue: 16 / 255, alpha: 1))
            .withAlphaComponent(0.42)
    }
}

final class FolioDayCell: UICollectionViewCell {
    static let reuse = "folio.day"
    private let washLayer = CAShapeLayer()
    private let todayLayer = CAShapeLayer()
    private var expandsHit = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        washLayer.fillColor = FolioYearPixels.paper().cgColor
        washLayer.strokeColor = FolioYearPixels.hairline().cgColor
        washLayer.lineWidth = 1
        todayLayer.fillColor = UIColor.clear.cgColor
        todayLayer.strokeColor = UIColor(named: "accent")?.cgColor
        todayLayer.lineWidth = 1.5
        contentView.layer.addSublayer(washLayer)
        contentView.layer.addSublayer(todayLayer)
        isAccessibilityElement = true
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        clipsToBounds = false
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        washLayer.frame = contentView.bounds
        todayLayer.frame = contentView.bounds
        let rect = contentView.bounds.insetBy(dx: 0.5, dy: 0.5)
        washLayer.path = UIBezierPath(rect: rect).cgPath
        todayLayer.path = UIBezierPath(rect: rect.insetBy(dx: 1, dy: 1)).cgPath
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard expandsHit else { return bounds.contains(point) }
        let padX = max(0, (FolioChrome.tap - bounds.width) / 2)
        let padY = max(0, (FolioChrome.tap - bounds.height) / 2)
        return bounds.insetBy(dx: -padX, dy: -padY).contains(point)
    }

    func apply(_ cell: FolioGridCell) {
        expandsHit = cell.isToday
        if cell.painted {
            washLayer.fillColor = UIColor(red: cell.red, green: cell.green, blue: cell.blue, alpha: 1).cgColor
        } else {
            washLayer.fillColor = FolioYearPixels.paper().cgColor
        }
        washLayer.strokeColor = FolioYearPixels.hairline().cgColor
        washLayer.lineWidth = 1
        todayLayer.isHidden = !cell.isToday
        var label = "Day \(FolioFigures.integer(cell.dayOfYear)), \(cell.spokenName)"
        if cell.isToday {
            label += ", today"
        }
        accessibilityLabel = label
        accessibilityTraits = cell.isToday ? .button : .none
        accessibilityHint = cell.isToday ? "Opens today's states" : nil
        setNeedsLayout()
    }
}
