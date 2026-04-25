import Foundation

// MARK: - Tibber API Service
class TibberAPIService {

    static let endpoint = URL(string: "https://api.tibber.com/v1-beta/gql")!

    // MARK: - GraphQL Query (15-min resolution)
    private static let priceQuery = """
    {
      viewer {
        homes {
          id
          currentSubscription {
            priceInfo(resolution: QUARTER_HOURLY) {
              current {
                total
                energy
                tax
                startsAt
                level
              }
              today {
                total
                energy
                tax
                startsAt
                level
              }
              tomorrow {
                total
                energy
                tax
                startsAt
                level
              }
            }
          }
        }
      }
    }
    """

    static func fetchPrices(apiToken: String) async throws -> PriceData {
        print("🔑 API call with token length: \(apiToken.count)")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("TibberWatch/1.0 watchOS", forHTTPHeaderField: "User-Agent")

        let body = ["query": priceQuery]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TibberError.networkError("Invalid response")
        }

        print("🔌 Tibber HTTP status: \(httpResponse.statusCode)")
        let rawString = String(data: data, encoding: .utf8) ?? "unreadable"
        print("🔌 Tibber raw response: \(rawString.prefix(500))")

        guard httpResponse.statusCode == 200 else {
            throw TibberError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let tibberResponse = try decoder.decode(TibberResponse.self, from: data)

        if let errors = tibberResponse.errors, !errors.isEmpty {
            let msg = errors.first?.message ?? "Unknown API error"
            print("🔌 Tibber API error: \(msg)")
            throw TibberError.apiError(msg)
        }

        guard let homes = tibberResponse.data?.viewer.homes,
              let home = homes.first,
              let priceInfo = home.currentSubscription?.priceInfo else {
            throw TibberError.noData
        }

        let todayEntries = priceInfo.today.compactMap { $0.toPriceEntry() }
        let tomorrowEntries = priceInfo.tomorrow.compactMap { $0.toPriceEntry() }

        print("✅ Got \(todayEntries.count) entries today, \(tomorrowEntries.count) tomorrow")

        return PriceData(
            today: todayEntries,
            tomorrow: tomorrowEntries,
            currency: "€/kWh",
            homeName: "Home"
        )
    }
}

// MARK: - Errors
enum TibberError: LocalizedError {
    case networkError(String)
    case httpError(Int)
    case apiError(String)
    case noData
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .httpError(let code):  return "HTTP \(code) error"
        case .apiError(let msg):    return "API error: \(msg)"
        case .noData:               return "No price data available"
        case .invalidToken:         return "Invalid API token"
        }
    }
}
