import Foundation

/// Role: Wash. One contiguous painted run. Analytics read lengths, not a journal of chips.
struct WashRun: Hashable, Sendable, Equatable {
    var startDayOfYear: Int
    var length: Int
}

/// Role: Wash. Census of wash-runs. A gap ends the run; no broken-run theatre.
enum WashCensus {
    static func runs(in dayOfYears: Set<Int>) -> [WashRun] {
        let sorted = dayOfYears.sorted()
        var result: [WashRun] = []
        var index = 0
        while index < sorted.count {
            let start = sorted[index]
            var length = 1
            var expected = start + 1
            index += 1
            while index < sorted.count, sorted[index] == expected {
                length += 1
                expected += 1
                index += 1
            }
            result.append(WashRun(startDayOfYear: start, length: length))
        }
        return result
    }
}
