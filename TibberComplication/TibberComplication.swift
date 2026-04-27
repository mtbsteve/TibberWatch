import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct TibberPriceEntry: TimelineEntry {
    let date: Date
    let price: Double
    let level: PriceLevel
    let hasData: Bool
}

// MARK: - Provider
struct TibberPriceProvider: TimelineProvider {

    func placeholder(in context: Context) -> TibberPriceEntry {
        TibberPriceEntry(date: Date(), price: 0.32, level: .normal, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TibberPriceEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TibberPriceEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 15 minutes to match price slot resolution
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> TibberPriceEntry {
        // ⚠️ Replace this suite name with your actual App Group identifier.
        // It must EXACTLY match the value in Signing & Capabilities for both targets.
        let suiteName = "group.com.stephan.tibberwatch"

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ Complication: failed to open UserDefaults suite '\(suiteName)' — check App Group setup")
            return TibberPriceEntry(date: Date(), price: 0, level: .normal, hasData: false)
        }

        let price = defaults.double(forKey: "complication_price")
        let levelRaw = defaults.string(forKey: "complication_level") ?? ""
        let updated = defaults.object(forKey: "complication_updated") as? Date

        //print("🧩 Complication read — price: \(price), level: '\(levelRaw)', updated: \(updated?.description ?? "nil")")

        let level = PriceLevel(rawValue: levelRaw) ?? .normal
        let hasData = price > 0
        return TibberPriceEntry(
            date: Date(),
            price: price,
            level: level,
            hasData: hasData
        )
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
                Text("€/kWh")
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
                     ? "Tibber  \(String(format: "%.2f", entry.price)) €"
                     : "Tibber  -- €")
            }
    }

    // MARK: Inline
    private var inlineView: some View {
        Text(entry.hasData ? "⚡ \(String(format: "%.3f", entry.price)) €/kWh" : "⚡ -- €")
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
                    Text("€/kWh")
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
