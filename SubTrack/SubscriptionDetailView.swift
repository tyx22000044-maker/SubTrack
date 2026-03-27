import SwiftUI

struct SubscriptionDetailView: View {
    let subscription: Subscription
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss
    @State private var showCancelAlert = false
    @State private var showDeleteAlert = false
    @State private var showEdit = false
    @State private var showReceipt = false
    @State private var reminderScheduled = false
    @State private var reminderLoading = false
    @State private var showPermissionAlert = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        return f
    }
    private var shortFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }

    /// Real payment history: walks backwards by billing cycle from nextBillingDate
    /// stopping at startDate or a sensible cap.
    private var paymentHistory: [(date: String, amount: String)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM dd, yyyy"

        let (component, step): (Calendar.Component, Int) = {
            switch subscription.billingCycle {
            case .monthly: return (.month, -1)
            case .yearly:  return (.year,  -1)
            case .weekly:  return (.weekOfYear, -1)
            }
        }()
        let cap: Int = {
            switch subscription.billingCycle {
            case .monthly: return 12
            case .yearly:  return 6
            case .weekly:  return 16
            }
        }()

        var result: [(date: String, amount: String)] = []
        var cursor = subscription.nextBillingDate
        for _ in 0..<cap {
            guard let prev = cal.date(byAdding: component, value: step, to: cursor) else { break }
            if prev < subscription.startDate { break }
            result.append((fmt.string(from: prev), subscription.formattedAmount()))
            cursor = prev
        }
        return result
    }

    var statusText: String {
        switch subscription.status {
        case .active:    return settings.activeLabel
        case .paused:    return settings.pausedLabel
        case .cancelled: return settings.cancelledLabel
        }
    }
    var statusColor: Color {
        switch subscription.status {
        case .active:    return Color(hex: "4CAF50")
        case .paused:    return Color.appTertiary
        case .cancelled: return Color.appSecondary
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Icon + Name + Status
                    VStack(spacing: 12) {
                        SubIcon(subscription: subscription, size: 80)
                            .padding(.top, 24)

                        Text(subscription.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.appOnSurface)

                        Text(statusText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(statusColor)
                            .tracking(0.8)
                            .padding(.horizontal, 14).padding(.vertical, 5)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)

                    // Payment Info
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: settings.paymentInfoLabel)

                        DetailRow(label: settings.serviceFeeLabel,
                                  value: subscription.formattedAmount())

                        DetailRow(label: settings.billingCycleLabel,
                                  value: settings.billingCycleDisplay(subscription.billingCycle))

                        DetailRow(label: settings.nextPaymentLabel,
                                  value: dateFormatter.string(from: subscription.nextBillingDate) +
                                         "  (" + settings.s("\(subscription.daysUntilRenewal)天后", "in \(subscription.daysUntilRenewal) days") + ")",
                                  valueColor: subscription.isExpiringSoon ? Color.appSecondary : Color.appOnSurface)

                        DetailRow(label: settings.firstSubscribedLabel,
                                  value: shortFormatter.string(from: subscription.startDate))

                        DetailRow(label: settings.totalSpentLabel,
                                  value: String(format: "%@%.2f", subscription.currency.symbol, subscription.totalSpent) +
                                         "  (\(subscription.totalMonthsSubscribed)" + settings.monthsLabel + ")",
                                  isLast: true)
                    }
                    .glassCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Payment History
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: settings.paymentHistoryLabel)
                        let history = paymentHistory
                        if history.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appOutline)
                                Text(settings.s("暂无付款记录", "No payment history yet"))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appOnSurfaceVariant)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 16)
                        } else {
                            ForEach(Array(history.enumerated()), id: \.offset) { idx, item in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "4CAF50"))
                                        .font(.system(size: 16))
                                    Text(item.date)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.appOnSurface)
                                    Spacer()
                                    Text(item.amount)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.appOnSurface)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 13)
                                .overlay(alignment: .bottom) {
                                    if idx < history.count - 1 {
                                        Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 42)
                                    }
                                }
                            }
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Community Rating — Strategic Preview
                    CommunityRatingPreview()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Reminder
                        Button {
                            Task {
                                reminderLoading = true
                                if reminderScheduled {
                                    NotificationManager.shared.cancelReminder(for: subscription.id)
                                    reminderScheduled = false
                                } else {
                                    let granted = await NotificationManager.shared.requestPermission()
                                    if granted {
                                        await NotificationManager.shared.scheduleReminder(for: subscription)
                                        reminderScheduled = true
                                    } else {
                                        showPermissionAlert = true
                                    }
                                }
                                reminderLoading = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: reminderScheduled ? "bell.fill" : "bell")
                                Text(reminderScheduled
                                     ? settings.s("已设置提醒 ✓", "Reminder Set ✓")
                                     : settings.setReminderLabel)
                                    .font(.system(size: 16, weight: .semibold))
                                if reminderLoading {
                                    ProgressView().tint(Color.appOnPrimary).scaleEffect(0.8)
                                }
                            }
                            .foregroundColor(Color.appOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(reminderScheduled ? Color.appPrimary.opacity(0.7) : Color.appPrimary)
                            .cornerRadius(14)
                        }

                        // Pause / Resume (only shown when not cancelled)
                        if subscription.status != .cancelled {
                            Button {
                                store.togglePause(subscription.id)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: subscription.status == .paused
                                          ? "play.fill" : "pause.fill")
                                    Text(subscription.status == .paused
                                         ? settings.s("恢复订阅", "Resume Subscription")
                                         : settings.s("暂停订阅", "Pause Subscription"))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color.appOnSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appSurfaceContainer)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.appOutlineVariant, lineWidth: 1)
                                )
                            }
                        }

                        // View Receipt
                        Button { showReceipt = true } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text(settings.viewReceiptLabel)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color.appOnSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appSurfaceContainer)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.appOutlineVariant, lineWidth: 1)
                            )
                        }

                        // Divider row for destructive actions
                        HStack(spacing: 16) {
                            if subscription.status != .cancelled {
                                Button {
                                    showCancelAlert = true
                                } label: {
                                    Text(settings.cancelSubLabel)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.appSecondary)
                                        .padding(.vertical, 8)
                                }
                            }
                            Spacer()
                            Button {
                                showDeleteAlert = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13))
                                    Text(settings.s("永久删除", "Delete"))
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(Color.appSecondary.opacity(0.8))
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle(subscription.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(settings.s("返回", "Back"))
                        }
                        .font(.system(size: 15))
                        .foregroundColor(Color.appPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.editLabel) { showEdit = true }
                        .font(.system(size: 15))
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
        .alert(settings.cancelSubLabel, isPresented: $showCancelAlert) {
            Button(settings.s("确认取消", "Confirm"), role: .destructive) {
                NotificationManager.shared.cancelReminder(for: subscription.id)
                store.markCancelled(subscription.id)
                dismiss()
            }
            Button(settings.s("返回", "Cancel"), role: .cancel) { }
        } message: {
            Text(settings.s("此操作将把该订阅标记为已取消。", "This will mark the subscription as cancelled."))
        }
        .alert(settings.s("永久删除", "Delete Subscription"), isPresented: $showDeleteAlert) {
            Button(settings.s("永久删除", "Delete"), role: .destructive) {
                store.delete(subscription.id)
                dismiss()
            }
            Button(settings.s("取消", "Cancel"), role: .cancel) { }
        } message: {
            Text(settings.s("此操作将彻底删除该订阅，无法恢复。", "This will permanently delete the subscription and cannot be undone."))
        }
        .alert(settings.s("需要通知权限", "Notifications Required"), isPresented: $showPermissionAlert) {
            Button(settings.s("去设置", "Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(settings.s("取消", "Cancel"), role: .cancel) { }
        } message: {
            Text(settings.s("请在系统设置中允许 SubTrack 发送通知。", "Please allow SubTrack to send notifications in System Settings."))
        }
        .task {
            reminderScheduled = await NotificationManager.shared.isReminderScheduled(for: subscription.id)
        }
        .sheet(isPresented: $showEdit) {
            AddSubscriptionView(editing: subscription)
                .environment(store)
                .environment(settings)
        }
        .sheet(isPresented: $showReceipt) {
            ReceiptView(subscription: subscription)
                .environment(settings)
        }
    }
}

