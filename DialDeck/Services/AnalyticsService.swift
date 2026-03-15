//
//  AnalyticsService.swift
//  DialDeck
//
//  Firebase Analytics + Facebook SDK integration (placeholder)
//

import Foundation
import AppTrackingTransparency

// MARK: - Analytics Event
enum AnalyticsEvent {
    case appOpen
    case onboardingCompleted
    case signUp(method: String)
    case prospectAdded
    case callLogged(outcome: String)
    case scriptCreated
    case scriptUsed
    case objectionViewed(category: String)
    case followUpCreated
    case followUpCompleted
    case metricsViewed
    case exportGenerated
    case paywallViewed(source: String)
    case purchaseStarted(productID: String)
    case purchaseCompleted(productID: String)
    case purchaseFailed(productID: String)
    case dailyGoalReached
    case streakUpdated(days: Int)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingCompleted: return "onboarding_completed"
        case .signUp: return "sign_up"
        case .prospectAdded: return "prospect_added"
        case .callLogged: return "call_logged"
        case .scriptCreated: return "script_created"
        case .scriptUsed: return "script_used"
        case .objectionViewed: return "objection_viewed"
        case .followUpCreated: return "follow_up_created"
        case .followUpCompleted: return "follow_up_completed"
        case .metricsViewed: return "metrics_viewed"
        case .exportGenerated: return "export_generated"
        case .paywallViewed: return "paywall_viewed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .dailyGoalReached: return "daily_goal_reached"
        case .streakUpdated: return "streak_updated"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .signUp(let method): return ["method": method]
        case .callLogged(let outcome): return ["outcome": outcome]
        case .objectionViewed(let category): return ["category": category]
        case .paywallViewed(let source): return ["source": source]
        case .purchaseStarted(let id): return ["product_id": id]
        case .purchaseCompleted(let id): return ["product_id": id]
        case .purchaseFailed(let id): return ["product_id": id]
        case .streakUpdated(let days): return ["days": days]
        default: return [:]
        }
    }
}

// MARK: - Analytics Service
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private var isInitialized = false

    private init() {}

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        // Firebase.configure() would go here
        // Analytics.setAnalyticsCollectionEnabled(true)
        print("[Analytics] Initialized")
    }

    func track(_ event: AnalyticsEvent) {
        guard isInitialized else { return }
        // Analytics.logEvent(event.name, parameters: event.parameters)
        #if DEBUG
        print("[Analytics] Event: \(event.name) params: \(event.parameters)")
        #endif
    }

    func setUserProperty(_ value: String?, forName name: String) {
        // Analytics.setUserProperty(value, forName: name)
    }

    func setUserID(_ id: String?) {
        // Analytics.setUserID(id)
    }
}

// MARK: - ATT Service
@MainActor
final class ATTService {
    static let shared = ATTService()
    private init() {}

    var trackingStatus: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    func requestIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else { return status }
        return await ATTrackingManager.requestTrackingAuthorization()
    }
}

// MARK: - Attribution Manager
@MainActor
final class AttributionManager {
    static let shared = AttributionManager()
    private let attributionRequestedKey = "com.appfactory.dialdeck.attributionRequested"
    private init() {}

    func requestAttributionIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: attributionRequestedKey) else { return }
        UserDefaults.standard.set(true, forKey: attributionRequestedKey)
        // Apple Search Ads attribution via AdServices
        // let token = try? AAAttribution.attributionToken()
        // Send token to backend for attribution
        #if DEBUG
        print("[Attribution] Attribution token requested")
        #endif
    }
}
