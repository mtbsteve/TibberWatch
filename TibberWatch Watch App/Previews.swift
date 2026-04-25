import SwiftUI

#Preview("Main View") {
    ContentView()
        .environmentObject({
            let store = TibberStore()
            store.priceData = DemoData.priceData
            store.apiToken = "demo"
            return store
        }())
}

#Preview("Loading") {
    ContentView()
        .environmentObject({
            let store = TibberStore()
            store.isLoading = true
            store.apiToken = "demo"
            return store
        }())
}

#Preview("Setup") {
    ContentView()
        .environmentObject(TibberStore())
}

#Preview("Chart Only") {
    let entries = DemoData.priceData.today
    PriceChartView(
        entries: entries,
        minPrice: entries.map(\.total).min() ?? 0,
        maxPrice: entries.map(\.total).max() ?? 1
    )
    .frame(height: 80)
    .padding()
}
