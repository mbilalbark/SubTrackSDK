import Foundation
import StoreKit

/// SubTrack SDK ana entry point — RevenueCat'teki Purchases karşılığı
public final class SubTrack {

    // MARK: - Shared Instance
    public static var shared: SubTrack {
        guard let instance = _shared else {
            fatalError("SubTrack is not configured. Call SubTrack.configure() first.")
        }
        return instance
    }

    private static var _shared: SubTrack?

    // MARK: - Properties
    let api: SubTrackAPI
    let projectId: String
    public let userId: String

    private init(baseURL: String, apiKey: String, projectId: String, userId: String) {
        self.api = SubTrackAPI(baseURL: baseURL, apiKey: apiKey)
        self.projectId = projectId
        self.userId = userId
    }

    // MARK: - Configure
    /// Uygulamanın başında çağır — AppCreater için:
    /// SubTrack.configure(baseURL: "https://yourserver.com", apiKey: "...", projectId: "...", userId: currentUserId)
    public static func configure(
        baseURL: String,
        apiKey: String,
        projectId: String,
        userId: String
    ) {
        _shared = SubTrack(
            baseURL: baseURL,
            apiKey: apiKey,
            projectId: projectId,
            userId: userId
        )
    }

    // MARK: - Fetch Products
    /// Backend'den product listesini çekip StoreKit ile eşleştirir
    public func fetchProducts() async throws -> [STProduct] {
        let apiProducts = try await api.fetchProducts(projectId: projectId)

        let storeIds = apiProducts.compactMap { $0.storeProductId.isEmpty ? nil : $0.storeProductId }
        guard !storeIds.isEmpty else { return [] }

        let storeProducts = try await Product.products(for: Set(storeIds))
        let storeMap = Dictionary(uniqueKeysWithValues: storeProducts.map { ($0.id, $0) })

        return apiProducts.compactMap { apiProduct in
            guard !apiProduct.storeProductId.isEmpty,
                  let storeProduct = storeMap[apiProduct.storeProductId] else { return nil }
            return STProduct(
                id: apiProduct.id,
                period: apiProduct.period,
                entitlementKey: apiProduct.entitlements.name,
                storeProduct: storeProduct
            )
        }
    }

    // MARK: - Check Entitlement
    /// "premium" gibi bir entitlement key ile kullanıcının erişimi var mı kontrol eder
    public func checkEntitlement(_ key: String) async throws -> Bool {
        let response = try await api.checkEntitlement(
            userId: userId,
            entitlementKey: key,
            projectId: projectId
        )
        return response.entitled
    }

    // MARK: - Purchase
    /// Ürünü satın alır ve backend'e bildirir
    public func purchase(_ product: STProduct) async throws {
        let result = try await product.storeProduct.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let environment = transaction.environment == .xcode || transaction.environment == .sandbox
                ? "sandbox" : "production"

            try await api.validateTransaction(
                userId: userId,
                projectId: projectId,
                transactionId: String(transaction.originalID),
                productId: product.storeProduct.id,
                environment: environment
            )

            await transaction.finish()

        case .userCancelled:
            throw STError.purchaseCancelled

        case .pending:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Restore Purchases
    /// Mevcut transaction'ları backend ile sync eder
    public func restorePurchases() async throws -> Bool {
        var transactionIds: [String] = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                transactionIds.append(String(transaction.originalID))
                await transaction.finish()
            }
        }

        guard !transactionIds.isEmpty else { return false }

        let response = try await api.restoreTransactions(
            userId: userId,
            projectId: projectId,
            transactionIds: transactionIds
        )

        return response?.entitled ?? false
    }

    // MARK: - Private
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw STError.unknown(URLError(.userAuthenticationRequired))
        case .verified(let value):
            return value
        }
    }
}
