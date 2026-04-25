# TibberWatch — watchOS App

A standalone watchOS app that displays Tibber electricity prices per kWh as a 15-minute resolution bar chart.

---

## Features

- 📊 **96-bar chart** at 15-minute resolution (`QUARTER_HOURLY`)
- ⚡ **Current price card** — colour-coded by Tibber price level
- 📈 **Min / Avg / Max stats** — at-a-glance summary
- 🕒 **Tomorrow toggle** — when next-day prices become available
- 🔁 **Auto-refresh** every 30 minutes after a successful fetch
- 🛠 **Token reset** — "Change Token" button on the error screen
- 🎭 **Demo mode** — explore the UI without a Tibber account

---

## Project Setup in Xcode

### 1. Create the Xcode project

1. **File → New → Project → watchOS → App**
2. Set:
   - **Product Name**: `TibberWatch`
   - **Interface**: SwiftUI
   - **Life Cycle**: SwiftUI App
   - Uncheck "Include Notification Scene"
3. Choose a save location and finish

### 2. Add the source files

Delete the auto-generated files and add these to the **Watch App target**:

| File | Description |
|------|-------------|
| `TibberWatchApp.swift` | App entry point |
| `Models.swift` | Data models, GraphQL response types |
| `TibberAPIService.swift` | GraphQL API client (15-min query) |
| `TibberStore.swift` | `ObservableObject` state store |
| `PriceChartView.swift` | 96-bar chart, dynamic widths |
| `ContentView.swift` | All screens & UI |
| `DemoData.swift` | 96 quarter-hourly demo entries |
| `Previews.swift` | SwiftUI Previews |

### 3. Set the deployment target

Set **watchOS Deployment Target** to **watchOS 9.0** or later in the project settings.

### 4. Build & run

- Run on the **watchOS Simulator** (no Apple Developer account needed)
- Or on a real Apple Watch (requires paid Developer account)

---

## Getting your Tibber API token

1. Visit [developer.tibber.com](https://developer.tibber.com/settings/access-token)
2. Log in with your Tibber account
3. Create a **Personal Access Token**
4. Copy it (carefully — long random tokens are easy to mistype) and paste it into the app on first launch

---

## Usage

1. Launch the app on your Apple Watch
2. Enter your Tibber API token, **or** tap **Use Demo Data** to preview
3. Tap the ↺ button in the header to refresh manually
4. Scroll down for stats and the current price card
5. If tomorrow's prices are published, tap **Show Tomorrow** to switch views
6. If the token is wrong, tap **Change Token** on the error screen to start over

---

## Architecture

```
TibberWatchApp
└── ContentView (router)
    ├── TokenSetupView      — first-launch token entry / demo button
    ├── LoadingView         — spinner while fetching
    ├── ErrorView           — error message + Retry / Change Token
    └── PriceMainView       — main screen
        ├── PriceChartView      — 96 bars, dynamic widths
        ├── PriceLegendView     — hour axis (00 / 06 / 12 / 18 / 24)
        ├── PriceMinMaxLabels   — min/max in €/kWh
        ├── CurrentPriceCard    — live price + level
        └── StatCell × 3        — Min / Avg / Max
```

**State**: `TibberStore` (`@MainActor ObservableObject` + `@AppStorage` for token persistence)
**API**: GraphQL POST to `https://api.tibber.com/v1-beta/gql`
**Resolution**: `priceInfo(resolution: QUARTER_HOURLY)` — 96 slots per day
**Refresh**: Automatic every 30 minutes after a successful fetch (cancels on error)
**Date parsing**: `ISO8601DateFormatter` with `withFractionalSeconds` to handle Tibber's `2026-04-24T10:00:00.000+02:00` format

---

## Bar colour key

| Level | Colour |
|-------|--------|
| Very Cheap | 🟢 Green |
| Cheap | 🟢 Yellow-green |
| Normal | 🟡 Amber |
| Expensive | 🟠 Orange-red |
| Very Expensive | 🔴 Red |

---

## Notes

- The API requires a `User-Agent` header — already set in `TibberAPIService`.
- Tibber's documentation recommends caching prices and not querying more than necessary; the 30-minute auto-refresh is conservative for that reason.
- The chart's "current slot" white indicator line lines up with whichever 15-min bar contains `now`.
- Tomorrow's prices typically appear sometime in the early afternoon (CET) once the day-ahead market clears.
