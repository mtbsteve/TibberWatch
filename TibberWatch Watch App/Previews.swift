import SwiftUI

// MARK: - Previews
#Preview("Main View") {
    let store = TibberStore()
    store.priceData = DemoData.priceData
    store.apiToken = "demo"
    return ContentView()
        .environmentObject(store)
}

#Preview("Loading") {
    let store = TibberStore()
    store.isLoading = true
    store.apiToken = "demo"
    return ContentView()
        .environmentObject(store)
}

#Preview("Setup") {
    let store = TibberStore()
    return ContentView()
        .environmentObject(store)
}

#Preview("Chart Only") {
    let entries = DemoData.priceData.today
    return PriceChartView(
        entries: entries,
        minPrice: entries.map(\.total).min() ?? 0,
        maxPrice: entries.map(\.total).max() ?? 1
    )
    .frame(height: 80)
    .padding()
}
