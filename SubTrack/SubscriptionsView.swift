import SwiftUI

enum SubSortOption: Int {
    case renewalDate, amount, category, name
}

struct SubscriptionsView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @State private var filterIndex = 0
    @State private var sortOption: SubSortOption = .renewalDate
    @State private var selectedSub: Subscription? = nil
    @State private var searchText = ""
    @State private var showSearch = false

    var filters: [String] {
        [settings.filterAll, settings.filterActive, settings.filterExpiring, settings.filterPaused]
    }

    var filtered: [Subscription] {
        let base: [Subscription]
        switch filterIndex {
        case 1:  base = store.subscriptions.filter { $0.status == .active }
        case 2:  base = store.subscriptions.filter { $0.isExpiringSoon }
        case 3:  base = store.subscriptions.filter { $0.status == .paused }
        default: base = store.subscriptions
        }
        let sorted: [Subscription]
        switch sortOption {
        case .renewalDate: sorted = base.sorted { $0.daysUntilRenewal < $1.daysUntilRenewal }
        case .amount:      sorted = base.sorted { $0.monthlyAmount > $1.monthlyAmount }
        case .category:    sorted = base.sorted { $0.category.rawValue < $1.category.rawValue }
        case .name:        sorted = base.sorted { $0.name < $1.name }
        }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var sortLabel: String {
        switch sortOption {
        case .renewalDate: return settings.s("续费时间", "Renewal Date")
        case .amount:      return settings.s("金额", "Amount")
        case .category:    return settings.s("分类", "Category")
        case .name:        return settings.s("名称", "Name")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(settings.subscriptionsTitle)
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
                        .font(.system(size: 20)).foregroundColor(Color.appOnSurface)
                }
                Menu {
                    Text(settings.s("排序方式", "Sort by")).font(.headline)
                    Button { sortOption = .renewalDate } label: {
                        Label(settings.s("续费时间", "Renewal Date"),   systemImage: sortOption == .renewalDate ? "checkmark" : "calendar")
                    }
                    Button { sortOption = .amount } label: {
                        Label(settings.s("金额（高→低）", "Amount (High→Low)"), systemImage: sortOption == .amount ? "checkmark" : "dollarsign")
                    }
                    Button { sortOption = .category } label: {
                        Label(settings.s("分类", "Category"), systemImage: sortOption == .category ? "checkmark" : "tag")
                    }
                    Button { sortOption = .name } label: {
                        Label(settings.s("名称", "Name"), systemImage: sortOption == .name ? "checkmark" : "textformat")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down").font(.system(size: 14))
                        Text(sortLabel).font(.system(size: 12))
                    }
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

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
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters.indices, id: \.self) { i in
                        Button(filters[i]) { filterIndex = i }
                            .font(.system(size: 13, weight: filterIndex == i ? .semibold : .regular))
                            .foregroundColor(filterIndex == i ? Color.appOnPrimary : Color.appOnSurfaceVariant)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(filterIndex == i ? Color.appPrimary : Color.appSurfaceContainer)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // List
            ScrollView {
                LazyVStack(spacing: 10) {
                    if store.subscriptions.isEmpty {
                        SubscriptionsEmptyState()
                            .padding(.top, 40)
                    } else if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 40))
                                .foregroundColor(Color.appOutline)
                            Text(settings.s("没有符合条件的订阅", "No subscriptions match this filter"))
                                .font(.system(size: 15))
                                .foregroundColor(Color.appOnSurfaceVariant)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(filtered) { sub in
                            Button { selectedSub = sub } label: {
                                SubscriptionListRow(subscription: sub, settings: settings)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.appBackground)
        .sheet(item: $selectedSub) { sub in
            SubscriptionDetailView(subscription: sub)
                .environment(store)
                .environment(settings)
        }
    }
}

struct SubscriptionListRow: View {
    let subscription: Subscription
    let settings: AppSettings

    var nextLabel: String {
        if subscription.isExpiringSoon {
            return settings.s("⚠️ \(subscription.daysUntilRenewal)天后到期",
                              "⚠️ EXPIRING IN \(subscription.daysUntilRenewal) DAYS")
        }
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return settings.s("下次：\(f.string(from: subscription.nextBillingDate))",
                          "NEXT: \(f.string(from: subscription.nextBillingDate).uppercased())")
    }

    var statusColor: Color {
        switch subscription.status {
        case .active:    return Color.appPrimary
        case .paused:    return Color.appTertiary
        case .cancelled: return Color.appSecondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            SubIcon(subscription: subscription, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(settings.billingCycleDisplay(subscription.billingCycle).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .tracking(0.5)
                Text(nextLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(subscription.isExpiringSoon ? Color.appSecondary : Color.appOnSurfaceVariant)
                    .tracking(0.3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.formattedAmount())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(subscription.currency.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Subscriptions Empty State
struct SubscriptionsEmptyState: View {
    @Environment(AppSettings.self) var settings
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "checklist")
                    .font(.system(size: 36))
                    .foregroundColor(Color.appPrimary.opacity(0.6))
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text(settings.s("订阅列表为空", "No subscriptions yet"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(settings.s("点击下方 + 开始追踪\n你的第一个订阅服务", "Tap + below to start tracking\nyour first subscription"))
                    .font(.system(size: 14))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}
