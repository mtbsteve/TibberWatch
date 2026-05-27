# EnergyPriceInfo — watchOS App

A standalone watchOS app that displays Tibber electricity prices per kWh as a 15-minute resolution bar chart, with a watch face complication showing the current price.

> **Disclaimer.** EnergyPriceInfo is an independent third-party app. It is **not affiliated
> with, endorsed by, or sponsored by** Tibber AS. "Tibber" is a trademark of Tibber AS;
> the name is used here only to describe the third-party API the app reads price data
> from.

**Datenschutz / Privacy policy:** <https://mtbsteve.github.io/TibberWatch/Datenschutzrichtlinie.html>
([Markdown source](Datenschutzrichtlinie.md))

---

## App description

EnergyPriceInfo lets Tibber customers see exactly when electricity will be cheapest
today and tomorrow, directly on their Apple Watch. No iPhone required, no companion
app, no account beyond your existing Tibber subscription.

The main screen shows a 96-bar chart at quarter-hourly resolution (the same resolution
Tibber publishes via its day-ahead price feed), color-coded by Tibber's price-level
classification — `VERY_CHEAP`, `CHEAP`, `NORMAL`, `EXPENSIVE`, `VERY_EXPENSIVE`. A
current-price card at the bottom shows the live 15-minute slot, and a stats row gives
you Min / Avg / Max for the day on screen. Once tomorrow's prices clear (typically
early afternoon CET), a toggle appears so you can plan ahead — schedule the dishwasher,
charge the EV, run the heat pump — for the cheapest window.

A watch-face complication keeps the current price (with its color level) on your wrist
without launching the app. Tap it to open the full chart. The complication updates
automatically every 15 minutes in sync with the Tibber slot boundaries.

The app supports multiple Tibber currencies out of the box (EUR, GBP, NOK, SEK, DKK)
and includes a built-in **Demo Mode** that loads sample data so you can preview the UI
without a Tibber account.

**Privacy.** EnergyPriceInfo sends nothing to any server other than Tibber itself, has no
analytics, no tracking, no third-party SDKs, and no advertising. Your Personal Access
Token stays on your Apple Watch in the app's sandboxed `UserDefaults`.

---

## Features

- 📊 **96-bar chart** at 15-minute resolution (`QUARTER_HOURLY`)
- 👆 **Interactive chart scrubbing** — swipe across the chart to inspect any 15-min slot; the info card updates to show that slot's price and level, with a light haptic click as you cross each bar. The indicator snaps back to "now" when you reopen the app or tap refresh.
- ⚡ **Current price card** — colour-coded by Tibber price level
- 📈 **Min / Avg / Max stats** — scoped to the day being shown (today vs. tomorrow)
- 🕒 **Tomorrow toggle** — when next-day prices become available
- ⌚ **Watch complication** — coloured dot + curved price label along the bezel
- 🌍 **Multi-currency** — displays EUR, GBP, NOK, SEK, DKK automatically from the API
- 🔁 **Auto-refresh** every 15 minutes after a successful fetch
- 🌅 **Day rollover detection** — resets to Today view and refetches when the calendar date changes
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
2. ↺ button refreshes manually (also resets the chart cursor to "now")
3. **Swipe across the chart** to scrub through the day — the info card below the chart updates to show the price + level of the slot under your finger. Reopen the app or tap refresh to snap back to the current time.
4. Scroll for stats and current price
5. Toggle **Show Tomorrow** if next-day prices are published
6. **Change Token** appears on the error screen; **Exit Demo Mode** appears in demo mode

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

Tapping the complication opens the Watch App. The price updates automatically every 15 minutes in sync with the price slot boundaries — no app launch required.

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
        ├── PriceChartView (96 bars + DragGesture → selectedIndex)
        ├── PriceLegendView (00/06/12/18/24)
        ├── PriceMinMaxLabels
        ├── CurrentPriceCard (live "now" OR user-selected slot)
        ├── StatCell × 3 (day-scoped)
        └── Exit Demo Mode (only in demo)

        selectedIndex resets to nil on:
          • day toggle (today ↔ tomorrow)
          • refresh button tap
          • scenePhase → .active (returning from the watch face)
                  ↓
          saveComplicationData()
                  ↓
       UserDefaults(suiteName: "group.com.mtbsteve.tibberwatch")
         complication_price / _level / _currency   ← current slot scalars
         complication_today_entries                 ← JSON [PriceEntry] for today
         complication_tomorrow_entries              ← JSON [PriceEntry] for tomorrow
                  ↑ shared via App Group ↑
       TibberPriceProvider.getTimeline()
         decodes arrays → one TimelineEntry per 15-min slot
         policy: .atEnd  (WidgetKit requests new timeline after last slot)
