# TibberWatch — watchOS App

A standalone watchOS app that displays Tibber electricity prices per kWh as a 15-minute resolution bar chart, with a watch face complication showing the current price.

---

## Features

- 📊 **96-bar chart** at 15-minute resolution (`QUARTER_HOURLY`)
- ⚡ **Current price card** — colour-coded by Tibber price level
- 📈 **Min / Avg / Max stats** — scoped to the day being shown (today vs. tomorrow)
- 🕒 **Tomorrow toggle** — when next-day prices become available
- ⌚ **Watch complication** — coloured dot + curved price label along the bezel
- 🔁 **Auto-refresh** every 30 minutes after a successful fetch
- 🛠 **Token reset** — "Change Token" button on the error screen, "Exit Demo Mode" in demo
- 💾 **Token pre-fill** — last entered token is remembered and pre-filled on the setup screen
- 🎭 **Demo mode** — explore the UI without a Tibber account
- 🩺 **Built-in token diagnostics** — shows length / first chars / hex bytes on the error screen

---

## Project Setup in Xcode

This is a multi-target project: a Watch App + a Widget Extension (for the complication).

### 1. Watch App target

Add these files to your **Watch App target**:

| File | Description |
|------|-------------|
| `TibberWatchApp.swift` | App entry point |
| `Models.swift` | Data models, `PriceLevel` colours, `Color(hexValue:)` |
| `TibberAPIService.swift` | GraphQL API client (15-min query) |
| `TibberStore.swift` | `ObservableObject` state store, complication data writer |
| `PriceChartView.swift` | 96-bar chart, dynamic widths |
| `ContentView.swift` | All screens & UI |
| `DemoData.swift` | 96 quarter-hourly demo entries |
| `Previews.swift` | SwiftUI Previews |

### 2. Widget Extension target

The complication runs in its own target, mandated by WidgetKit.

1. **File → New → Target → watchOS → Widget Extension**
2. Name it `TibberComplication`
3. **Uncheck** "Include Configuration Intent"
4. Activate the new scheme

Then:

1. **Delete** the auto-generated `.swift` files inside the new `TibberComplication` folder
2. Drag `TibberComplication.swift` into that folder, ticking ONLY the **TibberComplication** target
3. Click `Models.swift` → File Inspector → tick BOTH targets in **Target Membership**
   (do NOT physically duplicate the file — share via target membership only)

### 3. App Group (required for the complication to read price data)

Both targets need the same App Group capability so they can share `UserDefaults`:

1. Project → **Watch App target** → Signing & Capabilities → **+ Capability → App Groups** → create e.g. `group.com.yourname.tibberwatch`
2. Project → **TibberComplication target** → Signing & Capabilities → **+ Capability → App Groups** → tick the SAME group
3. Verify both targets use the **same Team** under Signing — App Groups won't link otherwise
4. Update the suite name in **both** code files to match exactly what you created above:
   - `TibberStore.swift` → `private static let appGroupID = "group.com.yourname.tibberwatch"`
   - `TibberComplication.swift` → `let suiteName = "group.com.yourname.tibberwatch"`

### 4. Embed the Widget Extension in the Watch App

Project → **Watch App target** → **General** → **Frameworks, Libraries, and Embedded Content**:
`TibberComplication.appex` should be listed with **Embed & Sign**. Add it manually if missing — without this step the complication won't appear in the watch face customisation list.

### 5. Deployment target

Set **watchOS Deployment Target** to **watchOS 10.0** or later for the modern complication families.

### 6. Build & run

1. Run the **Watch App scheme** first — let it fetch prices
2. Long-press the watch face → Edit → Customize → tap a complication slot → choose **TibberWatch → Tibber Price**

---

## Getting your Tibber API token

