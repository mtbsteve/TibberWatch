import SwiftUI

// MARK: - Root
struct ContentView: View {
    @EnvironmentObject var store: TibberStore

    var body: some View {
        Group {
            if !store.hasToken {
                TokenSetupView()
            } else if store.isLoading && store.priceData == nil {
                LoadingView()
            } else if let error = store.error, store.priceData == nil {
                ErrorView(message: error)
            } else if let priceData = store.priceData {
                PriceMainView(priceData: priceData)
            } else {
                LoadingView()
            }
        }
        .task {
            if store.hasToken && store.priceData == nil {
                await store.fetchPrices()
            }
        }
    }
}

// MARK: - Main Price View
struct PriceMainView: View {
    @EnvironmentObject var store: TibberStore
    let priceData: PriceData

    // Computed stats based on the currently displayed day
    private var displayedEntries: [PriceEntry] { store.displayedEntries }
    private var minPrice: Double { PriceData.minPrice(of: displayedEntries) }
    private var maxPrice: Double { PriceData.maxPrice(of: displayedEntries) }
    private var avgPrice: Double { PriceData.avgPrice(of: displayedEntries) }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                headerSection
                chartSection

                PriceLegendView(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    currency: priceData.currency
                )

                PriceMinMaxLabels(
                    minPrice: minPrice,
                    maxPrice: maxPrice
                )

                if let current = priceData.currentEntry {
                    CurrentPriceCard(entry: current, currency: priceData.currency)
                }

                statsRow

                if store.hasTomorrowData {
                    dayToggle
                }

                if let updated = store.lastUpdated {
                    Text("Updated \(updated, style: .relative) ago")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.showTomorrow ? "Tomorrow" : "Today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("Tibber prices")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                Task { await store.fetchPrices() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(store.isLoading ? 360 : 0))
                    .animation(store.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isLoading)
            }
            .buttonStyle(.plain)
        }
    }

    private var chartSection: some View {
        PriceChartView(
            entries: store.displayedEntries,
            minPrice: minPrice,
            maxPrice: maxPrice
        )
        .padding(.vertical, 2)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatCell(label: "Min", value: String(format: "%.2f", minPrice), color: .green)
            Divider().frame(height: 24)
            StatCell(label: "Avg", value: String(format: "%.2f", avgPrice), color: .yellow)
            Divider().frame(height: 24)
            StatCell(label: "Max", value: String(format: "%.2f", maxPrice), color: .red)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var dayToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.showTomorrow.toggle()
            }
        } label: {
            HStack {
                Image(systemName: store.showTomorrow ? "chevron.left" : "chevron.right")
                    .font(.system(size: 9))
                Text(store.showTomorrow ? "Show Today" : "Show Tomorrow")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.blue)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Cell
struct StatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 8)).foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }
}

// MARK: - Current Price Card
struct CurrentPriceCard: View {
    let entry: PriceEntry
    let currency: String

    private var levelText: String {
        switch entry.level {
        case .veryCheap: return "Very Cheap ↓"
        case .cheap: return "Cheap ↓"
        case .normal: return "Normal"
        case .expensive: return "Expensive ↑"
        case .veryExpensive: return "Very High ↑↑"
        }
    }

    private var levelColor: Color {
        switch entry.level {
        case .veryCheap: return .green
        case .cheap: return Color(hue: 0.3, saturation: 0.7, brightness: 0.85)
        case .normal: return .yellow
        case .expensive: return .orange
        case .veryExpensive: return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("NOW")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.3f", entry.total))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(currency)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(levelText)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(levelColor)
                Text(entry.timeLabel)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.07))
        .cornerRadius(9)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(0.8)
            Text("Fetching prices…")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    @EnvironmentObject var store: TibberStore
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 22))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await store.fetchPrices() }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.blue)

            Button("Change Token") {
                store.clearToken()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.orange)
        }
        .padding()
    }
}

// MARK: - Token Setup View
struct TokenSetupView: View {
    @EnvironmentObject var store: TibberStore
    @State private var tokenInput = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)

                Text("Tibber Watch")
                    .font(.system(size: 14, weight: .bold))

                Text("Enter your API token from tibber.com/developer")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("API Token", text: $tokenInput)
                    .font(.system(size: 10))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Save & Connect") {
                    let cleaned = tokenInput
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .controlCharacters).joined()
                        .components(separatedBy: .whitespacesAndNewlines).joined()
                    store.apiToken = cleaned
                    Task { await store.fetchPrices() }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow)
                .cornerRadius(8)
                .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Use Demo Data") {
                    store.apiToken = "demo"
                    store.priceData = DemoData.priceData
                }
                .font(.system(size: 10))
                .foregroundColor(.blue)
            }
            .padding()
        }
    }
}
