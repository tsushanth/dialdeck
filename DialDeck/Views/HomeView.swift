//
//  HomeView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var context
    @Query(sort: \CallMetrics.date, order: .reverse) private var metrics: [CallMetrics]
    @Query(sort: \FollowUp.scheduledDate) private var followUps: [FollowUp]
    @Query(sort: \Prospect.updatedAt, order: .reverse) private var prospects: [Prospect]

    @State private var showPaywall = false
    @State private var showCallSession = false
    @State private var selectedProspectForCall: Prospect? = nil

    private var todayMetrics: CallMetrics? {
        metrics.first { Calendar.current.isDateInToday($0.date) }
    }

    private var overdueFollowUps: [FollowUp] {
        followUps.filter { $0.isOverdue && !$0.isCompleted }
    }

    private var todayFollowUps: [FollowUp] {
        followUps.filter { $0.isDueToday && !$0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily goal progress
                    DailyGoalCard(metrics: todayMetrics)

                    // Quick stats
                    HStack(spacing: 12) {
                        StatMiniCard(title: "Connected", value: "\(todayMetrics?.connectedCalls ?? 0)", icon: "phone.fill", color: .green)
                        StatMiniCard(title: "Voicemails", value: "\(todayMetrics?.voicemails ?? 0)", icon: "voicemail", color: .orange)
                        StatMiniCard(title: "Converted", value: "\(todayMetrics?.conversions ?? 0)", icon: "checkmark.seal.fill", color: .blue)
                    }
                    .padding(.horizontal)

                    // Start calling CTA
                    Button {
                        showCallSession = true
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.title2)
                            Text("Start Calling")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    // Overdue follow-ups
                    if !overdueFollowUps.isEmpty {
                        FollowUpAlertCard(followUps: overdueFollowUps, title: "Overdue Follow-Ups", color: .red)
                    }

                    // Today's follow-ups
                    if !todayFollowUps.isEmpty {
                        FollowUpAlertCard(followUps: todayFollowUps, title: "Due Today", color: .orange)
                    }

                    // Recent prospects
                    if !prospects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recent Prospects")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)

                            ForEach(prospects.prefix(3)) { prospect in
                                ProspectRowCard(prospect: prospect) {
                                    selectedProspectForCall = prospect
                                    showCallSession = true
                                }
                            }
                        }
                    }

                    if !premiumManager.isPremium {
                        PremiumBannerView { showPaywall = true }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("DialDeck")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCallSession) {
                CallSessionView(preselectedProspect: selectedProspectForCall)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Daily Goal Card
struct DailyGoalCard: View {
    let metrics: CallMetrics?

    private var goalCalls: Int { metrics?.goalCalls ?? 50 }
    private var todayCalls: Int { metrics?.totalCalls ?? 0 }
    private var progress: Double { metrics?.goalProgress ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(todayCalls) / \(goalCalls) calls")
                        .font(.title2.bold())
                }
                Spacer()
                CircularProgressView(progress: progress)
                    .frame(width: 56, height: 56)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(progress >= 1.0 ? .green : .blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Circular Progress
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 1.0 ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
        }
    }
}

// MARK: - Follow Up Alert Card
struct FollowUpAlertCard: View {
    let followUps: [FollowUp]
    let title: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundColor(color)
                .padding(.horizontal)

            ForEach(followUps.prefix(3)) { followUp in
                HStack {
                    Image(systemName: followUp.type.icon)
                        .foregroundColor(color)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(followUp.prospect?.fullName ?? "Unknown")
                            .font(.subheadline.bold())
                        Text(followUp.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(followUp.scheduledDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Prospect Row Card
struct ProspectRowCard: View {
    let prospect: Prospect
    let onCallTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .overlay(Text(prospect.initials).font(.callout.bold()).foregroundColor(.blue))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(prospect.fullName)
                    .font(.subheadline.bold())
                Text(prospect.company)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(status: prospect.status)

            Button(action: onCallTap) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ProspectStatus

    var color: Color {
        switch status {
        case .new: return .blue
        case .contacted: return .orange
        case .interested: return .green
        case .notInterested: return .red
        case .followUp: return .purple
        case .converted: return .teal
        case .doNotCall: return .gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }
}

// MARK: - Premium Banner
struct PremiumBannerView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to DialDeck Pro")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("Unlimited prospects, CRM sync & advanced analytics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .environment(PremiumManager())
        .modelContainer(for: [CallMetrics.self, FollowUp.self, Prospect.self], inMemory: true)
}
