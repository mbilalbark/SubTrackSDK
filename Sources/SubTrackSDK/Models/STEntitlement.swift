import Foundation

/// SubTrack entitlement — RevenueCat CustomerInfo karşılığı
public struct STEntitlementInfo {
    public let key: String
    public let isActive: Bool
    public let expiresAt: Date?
    public let productId: String?
}

public struct STCustomerInfo {
    public let userId: String
    public let entitlements: [String: STEntitlementInfo]

    public func isEntitled(_ key: String) -> Bool {
        entitlements[key]?.isActive == true
    }
}
