import Foundation

public enum STError: LocalizedError {
    case notConfigured
    case productsNotLoaded
    case productNotFound(String)
    case purchaseCancelled
    case entitlementNotFound(String)
    case networkError(Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "SubTrack SDK is not configured. Call SubTrack.configure() first."
        case .productsNotLoaded:
            return "Products could not be loaded."
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .entitlementNotFound(let key):
            return "Entitlement not found: \(key)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