1. Visit [developer.tibber.com](https://developer.tibber.com/settings/access-token)
2. Create a **Personal Access Token**
3. Enter it on the watch — easiest paths:
   - **iCloud Universal Clipboard**: copy on Mac → paste in the iPhone keyboard popup that opens when you tap the watch field
   - **Type carefully** — `1` (one) vs `I` (capital eye) vs `l` (lowercase L) are easy to confuse in the watch font
   - The error screen displays length / first chars / hex bytes for diagnosis if the token is rejected

---

## Usage

1. Launch the app → enter token (or tap **Use Demo Data** to preview)
2. ↺ button refreshes manually
3. Scroll for stats and current price
4. Toggle **Show Tomorrow** if next-day prices are published
5. **Change Token** appears on the error screen; **Exit Demo Mode** appears in demo mode

---

## Complication

The corner complication shows a colour-coded dot and a curved price label along the bezel:

| Level | Dot Colour | Hex |
|-------|-----------|-----|
| Very Cheap | 🟢 Dark green | #006400 |
| Cheap | 🟢 Green | #2ECC40 |
| Normal | 🟡 Yellow | #FFD700 |
| Expensive | 🔴 Red | #FF4136 |
| Very Expensive | 🟥 Dark red | #8B0000 |

Tapping the complication opens the Watch App (built-in WidgetKit behaviour, no code needed).

> **Note:** Some watch faces (e.g., the chronograph face) tint all complications with a single accent colour, overriding the level colour. To see the proper colour-coded dot, use a face that allows full-colour complications: **Modular**, **Modular Compact**, **Infograph Modular**, or **Color**.

The complication supports four families:
- `accessoryCircular` — round badge with price text
- `accessoryCorner` — colour dot + curved bezel label (recommended)
- `accessoryInline` — compact text at the top of the watch face
- `accessoryRectangular` — full bar with colour dot, price, and level

---

## Architecture

```
TibberWatch (Watch App target)              TibberComplication (Widget target)
└── ContentView                             └── TibberPriceComplication (@main)
    ├── TokenSetupView                          ├── TibberPriceProvider
    │   └── pre-fills last entered token        │   └── reads UserDefaults(suiteName:)
    ├── LoadingView                             └── TibberComplicationView
    ├── ErrorView                                   ├── circularView
    │   ├── token diagnostics                       ├── cornerView (dot + curved label)
    │   └── Retry / Change Token                    ├── inlineView
    └── PriceMainView                               └── rectangularView
        ├── PriceChartView (96 bars)
        ├── PriceLegendView (00/06/12/18/24)
        ├── PriceMinMaxLabels
        ├── CurrentPriceCard
        ├── StatCell × 3 (day-scoped)
        └── Exit Demo Mode (only in demo)
                  ↓
          saveComplicationData()
                  ↓
       UserDefaults(suiteName: "group.com.yourname.tibberwatch")
                  ↑ shared via App Group ↑
```

**State**: `TibberStore` (`@MainActor ObservableObject` + `@AppStorage` for token persistence)
**API**: GraphQL POST to `https://api.tibber.com/v1-beta/gql`
**Resolution**: `priceInfo(resolution: QUARTER_HOURLY)` — 96 slots per day
**Refresh**: Every 30 minutes after a successful fetch (cancels on error)
**Date parsing**: `ISO8601DateFormatter` with `.withFractionalSeconds` for `2026-04-24T10:00:00.000+02:00`

---

## Notes & gotchas

- **Tibber API Personal Access Tokens are 43 characters** — count yours; if length is wrong, autocorrect interfered
- **`1` (one) vs `I` (capital eye)** — Tibber tokens often contain both; the diagnostic screen helps spot the difference
- **The watch app icon** must be in the Watch App target's `Assets.xcassets`, generated for watchOS sizes (use [appicon.co](https://www.appicon.co))
- **The CFPrefs daemon log** about App Groups (`Couldn't read values in CFPrefsPlistSource…`) is harmless system noise — ignore it
- **Tomorrow's prices** typically appear in the early afternoon (CET) once the day-ahead market clears
- **Watch face tinting** can override custom complication colours — choose the face accordingly

---

## Credits

Built with [Tibber's GraphQL API](https://developer.tibber.com/docs/overview). Not affiliated with or endorsed by Tibber.
