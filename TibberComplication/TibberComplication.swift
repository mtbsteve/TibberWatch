import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct TibberPriceEntry: TimelineEntry {
    let date: Date
    let price: Double
    let level: PriceLevel
    let currency: String   // e.g. "€/kWh", "kr/kWh"
    let hasData: Bool
}

// MARK: - Provider
struct TibberPriceProvider: TimelineProvider {

    func placeholder(in context: Context) -> TibberPriceEntry {
        TibberPriceEntry(date: Date(), price: 0.32, level: .normal, currency: "€/kWh", hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TibberPriceEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TibberPriceEntry>) -> Void) {
        let suiteName = "group.com.mtbsteve.tibberwatch"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            let fallback = TibberPriceEntry(date: Date(), price: 0, level: .normal, currency: "€/kWh", hasData: false)
            completion(Timeline(entries: [fallback], policy: .after(Date().addingTimeInterval(15 * 60))))
            return
        }

        let currency = defaults.string(forKey: "complication_currency") ?? "€/kWh"
        let decoder = JSONDecoder()
        let now = Date()

        var priceEntries: [PriceEntry] = []
        if let data = defaults.data(forKey: "complication_today_entries"),
           let entries = try? decoder.decode([PriceEntry].self, from: data) {
            priceEntries.append(contentsOf: entries)
        }
        if let data = defaults.data(forKey: "complication_tomorrow_entries"),
           let entries = try? decoder.decode([PriceEntry].self, from: data) {
            priceEntries.append(contentsOf: entries)
        }

        // One timeline entry per 15-min slot; include the currently active slot
        let timelineEntries = priceEntries
            .filter { $0.startsAt >= now.addingTimeInterval(-15 * 60) }
            .sorted { $0.startsAt < $1.startsAt }
            .map { p in
                TibberPriceEntry(date: p.startsAt, price: p.total, level: p.level, currency: currency, hasData: true)
            }

        if timelineEntries.isEmpty {
            // No stored data — fall back to single entry and try again in 15 min
            let fallback = TibberPriceEntry(date: now, price: 0, level: .normal, currency: currency, hasData: false)
            completion(Timeline(entries: [fallback], policy: .after(now.addingTimeInterval(15 * 60))))
        } else {
            // .atEnd asks WidgetKit to call getTimeline again after the last slot expires
            completion(Timeline(entries: timelineEntries, policy: .atEnd))
        }
    }

    private func currentEntry() -> TibberPriceEntry {
        let suiteName = "group.com.mtbsteve.tibberwatch"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return TibberPriceEntry(date: Date(), price: 0, level: .normal, currency: "€/kWh", hasData: false)
        }
        let price = defaults.double(forKey: "complication_price")
        let levelRaw = defaults.string(forKey: "complication_level") ?? ""
        let currency = defaults.string(forKey: "complication_currency") ?? "€/kWh"
        let level = PriceLevel(rawValue: levelRaw) ?? .normal
        return TibberPriceEntry(date: Date(), price: price, level: level, currency: currency, hasData: price > 0)
    }
}

// MARK: - Complication Views
struct TibberComplicationView: View {
    let entry: TibberPriceEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:    circularView
        case .accessoryCorner:      cornerView
        case .accessoryInline:      inlineView
        case .accessoryRectangular: rectangularView
        default:                    circularView
        }
    }

    private var levelColor: Color {
        Color(hexValue: entry.level.displayColorHex)
    }

    private var currencySymbol: String {
        entry.currency.components(separatedBy: "/").first ?? entry.currency
    }

    // MARK: Circular
    private var circularView: some View {
        ZStack {
            Circle()
                .fill(levelColor.opacity(0.25))
            Circle()
                .stroke(levelColor, lineWidth: 2)
            VStack(spacing: 0) {
                Text(entry.hasData ? String(format: "%.2f", entry.price) : "--")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(entry.currency)
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Corner
    /// Corner complication: small color-coded dot + neutral curved label along the bezel
    private var cornerView: some View {
        Circle()
            .fill(levelColor)
            .padding(8)
            .widgetLabel {
                Text(entry.hasData
                     ? "Tibber  \(String(format: "%.2f", entry.price)) \(currencySymbol)"
                     : "Tibber  --")
            }
    }

    // MARK: Inline
    private var inlineView: some View {
        Text(entry.hasData ? "⚡ \(String(format: "%.3f", entry.price)) \(entry.currency)" : "⚡ --")
            .foregroundColor(levelColor)
    }

    // MARK: Rectangular
    private var rectangularView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(levelColor)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(entry.hasData ? String(format: "%.3f", entry.price) : "--")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(entry.currency)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                Text(entry.level.shortLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(levelColor)
            }
        }
    }
}

// MARK: - Widget Definition
@main
struct TibberPriceComplication: Widget {
    let kind = "TibberPriceComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TibberPriceProvider()) { entry in
            TibberComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "tibberwatch://open")!)
        }
        .configurationDisplayName("Tibber Price")
        .description("Current electricity price per kWh")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}
