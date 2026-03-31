import Foundation
import StoreKit

/// SubTrack product — RevenueCat Package karşılığı
public struct STProduct {
    public let id: String
    public let period: String          // weekly, monthly, yearly, lifetime
    public let entitlementKey: String  // "premium" gibi
    public let storeProduct: Product   // StoreKit 2 Product

    public var localizedPrice: String {
        storeProduct.displayPrice
    }

    public var priceDecimal: Decimal {
        storeProduct.price
    }
}
