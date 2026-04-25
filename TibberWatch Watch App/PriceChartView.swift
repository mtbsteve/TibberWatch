import SwiftUI

// MARK: - Price Chart View
struct PriceChartView: View {
    let entries: [PriceEntry]
    let minPrice: Double
    let maxPrice: Double

    private let chartHeight: CGFloat = 70
    private let barSpacing: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let totalSpacing = barSpacing * CGFloat(max(entries.count - 1, 0))
            let availableWidth = geo.size.width - totalSpacing
            let barWidth = entries.isEmpty ? 0 : availableWidth / CGFloat(entries.count)

            ZStack(alignment: .bottom) {
                // Grid lines
                VStack(spacing: 0) {
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                }

                // Bars
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(entries) { entry in
                        BarView(
                            entry: entry,
                            minPrice: minPrice,
                            maxPrice: maxPrice,
                            chartHeight: chartHeight,
                            barWidth: barWidth
                        )
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)

                // Hour ticks at 06, 12, 18 (only useful for 96-slot view)
                hourTicks(geoWidth: geo.size.width, barWidth: barWidth)

                // Current slot indicator
                if let currentIdx = entries.firstIndex(where: \.isCurrentHour) {
                    let xPos = (CGFloat(currentIdx) + 0.5) * (barWidth + barSpacing)

                    Rectangle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 1.5, height: chartHeight + 4)
                        .position(x: xPos, y: chartHeight / 2)
                        .shadow(color: .white.opacity(0.6), radius: 2)
                }
            }
            .frame(height: chartHeight)
        }
        .frame(height: chartHeight)
    }

    @ViewBuilder
    private func hourTicks(geoWidth: CGFloat, barWidth: CGFloat) -> some View {
        if entries.count >= 48 {
            ForEach([24, 48, 72], id: \.self) { idx in
                if idx < entries.count {
                    let xPos = (CGFloat(idx) + 0.5) * (barWidth + barSpacing)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 0.5, height: chartHeight)
                        .position(x: xPos, y: chartHeight / 2)
                }
            }
        }
    }
}

// MARK: - Bar
struct BarView: View {
    let entry: PriceEntry
    let minPrice: Double
    let maxPrice: Double
    let chartHeight: CGFloat
    let barWidth: CGFloat

    private var normalizedHeight: CGFloat {
        let range = maxPrice - minPrice
        guard range > 0 else { return 0.5 }
        let ratio = (entry.total - minPrice) / range
        return CGFloat(max(0.05, ratio)) * chartHeight
    }

    private var barColor: Color {
        switch entry.level {
        case .veryCheap:    return Color(hue: 0.38, saturation: 0.85, brightness: 0.85)
        case .cheap:        return Color(hue: 0.30, saturation: 0.70, brightness: 0.85)
        case .normal:       return Color(hue: 0.15, saturation: 0.65, brightness: 0.90)
        case .expensive:    return Color(hue: 0.06, saturation: 0.80, brightness: 0.90)
        case .veryExpensive: return Color(hue: 0.00, saturation: 0.85, brightness: 0.85)
        }
    }

    var body: some View {
        Rectangle()
            .fill(barColor.opacity(entry.isCurrentHour ? 1.0 : 0.75))
            .frame(width: max(barWidth, 0.5), height: normalizedHeight)
    }
}

// MARK: - Hour axis labels
struct PriceLegendView: View {
    let minPrice: Double
    let maxPrice: Double
    let currency: String

    var body: some View {
        HStack {
            Text("00").font(.system(size: 7)).foregroundColor(.secondary)
            Spacer()
            Text("06").font(.system(size: 7)).foregroundColor(.secondary)
            Spacer()
            Text("12").font(.system(size: 7)).foregroundColor(.secondary)
            Spacer()
            Text("18").font(.system(size: 7)).foregroundColor(.secondary)
            Spacer()
            Text("24").font(.system(size: 7)).foregroundColor(.secondary)
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Min / Max labels
struct PriceMinMaxLabels: View {
    let minPrice: Double
    let maxPrice: Double

    var body: some View {
        HStack {
            Text(String(format: "%.2f", minPrice))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
            Spacer()
            Text(String(format: "%.2f", maxPrice))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.horizontal, 2)
    }
}
