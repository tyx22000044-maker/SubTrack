import SwiftUI

struct SubscriptionDetailView: View {
    let subscription: Subscription
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss
    @State private var showCancelAlert = false

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

    private var mockHistory: [(date: String, amount: String)] {
        let cal = Calendar.current
        return (1...3).map { i in
            let d = cal.date(byAdding: .month, value: -i, to: subscription.nextBillingDate) ?? Date()
            let f = DateFormatter()
            f.dateFormat = "MMM dd, yyyy"
            return (f.string(from: d), subscription.formattedAmount())
        }
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
                        ForEach(Array(mockHistory.enumerated()), id: \.offset) { idx, item in
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
                                if idx < mockHistory.count - 1 {
                                    Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 42)
                                }
                            }
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Community Rating — Coming Soon
                    ComingSoonCard(
                        icon: "person.2.fill",
                        title: settings.communityRatingLabel,
                        message: settings.s("社区评分与讨论功能即将上线。", "Community ratings and reviews are coming soon.")
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text(settings.setReminderLabel)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color.appOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .cornerRadius(14)
                        }

                        Button {
                        } label: {
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

                        Button {
                            showCancelAlert = true
                        } label: {
                            Text(settings.cancelSubLabel)
                                .font(.system(size: 15))
                                .foregroundColor(Color.appSecondary)
                                .padding(.vertical, 8)
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
                    Button(settings.editLabel) { }
                        .font(.system(size: 15))
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
        .alert(settings.cancelSubLabel, isPresented: $showCancelAlert) {
            Button(settings.s("确认取消", "Confirm"), role: .destructive) {
                store.markCancelled(subscription.id)
                dismiss()
            }
            Button(settings.s("返回", "Cancel"), role: .cancel) { }
        } message: {
            Text(settings.s("此操作将把该订阅标记为已取消。", "This will mark the subscription as cancelled."))
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