// MARK: - Helper Components
private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color.appOnSurfaceVariant)
            .tracking(0.8)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.appOnSurface
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color.appOnSurfaceVariant)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 16)
            }
        }
    }
}

// MARK: - Receipt View
struct ReceiptView: View {
    let subscription: Subscription
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss
    @State private var showShare = false

    private var receiptNumber: String {
        "ST-" + subscription.id.uuidString.prefix(8).uppercased()
    }
    private var issuedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: Date())
    }
    private var nextDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: subscription.nextBillingDate)
    }
    private var startDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: subscription.startDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        // ── Receipt card ─────────────────────────────────
                        VStack(spacing: 0) {
                            // Header
                            VStack(spacing: 8) {
                                // Jagged top edge (receipt tear)
                                ReceiptEdge(pointsUp: true)
                                    .fill(Color.appBackground)
                                    .frame(height: 16)
                                    .offset(y: -1)

                                VStack(spacing: 4) {
                                    Text("SubTrack")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.appOnSurfaceVariant)
                                        .tracking(3)
                                    Text(settings.s("订阅收据", "SUBSCRIPTION RECEIPT"))
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color.appOutline)
                                        .tracking(2)
                                }
                                .padding(.top, 8)
                            }

                            // Service Icon + Name
                            VStack(spacing: 12) {
                                SubIcon(subscription: subscription, size: 64)
                                    .padding(.top, 20)
                                Text(subscription.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.appOnSurface)
                                Text(settings.billingCycleDisplay(subscription.billingCycle))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.appOnSurfaceVariant)
                                    .tracking(1)
                            }
                            .padding(.bottom, 20)

                            ReceiptDivider()

                            // Amount
                            VStack(spacing: 4) {
                                Text(settings.s("本期费用", "AMOUNT DUE"))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.appOutline)
                                    .tracking(2)
                                Text(subscription.formattedAmount())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color.appOnSurface)
                                Text(subscription.currency.rawValue)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color.appOutline)
                            }
                            .padding(.vertical, 20)

                            ReceiptDivider()

                            // Details rows
                            VStack(spacing: 0) {
                                ReceiptRow(label: settings.s("收据编号", "RECEIPT NO."),  value: receiptNumber)
                                ReceiptRow(label: settings.s("开单日期", "ISSUED"),       value: issuedDate)
                                ReceiptRow(label: settings.s("首次订阅", "SINCE"),        value: startDate)
                                ReceiptRow(label: settings.s("下次扣款", "NEXT BILLING"), value: nextDate)
                                ReceiptRow(label: settings.s("累计支出", "TOTAL PAID"),
                                           value: String(format: "%@%.2f", subscription.currency.symbol, subscription.totalSpent),
                                           isLast: true)
                            }
                            .padding(.vertical, 8)

                            ReceiptDivider()

                            // Barcode-style decoration
                            HStack(spacing: 2) {
                                ForEach(0..<28, id: \.self) { i in
                                    Rectangle()
                                        .fill(Color.appOnSurfaceVariant.opacity(i % 3 == 0 ? 0.5 : 0.15))
                                        .frame(width: i % 3 == 0 ? 3 : 2, height: 36)
                                }
                            }
                            .padding(.vertical, 16)

                            Text(subscription.id.uuidString.lowercased().prefix(24) + "")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(Color.appOutline)
                                .padding(.bottom, 16)

                            // Jagged bottom edge
                            ReceiptEdge(pointsUp: false)
                                .fill(Color.appBackground)
                                .frame(height: 16)
                                .offset(y: 1)
                        }
                        .background(Color.appSurfaceContainer)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)

                        // Share button
                        Button {
                            showShare = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text(settings.s("分享收据", "Share Receipt"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color.appOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationTitle(settings.s("收据详情", "Receipt"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.s("关闭", "Close")) { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            let text = buildReceiptText()
            ShareSheet(items: [text])
        }
    }

    private func buildReceiptText() -> String {
        """
        ═══════════════════════════
              SubTrack
           \(settings.s("订阅收据", "SUBSCRIPTION RECEIPT"))
        ═══════════════════════════

        \(subscription.name)
        \(settings.billingCycleDisplay(subscription.billingCycle))

        \(settings.s("本期费用", "AMOUNT")): \(subscription.formattedAmount())

        ───────────────────────────
        \(settings.s("收据编号", "RECEIPT NO.")): \(receiptNumber)
        \(settings.s("开单日期", "ISSUED")):   \(issuedDate)
        \(settings.s("首次订阅", "SINCE")):    \(startDate)
        \(settings.s("下次扣款", "NEXT")):     \(nextDate)
        \(settings.s("累计支出", "TOTAL")):    \(String(format: "%@%.2f", subscription.currency.symbol, subscription.totalSpent))
        ───────────────────────────
        \(settings.s("由 SubTrack 生成", "Generated by SubTrack"))
        """
    }
}

// MARK: - Receipt UI Helpers

private struct ReceiptRow: View {
    let label: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.appOutline)
                .tracking(0.5)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.appOnSurface)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if !isLast {
                // Dashed divider
                Rectangle()
                    .fill(Color.appOutlineVariant.opacity(0.4))
                    .frame(height: 0.5)
                    .padding(.horizontal, 20)
            }
        }
    }
}

