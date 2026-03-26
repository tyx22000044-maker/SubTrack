import SwiftUI

struct InsightsView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @State private var periodIndex = 1
    let periods = ["3M", "6M", "1Y"]
    let periodMonths = [3, 6, 12]

    struct CategoryItem: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let pct: Double
        let color: Color
    }
    struct MonthData: Identifiable {
        let id = UUID()
        let label: String
        let amount: Double
        let isCurrent: Bool
    }

    func monthlyData() -> [MonthData] {
        let count = periodMonths[periodIndex]
        let base = store.totalMonthlySpend
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        let v = [0.88, 0.93, 0.97, 1.04, 0.95, 1.08, 0.91, 1.06, 0.99, 1.11, 1.03, 1.0]
        return (0..<count).map { i in
            let offset = count - 1 - i
            let date = cal.date(byAdding: .month, value: -offset, to: now) ?? now
            let label = offset == 0 ? settings.s("本月", "Now") : fmt.string(from: date)
            return MonthData(label: label, amount: base * v[i % v.count], isCurrent: offset == 0)
        }
    }

    var currentData: [MonthData] { monthlyData() }
    var totalSpend: Double  { currentData.reduce(0) { $0 + $1.amount } }
    var monthlyAvg: Double  { totalSpend / Double(periodMonths[periodIndex]) }
    var peakAmount: Double  { currentData.map(\.amount).max() ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(settings.insightsTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appOnSurface)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Period Selector
                HStack(spacing: 0) {
                    ForEach(periods.indices, id: \.self) { i in
                        Button(periods[i]) { periodIndex = i }
                            .font(.system(size: 13, weight: periodIndex == i ? .semibold : .regular))
                            .foregroundColor(periodIndex == i ? Color.appOnPrimary : Color.appOnSurfaceVariant)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(periodIndex == i ? Color.appPrimary : Color.clear)
                            .cornerRadius(8)
                    }
                }
                .background(Color.appSurfaceContainer)
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: periodIndex)

                // Stats Row
                HStack(spacing: 10) {
                    InsightStat(label: settings.totalSpendLabel, value: String(format: "$%.0f", totalSpend))
                    InsightStat(label: settings.monthlyAvgLabel, value: String(format: "$%.0f", monthlyAvg))
                    InsightStat(label: settings.peakMonthLabel,  value: String(format: "$%.0f", peakAmount))
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: periodIndex)

                // Monthly Bar Chart
                VStack(alignment: .leading, spacing: 14) {
                    Text(settings.monthlyTrendLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    MonthlyBarChart(data: currentData)
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.3), value: periodIndex)

                // Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text(settings.breakdownLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    ForEach(categoryData()) { item in
                        CategoryBarRow(item: item)
                    }
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 20)

                // AI Suggestions — Coming Soon
                ComingSoonCard(
                    icon: "sparkles",
                    title: settings.aiSugLabel,
                    message: settings.s("AI 智能分析即将上线，帮你找到重复订阅、推荐最优方案。", "AI-powered analysis is coming soon — find duplicates and optimize your spending.")
                )
                .padding(.horizontal, 20)

                Spacer().frame(height: 90)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
    }

    func categoryData() -> [CategoryItem] {
        let total = store.totalMonthlySpend
        let pairs: [(String, Subscription.Category, Color)] = [
            (settings.s("娱乐",    "Entertainment"), .entertainment, Color.appPrimary),
            (settings.s("效率工具", "Productivity"),  .productivity,  Color.appSecondary),
            (settings.s("音乐",    "Music"),          .music,         Color.appTertiary),
            (settings.s("云服务",  "Cloud"),          .cloud,         Color(hex: "90caf9")),
        ]
        return pairs.map { name, cat, color in
            let amt = store.subscriptions.filter { $0.category == cat }.reduce(0) { $0 + $1.monthlyAmount }
            return CategoryItem(name: name, amount: amt, pct: total > 0 ? amt / total : 0, color: color)
        }
    }
}

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSurfaceHigh)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.appOutline)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Color.appOnSurfaceVariant)
                    Text("· 敬请期待").font(.system(size: 12)).foregroundColor(Color.appOutline)
                }
                Text(message).font(.system(size: 12)).foregroundColor(Color.appOutline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.appSurfaceContainer.opacity(0.6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.appOutlineVariant.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Monthly Bar Chart
struct MonthlyBarChart: View {
    let data: [InsightsView.MonthData]
    var maxAmt: Double { data.map(\.amount).max() ?? 1 }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { item in
                    VStack(spacing: 0) {
                        if item.isCurrent {
                            Text(String(format: "$%.0f", item.amount))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.appPrimary)
                                .padding(.bottom, 4)
                        } else {
                            Spacer()
                        }
                        GeometryReader { g in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.isCurrent ? Color.appPrimary : Color.appPrimary.opacity(0.3))
                                    .frame(height: g.size.height * (item.amount / maxAmt))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
            HStack(spacing: 6) {
                ForEach(data) { item in
                    Text(item.label)
                        .font(.system(size: 9))
                        .foregroundColor(item.isCurrent ? Color.appPrimary : Color.appOnSurfaceVariant)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct InsightStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(Color.appOnSurface)
            Text(label).font(.system(size: 11)).foregroundColor(Color.appOnSurfaceVariant).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14).glassCard(cornerRadius: 12)
    }
}

// MARK: - Category Bar
struct CategoryBarRow: View {
    let item: InsightsView.CategoryItem
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(item.color).frame(width: 8, height: 8)
                    Text(item.name).font(.system(size: 14)).foregroundColor(Color.appOnSurface)
                }
                Spacer()
                Text(String(format: "$%.0f · %.0f%%", item.amount, item.pct * 100))
                    .font(.system(size: 13)).foregroundColor(Color.appOnSurfaceVariant)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.appSurfaceHigh).frame(height: 8)
                    Capsule().fill(item.color).frame(width: max(4, g.size.width * item.pct), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - AI Suggestion Card
struct AISuggestion: View {
    let icon: String
    let title: String
    let description: String
    let accent: Color
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.2)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color.appOnSurface)
                Text(description).font(.system(size: 13)).foregroundColor(Color.appOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.appSurfaceContainer)
        .cornerRadius(12)
    }
}
