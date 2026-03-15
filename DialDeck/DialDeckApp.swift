//
//  DialDeckApp.swift
//  DialDeck
//
//  Main app entry point with SwiftData, StoreKit 2, and SDK integrations
//

import SwiftUI
import SwiftData
import AppTrackingTransparency
import AdServices

@main
struct DialDeckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var premiumManager = PremiumManager()

    init() {
        do {
            let schema = Schema([
                Prospect.self,
                CallLog.self,
                CallScript.self,
                Objection.self,
                FollowUp.self,
                CallMetrics.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        ReviewManager.shared.recordAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(premiumManager)
                .onAppear {
                    Task {
                        await premiumManager.refreshPremiumStatus()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Analytics
        Task { @MainActor in
            AnalyticsService.shared.initialize()
            AnalyticsService.shared.track(.appOpen)
        }

        // Request ATT permission
        Task { @MainActor in
            _ = await ATTService.shared.requestIfNeeded()
            await AttributionManager.shared.requestAttributionIfNeeded()
        }

        return true
    }
}

// MARK: - Premium Manager
@MainActor
@Observable
final class PremiumManager {
    private(set) var isPremium: Bool = false
    private let storeKit = StoreKitManager()

    var storeKitManager: StoreKitManager { storeKit }

    func refreshPremiumStatus() async {
        await storeKit.updatePurchasedProducts()
        isPremium = storeKit.isPremium
    }
}

// MARK: - Review Manager
final class ReviewManager {
    static let shared = ReviewManager()
    private let launchCountKey = "com.appfactory.dialdeck.launchCount"

    private init() {}

    func recordAppLaunch() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey) + 1
        UserDefaults.standard.set(count, forKey: launchCountKey)
    }

    var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }
}
