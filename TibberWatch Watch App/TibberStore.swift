import SwiftUI
import Combine
import WidgetKit

// MARK: - Store
@MainActor
class TibberStore: ObservableObject {

    // MARK: - Published State
    @Published var priceData: PriceData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var showTomorrow = false

    // MARK: - Persisted API Token
    @AppStorage("tibber_api_token") var apiToken: String = ""

    // MARK: - Auto-refresh
    private var refreshTask: Task<Void, Never>?

    init() {
        if !apiToken.isEmpty {
            Task { await fetchPrices() }
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func fetchPrices() async {
        guard !apiToken.isEmpty else {
            error = "Please set your Tibber API token"
            return
        }

        isLoading = true
        error = nil

        do {
            let data = try await TibberAPIService.fetchPrices(apiToken: apiToken)
            priceData = data
            lastUpdated = Date()
            isLoading = false
            saveComplicationData()
            startAutoRefresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            refreshTask?.cancel()
        }
    }

    func clearToken() {
        refreshTask?.cancel()
        apiToken = ""
        priceData = nil
        error = nil
        isLoading = false
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000)
                if !Task.isCancelled {
                    await fetchPrices()
                }
            }
        }
    }

    var displayedEntries: [PriceEntry] {
        showTomorrow ? (priceData?.tomorrow ?? []) : (priceData?.today ?? [])
    }

    var hasToken: Bool { !apiToken.isEmpty }
    var hasTomorrowData: Bool { !(priceData?.tomorrow.isEmpty ?? true) }

    // MARK: - Complication data sharing
    /// Persist the current price + level so the complication can read it
    private func saveComplicationData() {
        guard let entry = priceData?.currentEntry else { return }
        let defaults = UserDefaults.standard
        defaults.set(entry.total, forKey: "complication_price")
        defaults.set(entry.level.rawValue, forKey: "complication_level")
        defaults.set(Date(), forKey: "complication_updated")

        // Force widget timeline refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}
