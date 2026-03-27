import SwiftUI

struct DashboardView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @State private var selectedSub: Subscription? = nil
    @State private var showSearch = false
    @State private var searchText = ""
    var onSeeAll: (() -> Void)? = nil

    // Search results across all subscriptions
    var searchResults: [Subscription] {
        guard !searchText.isEmpty else { return [] }
        return store.subscriptions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("SubTrack")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.appOnSurface)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appOnSurface)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Search Bar
                if showSearch {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appOutline)
                        TextField(settings.s("搜索订阅...", "Search subscriptions..."), text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(Color.appOnSurface)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.appOutline)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(Color.appSurfaceContainer)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ── Search results mode ──────────────────────────────────
                if showSearch && !searchText.isEmpty {
                    if searchResults.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(Color.appOutline)
                            Text(settings.s("未找到 \(searchText)", "No results for \(searchText)"))
                                .font(.system(size: 15))
                                .foregroundColor(Color.appOnSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(settings.s("搜索结果", "Search Results"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.appOnSurfaceVariant)
                                .padding(.horizontal, 20)
                            ForEach(searchResults) { sub in
                                Button { selectedSub = sub } label: {
                                    SubscriptionRowCard(subscription: sub, settings: settings)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                // ── Normal mode ──────────────────────────────────────────
                } else {
                    // Spending Card
                    SpendingCard(store: store, settings: settings)
                        .padding(.horizontal, 20)

                    // Empty State
                    if store.subscriptions.isEmpty {
                        DashboardEmptyState()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }

                    // Priority Renewals
                    if !store.upcomingRenewals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(settings.priorityRenewalsLabel)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appOnSurface)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(store.upcomingRenewals) { sub in
                                        Button { selectedSub = sub } label: {
                                            RenewalCard(subscription: sub, settings: settings)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Monthly Subscriptions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(settings.monthlySubsLabel)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appOnSurface)
                            Spacer()
                            Button(settings.seeAllLabel) { onSeeAll?() }
                                .font(.system(size: 14))
                                .foregroundColor(Color.appPrimary)
                        }
                        .padding(.horizontal, 20)

                        ForEach(Array(store.subscriptions.filter { $0.status == .active }.prefix(3))) { sub in
                            Button { selectedSub = sub } label: {
                                SubscriptionRowCard(subscription: sub, settings: settings)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer().frame(height: 90)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .sheet(item: $selectedSub) { sub in
            SubscriptionDetailView(subscription: sub)
                .environment(store)
                .environment(settings)
        }
    }
}

// MARK: - Spending Card
struct SpendingCard: View {
    let store: SubscriptionStore
    let settings: AppSettings

    private var isCNY: Bool { settings.currencyDefault == 0 }
    private var displayTotal: Double { isCNY ? store.totalInCNY : store.totalInUSD }
    private var symbol: String { isCNY ? "¥" : "$" }
    private var rateNote: String {
        isCNY
            ? settings.s("含汇率换算 ¥7.25/$1", "Rate: ¥7.25 / $1")
            : settings.s("含汇率换算 $1/¥7.25", "Rate: $1 / ¥7.25")
    }

    // Real last-month total: subs that were already active last month
    private var lastMonthTotal: Double {
        let cal = Calendar.current
        let now = Date()
        guard let lastMonthDate  = cal.date(byAdding: .month, value: -1, to: now),
              let startOfLast    = cal.date(from: cal.dateComponents([.year, .month], from: lastMonthDate)),
              let startOfThis    = cal.date(byAdding: .month, value: 1, to: startOfLast),
              let endOfLast      = cal.date(byAdding: .second, value: -1, to: startOfThis) else {
            return displayTotal
        }
        return store.subscriptions
            .filter { $0.status == .active && $0.startDate <= endOfLast }
            .reduce(0.0) { acc, sub in
                isCNY
                    ? acc + (sub.currency == .cny ? sub.monthlyAmount : sub.monthlyAmount * SubscriptionStore.usdToCnyRate)
                    : acc + (sub.currency == .usd ? sub.monthlyAmount : sub.monthlyAmount / SubscriptionStore.usdToCnyRate)
            }
    }

    private var monthChangePct: Double {
        guard lastMonthTotal > 0 else { return 0 }
        return (displayTotal - lastMonthTotal) / lastMonthTotal * 100
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(settings.monthlySpendingLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .tracking(0.8)
                Text(String(format: "%@%.2f", symbol, displayTotal))
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color.appOnSurface)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(settings.s("预计月支出 · ", "Projected · "))
                    Text(rateNote)
                }
                .font(.system(size: 11))
                .foregroundColor(Color.appOnSurfaceVariant)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.appPrimary.opacity(0.6))
                // Real month-over-month change
                let pct = monthChangePct
                let noData = displayTotal == 0 && lastMonthTotal == 0
                if !noData {
                    let isUp = pct >= 0
                    HStack(spacing: 3) {
                        Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(pct == 0 ? "—" : String(format: "%@%.0f%%", isUp ? "+" : "", pct))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(isUp ? Color.appSecondary : Color(hex: "4CAF50"))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background((isUp ? Color.appSecondary : Color(hex: "4CAF50")).opacity(0.15))
                    .cornerRadius(10)
                    Text(settings.vsLastMonthLabel)
                        .font(.system(size: 11))
                        .foregroundColor(Color.appOnSurfaceVariant)
                }
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Renewal Card
struct RenewalCard: View {
    let subscription: Subscription
    let settings: AppSettings
    @State private var reminderSet = false

    var body: some View {
        HStack(spacing: 12) {
            SubIcon(subscription: subscription, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(settings.billingCycleDisplay(subscription.billingCycle) + " · " +
                     settings.s("\(subscription.daysUntilRenewal)天后到期", "Due in \(subscription.daysUntilRenewal) days"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.appOnSurfaceVariant)
            }
            Spacer()
            Button {
                Task {
                    if reminderSet {
                        NotificationManager.shared.cancelReminder(for: subscription.id)
                        reminderSet = false
                    } else {
                        let granted = await NotificationManager.shared.requestPermission()
                        if granted {
                            await NotificationManager.shared.scheduleReminder(for: subscription)
                            reminderSet = true
                        }
                    }
                }
            } label: {
                Text(reminderSet ? settings.s("已提醒 ✓", "Set ✓") : settings.remindMeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appOnPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(reminderSet ? Color.appPrimary.opacity(0.6) : Color.appPrimary)
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .frame(width: 320)
        .glassCard()
        .task {
            reminderSet = await NotificationManager.shared.isReminderScheduled(for: subscription.id)
        }
    }
}

// MARK: - Subscription Row Card
struct SubscriptionRowCard: View {
    let subscription: Subscription
    let settings: AppSettings

    var daysLabel: String {
        let d = subscription.daysUntilRenewal
        return d == 0 ? settings.s("今天到期", "Due today") : settings.s("\(d)天后", "in \(d)d")
    }

    var body: some View {
        HStack(spacing: 12) {
            SubIcon(subscription: subscription, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(settings.billingCycleDisplay(subscription.billingCycle))
                    .font(.system(size: 12))
                    .foregroundColor(Color.appOnSurfaceVariant)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(subscription.formattedAmount())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(daysLabel)
                    .font(.system(size: 10))
                    .foregroundColor(subscription.isExpiringSoon ? Color.appSecondary : Color.appOnSurfaceVariant)
                // Progress bar through billing cycle
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.appSurfaceHigh).frame(height: 3)
                        Capsule()
                            .fill(subscription.isExpiringSoon
                                  ? Color.appSecondary
                                  : Color(hex: subscription.iconHex).opacity(0.8))
                            .frame(width: max(3, g.size.width * subscription.cycleProgress), height: 3)
                    }
                }
                .frame(width: 56, height: 3)
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Dashboard Empty State
struct DashboardEmptyState: View {
    @Environment(AppSettings.self) var settings
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.appPrimary.opacity(0.6))
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text(settings.s("还没有订阅", "No subscriptions yet"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(settings.s("点击下方 + 添加你的第一个订阅\n开始追踪每月支出", "Tap + below to add your first subscription\nand start tracking monthly spend"))
                    .font(.system(size: 14))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Shared Icon Component
struct SubIcon: View {
    let subscription: Subscription
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Color(hex: subscription.iconHex).opacity(0.2))
                .frame(width: size, height: size)
            Image(systemName: subscription.iconSymbol)
                .font(.system(size: size * 0.44))
                .foregroundColor(Color(hex: subscription.iconHex))
        }
    }
}
