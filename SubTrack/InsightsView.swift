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

    var symbol: String { settings.currencyDefault == 0 ? "¥" : "$" }

    func monthlyData() -> [MonthData] {
        let count = periodMonths[periodIndex]
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        let isCNY = settings.currencyDefault == 0

        return (0..<count).map { i in
            let offset = count - 1 - i
            let targetDate = cal.date(byAdding: .month, value: -offset, to: now) ?? now

            // Calculate end of that month
            let comps = cal.dateComponents([.year, .month], from: targetDate)
            let startOfMonth = cal.date(from: comps) ?? targetDate
            let startOfNext = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? targetDate
            let endOfMonth = cal.date(byAdding: .second, value: -1, to: startOfNext) ?? targetDate

            // Sum subscriptions that were active (started) by that month
            let amount = store.subscriptions
                .filter { $0.status == .active && $0.startDate <= endOfMonth }
                .reduce(0.0) { acc, sub in
                    if isCNY {
                        return acc + (sub.currency == .cny ? sub.monthlyAmount : sub.monthlyAmount * SubscriptionStore.usdToCnyRate)
                    } else {
                        return acc + (sub.currency == .usd ? sub.monthlyAmount : sub.monthlyAmount / SubscriptionStore.usdToCnyRate)
                    }
                }

            let label = offset == 0 ? settings.s("本月", "Now") : fmt.string(from: targetDate)
            return MonthData(label: label, amount: amount, isCurrent: offset == 0)
        }
    }

    var currentData: [MonthData] { monthlyData() }
    var totalSpend: Double  { currentData.reduce(0) { $0 + $1.amount } }
    var monthlyAvg: Double  { totalSpend / Double(periodMonths[periodIndex]) }
    var peakAmount: Double  { currentData.map(\.amount).max() ?? 0 }

    // Year-to-date total (Jan 1 of current year → now)
    var yearToDateTotal: Double {
        let cal = Calendar.current
        let now = Date()
        let isCNY = settings.currencyDefault == 0
        guard let jan1 = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1)) else { return 0 }
        return store.subscriptions
            .filter { $0.status == .active && $0.startDate <= now }
            .reduce(0.0) { acc, sub in
                // Count months from max(startDate, jan1) to now
                let from = max(sub.startDate, jan1)
                let months = max(1, cal.dateComponents([.month], from: from, to: now).month ?? 1)
                let contribution = sub.monthlyAmount * Double(months)
                if isCNY {
                    return acc + (sub.currency == .cny ? contribution : contribution * SubscriptionStore.usdToCnyRate)
                } else {
                    return acc + (sub.currency == .usd ? contribution : contribution / SubscriptionStore.usdToCnyRate)
                }
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(settings.insightsTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appOnSurface)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if store.subscriptions.isEmpty {
                    // ── Empty state ──────────────────────────────
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appOutline)
                        Text(settings.s("添加订阅后查看财务洞察", "Add subscriptions to see insights"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appOnSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {

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
                    InsightStat(label: settings.totalSpendLabel, value: String(format: "%@%.0f", symbol, totalSpend))
                    InsightStat(label: settings.monthlyAvgLabel, value: String(format: "%@%.0f", symbol, monthlyAvg))
                    InsightStat(label: settings.peakMonthLabel,  value: String(format: "%@%.0f", symbol, peakAmount))
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.2), value: periodIndex)

                // Monthly Bar Chart
                VStack(alignment: .leading, spacing: 14) {
                    Text(settings.monthlyTrendLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    MonthlyBarChart(data: currentData, symbol: symbol)
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
                        CategoryBarRow(item: item, symbol: symbol)
                    }
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 20)

                // Annual Summary
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.annualSummaryLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.appOnSurfaceVariant)
                            .tracking(0.8)
                        Text(String(format: "%@%.0f", symbol, yearToDateTotal))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.appOnSurface)
                        Text(settings.s("今年 1 月 1 日起累计", "Since Jan 1 this year"))
                            .font(.system(size: 12))
                            .foregroundColor(Color.appOutline)
                    }
                    Spacer()
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.appPrimary.opacity(0.5))
                }
                .padding(20)
                .glassCard()
                .padding(.horizontal, 20)

                // AI Suggestions — Strategic Preview
                AIInsightsPreview()
                    .padding(.horizontal, 20)

                Spacer().frame(height: 90)
                } // end else (non-empty)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
    }

    func categoryData() -> [CategoryItem] {
        let isCNY = settings.currencyDefault == 0
        // Total using same currency conversion as the bar chart
        let total = store.subscriptions.filter { $0.status == .active }.reduce(0.0) { acc, sub in
            isCNY
                ? acc + (sub.currency == .cny ? sub.monthlyAmount : sub.monthlyAmount * SubscriptionStore.usdToCnyRate)
                : acc + (sub.currency == .usd ? sub.monthlyAmount : sub.monthlyAmount / SubscriptionStore.usdToCnyRate)
        }
        let pairs: [(String, Subscription.Category, Color)] = [
            (settings.s("娱乐",    "Entertainment"), .entertainment, Color.appPrimary),
            (settings.s("效率工具", "Productivity"),  .productivity,  Color.appSecondary),
            (settings.s("音乐",    "Music"),          .music,         Color.appTertiary),
            (settings.s("云服务",  "Cloud"),          .cloud,         Color(hex: "90caf9")),
            (settings.s("其他",    "Other"),          .other,         Color.appOutline),
        ]
        return pairs.compactMap { name, cat, color in
            let amt = store.subscriptions.filter { $0.status == .active && $0.category == cat }.reduce(0.0) { acc, sub in
                isCNY
                    ? acc + (sub.currency == .cny ? sub.monthlyAmount : sub.monthlyAmount * SubscriptionStore.usdToCnyRate)
                    : acc + (sub.currency == .usd ? sub.monthlyAmount : sub.monthlyAmount / SubscriptionStore.usdToCnyRate)
            }
            guard amt > 0 else { return nil }   // hide empty categories
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
    var symbol: String = "$"
    var maxAmt: Double { data.map(\.amount).max() ?? 1 }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { item in
                    VStack(spacing: 0) {
                        if item.isCurrent {
                            Text(String(format: "%@%.0f", symbol, item.amount))
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
    var symbol: String = "$"
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(item.color).frame(width: 8, height: 8)
                    Text(item.name).font(.system(size: 14)).foregroundColor(Color.appOnSurface)
                }
                Spacer()
                Text(String(format: "%@%.0f · %.0f%%", symbol, item.amount, item.pct * 100))
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

// MARK: - AI Suggestion Card (reusable, used elsewhere)
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

// MARK: - AI Insights Preview (strategic coming-soon module)
struct AIInsightsPreview: View {
    @Environment(AppSettings.self) var settings

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appPrimary.opacity(0.14)).frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 17))
                        .foregroundColor(Color.appPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.s("AI 省钱建议", "AI Savings Suggestions"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    Text(settings.s("智能分析你的订阅组合", "Analyzes your subscription portfolio"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.appOnSurfaceVariant)
                }
                Spacer()
                Text("V 1.0")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.12))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Rectangle()
                .fill(Color.appOutlineVariant.opacity(0.5))
                .frame(height: 0.5)

            // ── Mock suggestion cards (blurred) ──────────────────────
            VStack(spacing: 10) {
                // Type A: Duplicate detection
                MockSuggestionCard(
                    icon: "exclamationmark.2",
                    accent: .orange,
                    badge: settings.s("重复订阅", "Duplicate Found"),
                    title: settings.s("发现重叠订阅", "Found Duplicate"),
                    message: settings.s(
                        "Apple Music (¥11) 与 Apple One (¥68) 功能重叠，取消前者每月可省 ¥11。",
                        "Apple Music (¥11) overlaps with Apple One (¥68). Cancel it to save ¥11/mo."
                    )
                )
                // Type B: Switch to annual
                MockSuggestionCard(
                    icon: "calendar.badge.checkmark",
                    accent: Color.appPrimary,
                    badge: settings.s("切换年付", "Switch to Annual"),
                    title: settings.s("建议切换年付", "Switch to Annual"),
                    message: settings.s(
                        "切换 Netflix 为年付预计每年省 ¥18，你已连续订阅 8 个月。",
                        "Switching Netflix to annual billing saves an estimated ¥18/year. You've subscribed 8 months."
                    )
                )
            }
            .blur(radius: 5)
            .overlay(
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.appSurfaceContainer.opacity(0.92))
                            .frame(width: 52, height: 52)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appPrimary)
                    }
                    Text(settings.s("AI 分析即将上线", "AI Analysis Coming Soon"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    Text(settings.s("上线后自动扫描你的订阅组合", "Will auto-scan your subscription portfolio"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.appOnSurfaceVariant)
                }
            )
            .padding(.horizontal, 14).padding(.top, 14)

            Rectangle()
                .fill(Color.appOutlineVariant.opacity(0.5))
                .frame(height: 0.5)
                .padding(.top, 14)

            // ── Two feature pills ────────────────────────────────────
            HStack(spacing: 12) {
                AIFeaturePill(
                    icon: "doc.text.magnifyingglass",
                    text: settings.s("重复订阅检测", "Duplicate Detection")
                )
                AIFeaturePill(
                    icon: "arrow.2.circlepath",
                    text: settings.s("年付省钱建议", "Annual Switch Tips")
                )
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .glassCard()
    }
}

private struct MockSuggestionCard: View {
    let icon: String
    let accent: Color
    let badge: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.18)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(accent.opacity(0.12))
                        .cornerRadius(20)
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appOnSurface)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Color.appSurfaceContainer)
        .cornerRadius(12)
    }
}

private struct AIFeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(Color.appPrimary)
            Text(text).font(.system(size: 12, weight: .medium)).foregroundColor(Color.appOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.appPrimary.opacity(0.08))
        .cornerRadius(10)
    }
}
