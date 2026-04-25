import Foundation

// MARK: - Price Level
enum PriceLevel: String, Codable {
    case veryCheap     = "VERY_CHEAP"
    case cheap         = "CHEAP"
    case normal        = "NORMAL"
    case expensive     = "EXPENSIVE"
    case veryExpensive = "VERY_EXPENSIVE"
}

// MARK: - Price Entry
struct PriceEntry: Identifiable, Codable {
    let id = UUID()
    let total: Double
    let energy: Double
    let tax: Double
    let startsAt: Date
    let level: PriceLevel

    enum CodingKeys: String, CodingKey {
        case total, energy, tax, startsAt, level
    }

    var hour: Int {
        Calendar.current.component(.hour, from: startsAt)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: startsAt)
    }

    /// True if 'now' falls within this 15-min slot
    var isCurrentHour: Bool {
        let now = Date()
        return now >= startsAt && now < startsAt.addingTimeInterval(15 * 60)
    }

    var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - GraphQL Response Models
struct TibberResponse: Codable {
    let data: TibberData?
    let errors: [TibberAPIError]?
}

struct TibberAPIError: Codable {
    let message: String
}

struct TibberData: Codable {
    let viewer: TibberViewer
}

struct TibberViewer: Codable {
    let homes: [TibberHome]
}

struct TibberHome: Codable {
    let id: String
    let currentSubscription: TibberSubscription?
}

struct TibberSubscription: Codable {
    let priceInfo: TibberPriceInfo
}

struct TibberPriceInfo: Codable {
    let current: RawPriceEntry?
    let today: [RawPriceEntry]
    let tomorrow: [RawPriceEntry]
}

struct RawPriceEntry: Codable {
    let total: Double
    let energy: Double
    let tax: Double
    let startsAt: String
    let level: PriceLevel

    func toPriceEntry() -> PriceEntry? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: startsAt) {
            return PriceEntry(total: total, energy: energy, tax: tax, startsAt: date, level: level)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: startsAt) {
            return PriceEntry(total: total, energy: energy, tax: tax, startsAt: date, level: level)
        }
        print("⚠️ Failed to parse date: \(startsAt)")
        return nil
    }
}

// MARK: - App State
struct PriceData {
    var today: [PriceEntry]
    var tomorrow: [PriceEntry]
    var currency: String
    var homeName: String

    /// Stats for an explicit set of entries (used for the day currently displayed)
    static func minPrice(of entries: [PriceEntry]) -> Double {
        entries.map(\.total).min() ?? 0
    }
    static func maxPrice(of entries: [PriceEntry]) -> Double {
        entries.map(\.total).max() ?? 1
    }
    static func avgPrice(of entries: [PriceEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.total).reduce(0, +) / Double(entries.count)
    }

    var currentEntry: PriceEntry? { today.first(where: \.isCurrentHour) }
}