```

**State**: `TibberStore` (`@MainActor ObservableObject` + `@AppStorage` for token persistence)
**API**: GraphQL POST to `https://api.tibber.com/v1-beta/gql`
**Resolution**: `priceInfo(resolution: QUARTER_HOURLY)` — 96 slots per day
**Currency**: read from API per slot; mapped to display unit (€, £, kr)
**Refresh**: Every 15 minutes after a successful fetch; day rollover also triggers a refetch
**Date parsing**: `ISO8601DateFormatter` with `.withFractionalSeconds` for `2026-04-24T10:00:00.000+02:00`

---

## Notes & gotchas

- **Tibber API Personal Access Tokens are 43 characters** — count yours; if length is wrong, autocorrect interfered
- **`1` (one) vs `I` (capital eye)** — Tibber tokens often contain both; the diagnostic screen helps spot the difference
- **The watch app icon** must be in the Watch App target's `Assets.xcassets`, generated for watchOS sizes (use [appicon.co](https://www.appicon.co))
- **The CFPrefs daemon log** about App Groups (`Couldn't read values in CFPrefsPlistSource…`) is harmless system noise — ignore it
- **Tomorrow's prices** typically appear in the early afternoon (CET) once the day-ahead market clears
- **Watch face tinting** can override custom complication colours — choose the face accordingly
- **After a fresh install**, open the Watch App once to fetch prices and populate the complication timeline; the complication shows `--` until the first successful fetch

---

## Credits

Built with [Tibber's GraphQL API](https://developer.tibber.com/docs/overview). Not affiliated with or endorsed by Tibber.

---

## App Store / TestFlight submission checklist

The repo already contains the artefacts Apple requires; before uploading the first
build, finish the manual steps:

- [ ] **Add the privacy manifests to the Xcode project.** The two
  `PrivacyInfo.xcprivacy` files (one per target) are in the repo but Xcode does not
  auto-pick up new resource files — drag each into the Xcode project navigator and
  tick the matching target's checkbox in **Target Membership**:
  - `TibberWatch Watch App/PrivacyInfo.xcprivacy` → **TibberWatch Watch App** target
  - `TibberComplication/PrivacyInfo.xcprivacy` → **TibberComplication** target
- [ ] **Encryption export compliance** is already declared (`ITSAppUsesNonExemptEncryption = NO`)
  in both target build settings and in `TibberComplication/Info.plist`. App Store
  Connect will skip the export-compliance prompt.
- [ ] **Privacy Policy URL** for App Store Connect:
  `https://mtbsteve.github.io/TibberWatch/Datenschutzrichtlinie.html` — works once
  GitHub Pages is enabled (Settings → Pages → Source: `main` / `/`).
- [ ] **Fill in the placeholders** in `Datenschutzrichtlinie.md` — controller name +
  address + email (DSGVO Art. 13) and the publication date — before flipping Pages on.
- [ ] **App Privacy questionnaire** in App Store Connect: declare *Data Not Collected*
  for every category. The Tibber token leaves your device only when the watch app
  itself talks to Tibber's API; that traffic is between the user's device and Tibber,
  not us.
- [ ] **Bump `CURRENT_PROJECT_VERSION`** before each upload to App Store Connect so
  builds don't collide.
- [ ] **App icon set** completeness — the watchOS asset catalog needs every required
  size; Apple will reject the upload if any are missing. Generate with
  [appicon.co](https://www.appicon.co) or the icon generator of your choice.
- [ ] **Watch-face screenshots** for the App Store listing — at least one per supported
  complication family (`accessoryCircular`, `accessoryCorner`, `accessoryInline`,
  `accessoryRectangular`).

### App Store description (template)

A copy-pasteable description for App Store Connect. Tweak as needed; keep the
trademark disclaimer.

```
EnergyPriceInfo puts your Tibber electricity prices on your wrist. See exactly when
power will be cheapest today and tomorrow — without picking up your phone.

• 96-bar chart at 15-minute resolution, colour-coded by Tibber's price-level
  classification (very cheap → very expensive).
• Current-price card with the live 15-minute slot.
• Min / Avg / Max stats for the day on screen.
• Tomorrow toggle: as soon as the day-ahead market clears, plan the dishwasher,
  the EV, or the heat pump for the cheapest window.
• Interactive chart: swipe across the chart to inspect any 15-min slot of the day.
• Watch-face complication: keeps the current price and colour level on your face;
  refreshes every 15 minutes in sync with Tibber's slot boundaries (always shows
  the live price regardless of what you've explored in the chart).
• Multi-currency: EUR, GBP, NOK, SEK, DKK out of the box.
• Demo Mode: preview the UI without a Tibber account.

Requires a Tibber account and a Personal Access Token from
developer.tibber.com/settings/access-token.

Privacy: no analytics, no tracking, no third-party SDKs, no servers. The app talks
only to Tibber's API directly from your Apple Watch. Your token stays on your
device.

Disclaimer: EnergyPriceInfo is an independent third-party app. It is not affiliated
with, endorsed by, or sponsored by Tibber AS. "Tibber" is a trademark of Tibber AS.
```
