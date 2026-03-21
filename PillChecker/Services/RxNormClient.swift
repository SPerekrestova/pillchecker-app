import Foundation

final class RxNormClient: Sendable {
    private let baseURL = "https://rxnav.nlm.nih.gov/REST"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func suggest(query: String) async -> [String] {
        (try? await suggestThrowing(query: query)) ?? []
    }

    func suggestThrowing(query: String) async throws -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        guard let url = URL(string: "\(baseURL)/approximateTerm.json?term=\(encoded)&maxEntries=5") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let group = json?["approximateGroup"] as? [String: Any]
        let candidates = group?["candidate"] as? [[String: Any]] ?? []

        var rxcuis: [String] = []
        var seen = Set<String>()
        for candidate in candidates {
            if let rxcui = candidate["rxcui"] as? String, !seen.contains(rxcui) {
                seen.insert(rxcui)
                rxcuis.append(rxcui)
            }
        }

        let names = await withTaskGroup(of: (Int, String?).self) { group in
            for (i, rxcui) in rxcuis.enumerated() {
                group.addTask { (i, await self.resolveName(rxcui: rxcui)) }
            }
            var ordered = [String?](repeating: nil, count: rxcuis.count)
            for await (i, name) in group { ordered[i] = name }
            return ordered.compactMap { $0 }
        }

        return names
    }

    private func resolveName(rxcui: String) async -> String? {
        do {
            guard let url = URL(string: "\(baseURL)/rxcui/\(rxcui)/properties.json") else {
                return nil
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, _) = try await session.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let properties = json?["properties"] as? [String: Any]
            return properties?["name"] as? String
        } catch {
            return nil
        }
    }
}
