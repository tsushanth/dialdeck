//
//  PaywallView.swift
//  DialDeck
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil
    @State private var showError = false

    private var storeKit: StoreKitManager { premiumManager.storeKitManager }

    let features: [PaywallFeature] = [
        .init(icon: "person.2.fill", title: "Unlimited Prospects", description: "Add as many leads as you need"),
        .init(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Deep insights into your performance"),
        .init(icon: "chart.line.uptrend.xyaxis", title: "Activity Charts", description: "Visual breakdown of your call trends"),
        .init(icon: "square.and.arrow.up", title: "CSV Export", description: "Export all data to spreadsheets"),
        .init(icon: "arrow.2.squarepath", title: "CRM Sync Templates", description: "Salesforce, HubSpot, Pipedrive ready"),
        .init(icon: "person.3.fill", title: "Team Features", description: "Share scripts and metrics with your team"),
        .init(icon: "doc.text.fill", title: "Unlimited Scripts", description: "Create as many call scripts as you need"),
        .init(icon: "bell.badge.fill", title: "Smart Reminders", description: "Never miss a follow-up again"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                        Text("DialDeck Pro")
                            .font(.largeTitle.bold())
                        Text("Close more deals. Make more money.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Features grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(features) { feature in
                            PaywallFeatureCard(feature: feature)
                        }
                    }
                    .padding(.horizontal)

                    // Pricing options
                    VStack(spacing: 12) {
                        if storeKit.isLoading {
                            ProgressView()
                        } else if storeKit.allProducts.isEmpty {
                            Text("Loading pricing...")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(storeKit.allProducts) { product in
                                ProductButton(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onTap: { selectedProduct = product }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Purchase button
                    Button {
                        guard let product = selectedProduct ?? storeKit.allProducts.first else { return }
                        Task { await purchase(product) }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(selectedProduct == nil ? "Start Free Trial" : "Continue")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)

                    // Restore
                    Button("Restore Purchases") {
                        Task { await storeKit.restorePurchases() }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    // Legal
                    Text("Subscriptions auto-renew. Cancel anytime in Settings. By purchasing you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { msg in
                Text(msg)
            }
            .onChange(of: storeKit.purchaseState) { _, newState in
                if case .purchased = newState {
                    Task { await premiumManager.refreshPremiumStatus() }
                    dismiss()
                } else if case .failed(let msg) = newState {
                    errorMessage = msg
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        AnalyticsService.shared.track(.purchaseStarted(productID: product.id))
        do {
            _ = try await storeKit.purchase(product)
            AnalyticsService.shared.track(.purchaseCompleted(productID: product.id))
        } catch {
            if case StoreKitError.userCancelled = error { /* silent */ } else {
                errorMessage = error.localizedDescription
                showError = true
                AnalyticsService.shared.track(.purchaseFailed(productID: product.id))
            }
        }
        isPurchasing = false
    }
}

// MARK: - Paywall Feature
struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct PaywallFeatureCard: View {
    let feature: PaywallFeature

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.caption.bold())
                Text(feature.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Product Button
struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(product.displayName)
                            .font(.subheadline.bold())
                        if product.isPopular {
                            Text("POPULAR")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(6)
                        }
                        if let label = product.savingsLabel {
                            Text(label)
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                        }
                    }
                    Text(product.displayPrice + " " + product.periodLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    PaywallView()
        .environment(PremiumManager())
}
