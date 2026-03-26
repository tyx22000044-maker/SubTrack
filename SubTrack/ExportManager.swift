import SwiftUI
import UIKit

// MARK: - CSV Export
func generateCSV(subscriptions: [Subscription], settings: AppSettings) -> String {
    let header = "Name,Amount,Currency,Billing Cycle,Monthly Amount,Category,Status,Next Billing Date,Start Date\n"
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    let rows = subscriptions.map { s in
        "\"\(s.name)\",\(s.amount),\(s.currency.rawValue),\(s.billingCycle.rawValue),\(String(format: "%.2f", s.monthlyAmount)),\(s.category.rawValue),\(s.status.rawValue),\(df.string(from: s.nextBillingDate)),\(df.string(from: s.startDate))"
    }.joined(separator: "\n")
    return header + rows
}

func csvFileURL(subscriptions: [Subscription], settings: AppSettings) -> URL {
    let content = generateCSV(subscriptions: subscriptions, settings: settings)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("SubTrack_Export.csv")
    try? content.write(to: url, atomically: true, encoding: .utf8)
    return url
}

// MARK: - PDF Report View (rendered to PDF)
struct PDFReportView: View {
    let subscriptions: [Subscription]
    let settings: AppSettings
    let store: SubscriptionStore

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        return f.string(from: Date())
    }
    private var isCNY: Bool { settings.currencyDefault == 0 }
    private var symbol: String { isCNY ? "¥" : "$" }
    private var total: Double { isCNY ? store.totalInCNY : store.totalInUSD }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "005BC1"))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                        Text("SubTrack")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "10141a"))
                    }
                    Text(settings.s("订阅支出报告", "Subscription Expense Report"))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(settings.s("生成日期：\(dateString)", "Generated: \(dateString)"))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                // Summary box
                VStack(alignment: .trailing, spacing: 4) {
                    Text(settings.s("月度总支出", "Monthly Total"))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(String(format: "%@%.2f", symbol, total))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "005BC1"))
                    Text(settings.s("\(subscriptions.filter { $0.status == .active }.count) 项活跃订阅",
                                    "\(subscriptions.filter { $0.status == .active }.count) active subscriptions"))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .padding(24)
            .background(Color(hex: "F2F4F8"))

            // Divider
            Rectangle().fill(Color(hex: "C2C7CF")).frame(height: 1)

            // Table header
            HStack {
                Text(settings.s("服务名称", "Service")).frame(maxWidth: .infinity, alignment: .leading)
                Text(settings.s("金额", "Amount")).frame(width: 80, alignment: .trailing)
                Text(settings.s("周期", "Cycle")).frame(width: 60, alignment: .center)
                Text(settings.s("分类", "Category")).frame(width: 80, alignment: .center)
                Text(settings.s("状态", "Status")).frame(width: 60, alignment: .center)
                Text(settings.s("下次扣款", "Next Date")).frame(width: 90, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.gray)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(hex: "E8EBF0"))

            // Rows
            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { idx, sub in
                HStack {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: sub.iconHex).opacity(0.2))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: sub.iconSymbol)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: sub.iconHex))
                            )
                        Text(sub.name).font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(sub.formattedAmount())
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 80, alignment: .trailing)

                    Text(settings.billingCycleDisplay(sub.billingCycle))
                        .font(.system(size: 10))
                        .frame(width: 60, alignment: .center)

                    Text(settings.categoryDisplay(sub.category))
                        .font(.system(size: 10))
                        .frame(width: 80, alignment: .center)

                    Text(statusLabel(sub.status, settings: settings))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(statusColor(sub.status))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(statusColor(sub.status).opacity(0.12))
                        .cornerRadius(4)
                        .frame(width: 60, alignment: .center)

                    Text(shortDate(sub.nextBillingDate))
                        .font(.system(size: 10))
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 9)
                .background(idx % 2 == 0 ? Color.white : Color(hex: "F8F9FC"))

                Rectangle().fill(Color(hex: "E8EBF0")).frame(height: 0.5)
            }

            // Footer
            HStack {
                Text(settings.s("由 SubTrack 生成 · 汇率 ¥7.25/$1", "Generated by SubTrack · Rate: ¥7.25/$1"))
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("subtrack.app")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "005BC1"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .frame(width: 600)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MM/dd/yyyy"
        return f.string(from: date)
    }
    private func statusLabel(_ status: Subscription.Status, settings: AppSettings) -> String {
        switch status {
        case .active:    return settings.s("活跃", "Active")
        case .paused:    return settings.s("暂停", "Paused")
        case .cancelled: return settings.s("取消", "Cancelled")
        }
    }
    private func statusColor(_ status: Subscription.Status) -> Color {
        switch status {
        case .active:    return Color(hex: "005BC1")
        case .paused:    return Color(hex: "874D00")
        case .cancelled: return Color(hex: "C5000B")
        }
    }
}

// MARK: - PDF File Generator
@MainActor
func generatePDF(subscriptions: [Subscription], settings: AppSettings, store: SubscriptionStore) -> URL {
    let reportView = PDFReportView(subscriptions: subscriptions, settings: settings, store: store)
    let renderer = ImageRenderer(content: reportView)
    renderer.scale = 2.0

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("SubTrack_Report.pdf")
    renderer.render { size, render in
        var box = CGRect(origin: .zero, size: CGSize(width: 612, height: size.height * (612 / size.width)))
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        ctx.beginPDFPage(nil)
        ctx.scaleBy(x: 612 / size.width, y: 612 / size.width)
        render(ctx)
        ctx.endPDFPage()
        ctx.closePDF()
    }
    return url
}
