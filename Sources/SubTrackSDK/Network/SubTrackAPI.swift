import Foundation

struct STAPIProduct: Decodable {
    let id: String
    let name: String
    let period: String
    let storeProductId: String
    let entitlements: STAPIEntitlement

    enum CodingKeys: String, CodingKey {
        case id, name, period
        case storeProductId = "store_product_id"
        case entitlements
    }
}

struct STAPIEntitlement: Decodable {
    let name: String
}

struct STAPIEntitlementResponse: Decodable {
    let entitled: Bool
    let expiresAt: String?
    let productId: String?

    enum CodingKeys: String, CodingKey {
        case entitled
        case expiresAt = "expires_at"
        case productId = "product_id"
    }
}

final class SubTrackAPI {
    private let baseURL: String
    private let apiKey: String

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    // MARK: - Fetch Products
    func fetchProducts(projectId: String) async throws -> [STAPIProduct] {
        let url = try makeURL("/api/sdk/products/\(projectId)")
        let data = try await get(url: url)
        return try JSONDecoder().decode([STAPIProduct].self, from: data)
    }

    // MARK: - Check Entitlement
    func checkEntitlement(userId: String, entitlementKey: String, projectId: String) async throws -> STAPIEntitlementResponse {
        let url = try makeURL("/api/sdk/entitlements/\(projectId)/\(userId)/\(entitlementKey)")
        let data = try await get(url: url)
        return try JSONDecoder().decode(STAPIEntitlementResponse.self, from: data)
    }

    // MARK: - Validate Receipt
    func validateTransaction(
        userId: String,
        projectId: String,
        transactionId: String,
        productId: String,
        environment: String
    ) async throws {
        let url = try makeURL("/api/sdk/validate")
        let body: [String: String] = [
            "user_id": userId,
            "project_id": projectId,
            "transaction_id": transactionId,
            "product_id": productId,
            "environment": environment
        ]
        try await post(url: url, body: body)
    }

    // MARK: - Restore
    func restoreTransactions(
        userId: String,
        projectId: String,
        transactionIds: [String]
    ) async throws -> STAPIEntitlementResponse {  // ← ? kaldır
        let url = try makeURL("/api/sdk/restore")
        let body: [String: Any] = [
            "user_id": userId,
            "project_id": projectId,
            "transaction_ids": transactionIds
        ]
        let data = try await postWithResponse(url: url, body: body)
        return try JSONDecoder().decode(STAPIEntitlementResponse.self, from: data)
    }

    // MARK: - Private Helpers
    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw STError.networkError(URLError(.badURL))
        }
        return url
    }

    private func get(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return data
    }

    private func post(url: URL, body: [String: String]) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    private func postWithResponse(url: URL, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return data
    }

   private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw STError.networkError(URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            throw STError.networkError(NSError(domain: "SubTrack", code: http.statusCode, 
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]))
        }
    }
}