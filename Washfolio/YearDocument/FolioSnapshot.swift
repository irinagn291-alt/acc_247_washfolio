import Foundation

/// Role: Year document. Codable projection of AlmanacFolio. UI never sees this type.
struct FolioSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var year: Int
    var strokes: [DayStroke]
    var palette: [FolioSwatch]
    var bleedAmount: Double
    var onboardingComplete: Bool

    static func empty(year: Int) -> FolioSnapshot {
        FolioSnapshot(
            schemaVersion: FolioCodec.currentSchema,
            year: year,
            strokes: [],
            palette: ToneWell.defaultPalette,
            bleedAmount: ToneWell.defaultBleed,
            onboardingComplete: false
        )
    }
}

/// Role: Year document. Recoverable load outcome. Never crash on a corrupt snapshot.
enum FolioWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Year document. Schema switch and snapshot encode/decode. No UserDefaults.
enum FolioCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ snapshot: FolioSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(normalized(snapshot))
    }

    static func decode(_ data: Data) throws -> FolioSnapshot {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return normalized(try decoder.decode(FolioSnapshot.self, from: data))
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func normalized(_ snapshot: FolioSnapshot) -> FolioSnapshot {
        var next = snapshot
        next.schemaVersion = currentSchema
        var byDay: [Int: DayStroke] = [:]
        for stroke in snapshot.strokes where stroke.year == snapshot.year {
            byDay[stroke.dayOfYear] = stroke
        }
        next.strokes = byDay.values.sorted { $0.dayOfYear < $1.dayOfYear }
        if snapshot.palette.map(\.spokenName) == ToneWell.legacyInkNames {
            next.palette = ToneWell.defaultPalette
        } else if (try? ToneWell.validated(snapshot.palette)) == nil {
            next.palette = ToneWell.defaultPalette
        }
        if (try? ToneWell.settingBleed(snapshot.bleedAmount)) == nil {
            next.bleedAmount = ToneWell.defaultBleed
        }
        return next
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
