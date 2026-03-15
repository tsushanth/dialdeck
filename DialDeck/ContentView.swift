//
//  ContentView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @AppStorage("com.appfactory.dialdeck.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case prospects = "person.2.fill"
        case scripts = "doc.text.fill"
        case metrics = "chart.bar.fill"
        case settings = "gearshape.fill"

        var title: String {
            switch self {
            case .home: return "Home"
            case .prospects: return "Prospects"
            case .scripts: return "Scripts"
            case .metrics: return "Metrics"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label(Tab.home.title, systemImage: Tab.home.rawValue)
                    }
                    .tag(Tab.home)

                ProspectsView()
                    .tabItem {
                        Label(Tab.prospects.title, systemImage: Tab.prospects.rawValue)
                    }
                    .tag(Tab.prospects)

                ScriptsView()
                    .tabItem {
                        Label(Tab.scripts.title, systemImage: Tab.scripts.rawValue)
                    }
                    .tag(Tab.scripts)

                MetricsView()
                    .tabItem {
                        Label(Tab.metrics.title, systemImage: Tab.metrics.rawValue)
                    }
                    .tag(Tab.metrics)

                SettingsView()
                    .tabItem {
                        Label(Tab.settings.title, systemImage: Tab.settings.rawValue)
                    }
                    .tag(Tab.settings)
            }
            .accentColor(.blue)
        }
    }
}

#Preview {
    ContentView()
        .environment(PremiumManager())
}