private struct ReceiptDivider: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<22, id: \.self) { _ in
                Rectangle()
                    .fill(Color.appOutlineVariant.opacity(0.5))
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 1)
            }
        }
        .padding(.horizontal, 20)
    }
}

/// A serrated / torn-paper edge shape for the receipt look
private struct ReceiptEdge: Shape {
    let pointsUp: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let teeth = 14
        let w = rect.width
        let h = rect.height
        let tw = w / CGFloat(teeth)

        path.move(to: CGPoint(x: 0, y: pointsUp ? h : 0))
        for i in 0..<teeth {
            let x1 = CGFloat(i) * tw
            let x2 = x1 + tw / 2
            let x3 = x1 + tw
            let tip: CGFloat = pointsUp ? 0 : h
            let base: CGFloat = pointsUp ? h : 0
            path.addLine(to: CGPoint(x: x1, y: base))
            path.addLine(to: CGPoint(x: x2, y: tip))
            path.addLine(to: CGPoint(x: x3, y: base))
        }
        path.addLine(to: CGPoint(x: w, y: pointsUp ? h : 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Community Rating Preview
struct CommunityRatingPreview: View {
    @Environment(AppSettings.self) var settings
    @State private var notifyRegistered = false

    // Mock distribution for visual preview (blurred)
    private let barWeights: [Double] = [0.44, 0.29, 0.15, 0.07, 0.05]

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appTertiary.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTertiary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.s("社区评分", "Community Ratings"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.appOnSurface)
                    Text(settings.s("SubTrack 用户真实反馈", "Real feedback from SubTrack users"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.appOnSurfaceVariant)
                }
                Spacer()
                Text("V 1.5")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.appTertiary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.appTertiary.opacity(0.14))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Rectangle()
                .fill(Color.appOutlineVariant.opacity(0.5))
                .frame(height: 0.5)

            // ── Blurred mock rating UI ───────────────────────────────
            ZStack {
                // Blurred content underneath
                HStack(alignment: .top, spacing: 16) {
                    // Score + stars
                    VStack(spacing: 6) {
                        Text("4.2")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(Color.appOnSurface)
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < 4 ? "star.fill" : "star.leadinghalf.filled")
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text("12,847")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appOnSurfaceVariant)
                    }
                    .frame(width: 72)

                    // Rating bars
                    VStack(spacing: 5) {
                        ForEach(barWeights.indices, id: \.self) { i in
                            HStack(spacing: 6) {
                                Text("\(5 - i)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.appOutline)
                                    .frame(width: 8)
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.appSurfaceHigh).frame(height: 6)
                                        Capsule()
                                            .fill(Color.yellow.opacity(0.65))
                                            .frame(width: g.size.width * barWeights[i], height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16).padding(.vertical, 18)
                .blur(radius: 6)

                // Lock overlay
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.appSurfaceContainer.opacity(0.9))
                            .frame(width: 48, height: 48)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.appOnSurfaceVariant)
                    }
                    Text(settings.s("上线后解锁", "Unlocks when live"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appOnSurfaceVariant)
                }
            }

            Rectangle()
                .fill(Color.appOutlineVariant.opacity(0.5))
                .frame(height: 0.5)

            // ── Value proposition ────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 20) {
                    CRFeaturePill(icon: "star.fill",    text: settings.s("真实评分", "Real Ratings"),   color: .yellow)
                    CRFeaturePill(icon: "tag.fill",     text: settings.s("用户标签", "User Tags"),      color: Color.appTertiary)
                    CRFeaturePill(icon: "chart.line.downtrend.xyaxis", text: settings.s("取消原因", "Cancel Reasons"), color: Color.appSecondary)
                }

                Text(settings.s(
                    "上线后，数千名 SubTrack 用户将分享真实的订阅体验——帮你在续费前做出更明智的决策。",
                    "When live, thousands of SubTrack users will share real subscription experiences — helping you decide before you renew."
                ))
                .font(.system(size: 13))
                .foregroundColor(Color.appOnSurfaceVariant)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16).padding(.top, 14)

            // ── Notify button ────────────────────────────────────────
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    notifyRegistered = true
                }
                UserDefaults.standard.set(true, forKey: "st_community_notify_interest")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: notifyRegistered ? "checkmark.circle.fill" : "bell.badge")
                        .font(.system(size: 15))
                    Text(notifyRegistered
                         ? settings.s("已登记，上线时通知你 ✓", "You'll be notified when live ✓")
                         : settings.s("上线时通知我", "Notify me when available"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(notifyRegistered ? Color.appOnPrimary : Color.appTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(notifyRegistered ? Color.appTertiary : Color.appTertiary.opacity(0.12))
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .glassCard()
        .onAppear {
            notifyRegistered = UserDefaults.standard.bool(forKey: "st_community_notify_interest")
        }
    }
}

private struct CRFeaturePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(Color.appOnSurface)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
}
