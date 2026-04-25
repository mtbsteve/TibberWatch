import Foundation

// MARK: - Demo / Preview Data
enum DemoData {

    static var priceData: PriceData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let todayEntries  = makeEntries(from: startOfDay, multiplier: 1.0)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let tomorrowEntries = makeEntries(from: tomorrowStart, multiplier: Double.random(in: 0.9...1.1))

        return PriceData(
            today: todayEntries,
            tomorrow: tomorrowEntries,
            currency: "€/kWh",
            homeName: "Demo Home"
        )
    }

    /// Generate 96 quarter-hourly slots with a smooth daily curve
    private static func makeEntries(from startOfDay: Date, multiplier: Double) -> [PriceEntry] {
        (0..<96).map { slot in
            let date = startOfDay.addingTimeInterval(Double(slot) * 15 * 60)
            let hour = Double(slot) / 4.0  // fractional hour 0.00 ... 23.75
            let price = priceForHour(hour) * multiplier
            return PriceEntry(
                total: price,
                energy: price * 0.65,
                tax: price * 0.35,
                startsAt: date,
                level: levelForPrice(price)
            )
        }
    }

    /// Smooth realistic curve: night low, morning peak, afternoon dip, evening peak
    private static func priceForHour(_ hour: Double) -> Double {
        let base = 0.32
        let morningPeak = 0.14 * gauss(hour, mean: 8.0,  sigma: 1.8)
        let eveningPeak = 0.18 * gauss(hour, mean: 19.0, sigma: 2.2)
        let nightDip    = -0.08 * gauss(hour, mean: 3.0,  sigma: 2.5)
        let noise       = sin(hour * 1.7) * 0.012
        return max(0.18, min(0.58, base + morningPeak + eveningPeak + nightDip + noise))
    }

    private static func gauss(_ x: Double, mean: Double, sigma: Double) -> Double {
        let z = (x - mean) / sigma
        return exp(-0.5 * z * z)
    }

    private static func levelForPrice(_ price: Double) -> PriceLevel {
        switch price {
        case ..<0.24:  return .veryCheap
        case ..<0.30:  return .cheap
        case ..<0.40:  return .normal
        case ..<0.48:  return .expensive
        default:       return .veryExpensive
        }
    }
}
