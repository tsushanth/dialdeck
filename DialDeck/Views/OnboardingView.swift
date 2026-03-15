//
//  OnboardingView.swift
//  DialDeck
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "phone.fill",
            iconColor: .blue,
            title: "Welcome to DialDeck",
            subtitle: "The modern cold calling app built for sales professionals who want to close more deals.",
            backgroundGradient: [.blue, .purple]
        ),
        OnboardingPage(
            icon: "person.2.fill",
            iconColor: .green,
            title: "Manage Your Pipeline",
            subtitle: "Track every prospect, log every call, and never let a hot lead fall through the cracks.",
            backgroundGradient: [.green, .teal]
        ),
        OnboardingPage(
            icon: "doc.text.fill",
            iconColor: .orange,
            title: "Proven Call Scripts",
            subtitle: "Use battle-tested scripts or create your own. Handle objections like a pro with our built-in guide.",
            backgroundGradient: [.orange, .red]
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: .purple,
            title: "Track Your Performance",
            subtitle: "See your connection rate, call streaks, and conversion metrics. Know exactly what's working.",
            backgroundGradient: [.purple, .blue]
        ),
        OnboardingPage(
            icon: "crown.fill",
            iconColor: .yellow,
            title: "Ready to Dominate?",
            subtitle: "Join thousands of sales pros using DialDeck to crush their quotas every month.",
            backgroundGradient: [.yellow, .orange]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].backgroundGradient.map { $0.opacity(0.15) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == currentPage ? Color.blue : Color.gray.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Action buttons
                VStack(spacing: 12) {
                    if currentPage == pages.count - 1 {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("Try Pro Free")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                        }

                        Button("Start for Free") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    } else {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            HStack {
                                Text("Next")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: showPaywall) { _, isShowing in
            if !isShowing { completeOnboarding() }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        AnalyticsService.shared.track(.onboardingCompleted)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let backgroundGradient: [Color]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.backgroundGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(PremiumManager())
}
