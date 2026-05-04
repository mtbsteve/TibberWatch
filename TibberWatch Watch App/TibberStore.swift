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

    // Last real token entered, kept even after clearToken so the setup view can pre-fill it.
    @AppStorage("tibber_last_token") var lastEnteredToken: String = ""

    // MARK: - Auto-refresh
    private var refreshTask: Task<Void, Never>?
    /// The calendar day (yyyy-MM-dd in local time) that the currently cached `priceData.today` represents.
    private var cachedDataDay: String?

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
            cachedDataDay = Self.todayKey()
            isLoading = false
            saveComplicationData()
            startAutoRefresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            refreshTask?.cancel()
        }
    }

    /// Call when the view appears or the watch wakes — checks if the calendar day
    /// has changed since the last fetch. If so, reset to "Today" view and fetch fresh data.
    func checkForDayRollover() {
        let now = Self.todayKey()
        guard let cached = cachedDataDay else { return }
        if cached != now {
            print("🌅 Day rollover detected: cached=\(cached), now=\(now). Resetting view and refetching.")
            // Reset to Today view — yesterday's "tomorrow" is now today, but our cached
            // tomorrow array is for the wrong day, so we need fresh data anyway.
            showTomorrow = false
            // Mark cache as stale so we don't re-trigger this every appear
            cachedDataDay = now
            Task { await fetchPrices() }
        }
    }

    func clearToken() {
        refreshTask?.cancel()
        apiToken = ""
        priceData = nil
        error = nil
        isLoading = false
        cachedDataDay = nil
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000)
                if !Task.isCancelled {
                    // On every refresh, also check for day rollover
                    if let cached = cachedDataDay, cached != Self.todayKey() {
                        await MainActor.run {
                            print("🌅 Auto-refresh detected day rollover")
                            showTomorrow = false
                        }
                    }
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

    // MARK: - Day key helper
    /// Returns yyyy-MM-dd in the user's local time zone for the current moment.
    private static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Complication data sharing
    /// Shared App Group suite name — must match the value in Signing & Capabilities
    /// for BOTH the Watch App target and the Complication target.
    private static let appGroupID = "group.com.mtbsteve.tibberwatch"

    /// Persist current price + full day arrays so the complication can build its own timeline
    func saveComplicationData() {
        guard let entry = priceData?.currentEntry else {
            print("⚠️ No current entry to save for complication")
            return
        }
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("⚠️ Failed to open UserDefaults suite '\(Self.appGroupID)' — check App Group config")
            return
        }
        defaults.set(entry.total, forKey: "complication_price")
        defaults.set(entry.level.rawValue, forKey: "complication_level")
        defaults.set(priceData?.currency ?? "€/kWh", forKey: "complication_currency")
        defaults.set(Date(), forKey: "complication_updated")

        // Encode full price arrays so the complication can schedule per-slot timeline entries
        let encoder = JSONEncoder()
        if let today = priceData?.today, let data = try? encoder.encode(today) {
            defaults.set(data, forKey: "complication_today_entries")
        }
        if let tomorrow = priceData?.tomorrow, let data = try? encoder.encode(tomorrow) {
            defaults.set(data, forKey: "complication_tomorrow_entries")
        }

        print("✅ Saved complication data: \(entry.total), level: \(entry.level.rawValue), entries: \(priceData?.today.count ?? 0) today / \(priceData?.tomorrow.count ?? 0) tomorrow")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
