import SwiftUI
import UIKit

/// Role: Year document. Projection the representable reads. Owns none of the year.
struct FolioGridCell: Sendable, Equatable {
    var dayOfYear: Int
    var painted: Bool
    var red: Double
    var green: Double
    var blue: Double
    var spokenName: String
    var isToday: Bool
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
            let name: String
            if let stroke, folio.palette.indices.contains(stroke.toneIndex) {
                name = folio.palette[stroke.toneIndex].spokenName
            } else {
                name = "Blank"
            }
            cells.append(
                FolioGridCell(
                    dayOfYear: day,
                    painted: stroke != nil,
                    red: stroke?.wash.red ?? 0,
                    green: stroke?.wash.green ?? 0,
                    blue: stroke?.wash.blue ?? 0,
                    spokenName: name,
                    isToday: day == todayOrdinal && yearNow == folio.year
                )
            )
        }
        return FolioGridFrame(year: folio.year, days: days, today: todayOrdinal, cells: cells)
    }
}

enum FolioYearMetrics {
    static let target: CGFloat = 18
    static let spacing: CGFloat = 2
    static let inset: CGFloat = 1

    static func columns(width: CGFloat) -> Int {
        min(21, max(7, Int((max(width, 1) + spacing) / (target + spacing))))
    }

    static func side(width: CGFloat) -> CGFloat {
        max(width, 1) / CGFloat(columns(width: width))
    }
}

/// Role: Year document. SwiftUI year grid so snapshots flatten the 365-day board.
struct FolioYearBoard: View {
    var frame: FolioGridFrame
    var onSelectToday: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let columns = FolioYearMetrics.columns(width: width)
            let side = FolioYearMetrics.side(width: width)
            let inset = FolioYearMetrics.inset
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for (index, cell) in frame.cells.enumerated() {
                        let col = CGFloat(index % columns)
                        let row = CGFloat(index / columns)
                        let rect = CGRect(
                            x: col * side + inset,
                            y: row * side + inset,
                            width: max(side - inset * 2, 1),
                            height: max(side - inset * 2, 1)
                        )
                        let fill = cell.painted
                            ? Color(red: cell.red, green: cell.green, blue: cell.blue)
                            : FolioChrome.Palette.surface
                        context.fill(Path(rect), with: .color(fill))
                        context.stroke(
                            Path(rect),
                            with: .color(FolioChrome.Palette.ink.opacity(0.42)),
                            lineWidth: 1
                        )
                        if cell.isToday {
                            context.stroke(
                                Path(rect.insetBy(dx: 1, dy: 1)),
                                with: .color(FolioChrome.Palette.accent),
                                lineWidth: 1.5
                            )
                        }
                    }
                }
                if let today = frame.cells.first(where: \.isToday) {
                    let index = max(0, today.dayOfYear - 1)
                    let col = CGFloat(index % columns)
                    let row = CGFloat(index / columns)
                    Button(action: onSelectToday) {
                        Color.clear
                            .frame(
                                width: max(FolioChrome.tap, side),
                                height: max(FolioChrome.tap, side)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: col * side + side / 2, y: row * side + side / 2)
                    .accessibilityLabel(
                        "Day \(FolioFigures.integer(today.dayOfYear)), \(today.spokenName), today"
                    )
                    .accessibilityHint("Opens the tone well")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("folio.year")
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
        accessibilityHint = cell.isToday ? "Opens the tone well" : nil
        setNeedsLayout()
    }
}
