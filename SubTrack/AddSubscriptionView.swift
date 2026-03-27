import SwiftUI

// MARK: - Service Presets (auto icon detection)
struct ServicePreset {
    let keyword: String
    let hex: String
    let symbol: String
    let category: Subscription.Category

    static let all: [ServicePreset] = [
        ServicePreset(keyword: "netflix",   hex: "E50914", symbol: "play.rectangle.fill",   category: .entertainment),
        ServicePreset(keyword: "spotify",   hex: "1DB954", symbol: "music.note",             category: .music),
        ServicePreset(keyword: "apple",     hex: "98989D", symbol: "apple.logo",             category: .entertainment),
        ServicePreset(keyword: "adobe",     hex: "FF3A2D", symbol: "a.circle.fill",          category: .productivity),
        ServicePreset(keyword: "disney",    hex: "113CCF", symbol: "star.circle.fill",       category: .entertainment),
        ServicePreset(keyword: "icloud",    hex: "3478F6", symbol: "icloud.fill",            category: .cloud),
        ServicePreset(keyword: "youtube",   hex: "FF0000", symbol: "play.circle.fill",       category: .entertainment),
        ServicePreset(keyword: "amazon",    hex: "FF9900", symbol: "cart.fill",              category: .entertainment),
        ServicePreset(keyword: "hulu",      hex: "1CE783", symbol: "tv.fill",                category: .entertainment),
        ServicePreset(keyword: "notion",    hex: "FFFFFF", symbol: "doc.fill",               category: .productivity),
        ServicePreset(keyword: "github",    hex: "6E40C9", symbol: "chevron.left.forwardslash.chevron.right", category: .productivity),
        ServicePreset(keyword: "dropbox",   hex: "0061FF", symbol: "arrow.down.circle.fill", category: .cloud),
        ServicePreset(keyword: "figma",     hex: "A259FF", symbol: "paintbrush.fill",        category: .productivity),
        ServicePreset(keyword: "slack",     hex: "E01E5A", symbol: "bubble.left.fill",       category: .productivity),
        ServicePreset(keyword: "zoom",      hex: "2D8CFF", symbol: "video.fill",             category: .productivity),
    ]

    static func detect(_ name: String) -> ServicePreset? {
        let lower = name.lowercased()
        return all.first { lower.contains($0.keyword) }
    }
}

// MARK: - Main View
struct AddSubscriptionView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss

    // Stored properties for edit mode
    private let editingId: UUID?
    private let editingStartDate: Date

    // State properties (initialized via custom init)
    @State private var currentStep: Int
    @State private var serviceName: String
    @State private var amountText: String
    @State private var billingCycle: Subscription.BillingCycle
    @State private var nextBillingDate: Date
    @State private var category: Subscription.Category
    @State private var currency: Subscription.Currency

    init(editing: Subscription? = nil) {
        editingId = editing?.id
        editingStartDate = editing?.startDate ?? Date()
        _currentStep    = State(initialValue: editing != nil ? 2 : 0)
        _serviceName    = State(initialValue: editing?.name ?? "")
        _amountText     = State(initialValue: editing.map { String(format: "%.2f", $0.amount) } ?? "")
        _billingCycle   = State(initialValue: editing?.billingCycle ?? .monthly)
        _nextBillingDate = State(initialValue: editing?.nextBillingDate ?? (Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()))
        _category       = State(initialValue: editing?.category ?? .entertainment)
        _currency       = State(initialValue: editing?.currency ?? .usd)
    }

    var isEditing: Bool { editingId != nil }

    var stepLabels: [String] {
        [settings.stepLabels[0], settings.stepLabels[1], settings.stepLabels[2]]
    }

    var detectedPreset: ServicePreset? { ServicePreset.detect(serviceName) }
    var iconHex: String    { detectedPreset?.hex ?? "adc6ff" }
    var iconSymbol: String { detectedPreset?.symbol ?? "app.fill" }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appOnSurface)
                            .frame(width: 36, height: 36)
                            .background(Color.appSurfaceContainer)
                            .clipShape(Circle())
                    }
                    Spacer()
                    if !isEditing {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles").font(.system(size: 11))
                            Text(settings.s("AI 智能扫描", "AI Smart Scanner")).font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color.appPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.appPrimary.opacity(0.15))
                        .cornerRadius(20)
                    } else {
                        Text(settings.s("编辑订阅", "Edit Subscription"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appOnSurface)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(isEditing ? Color.clear : Color.appOnSurfaceVariant)
                    }
                    .disabled(isEditing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Title
                if !isEditing {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.addSubTitle)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color.appOnSurface)
                        Text(settings.aiSubtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color.appOnSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }

                // Step Content
                Group {
                    switch currentStep {
                    case 0:
                        SelectStepView(onScan: { currentStep = 1 }, onManual: { currentStep = 2 })
                    case 1:
                        ScanStepView(onNext: { currentStep = 2 })
                    case 2:
                        ConfirmStepView(
                            serviceName: $serviceName,
                            amountText: $amountText,
                            billingCycle: $billingCycle,
                            nextBillingDate: $nextBillingDate,
                            category: $category,
                            currency: $currency,
                            iconHex: iconHex,
                            iconSymbol: iconSymbol,
                            isEditing: isEditing,
                            onSave: save
                        )
                    default:
                        EmptyView()
                    }
                }

                Spacer(minLength: 16)

                if !isEditing {
                    StepIndicator(steps: stepLabels, current: currentStep)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 36)
                }
            }
        }
    }

    func save() {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return }
        let name = serviceName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        var sub = Subscription(
            name: name,
            amount: amount,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            category: detectedPreset?.category ?? category,
            status: .active,
            iconHex: iconHex,
            iconSymbol: iconSymbol,
            currency: currency,
            startDate: editingStartDate
        )

        if let id = editingId {
            sub.id = id
            store.update(sub)
        } else {
            sub.startDate = Date()
            store.add(sub)
        }
        dismiss()
    }
}

extension AppSettings {
    var stepLabels: [String] { [s("选择", "SELECT"), s("扫描", "AI SCAN"), s("确认", "CONFIRM")] }
}

// MARK: - Step 0: Select
struct SelectStepView: View {
    @Environment(AppSettings.self) var settings
    let onScan: () -> Void
    let onManual: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onScan) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.appPrimary.opacity(0.15)).frame(width: 56, height: 56)
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 28)).foregroundColor(Color.appPrimary)
                    }
                    Text(settings.tapToScanLabel)
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(Color.appOnSurface)
                    Text(settings.s("支持 App Store / 邮件 / 银行账单", "Supports App Store / Email / Bank statements"))
                        .font(.system(size: 13)).foregroundColor(Color.appOnSurfaceVariant).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 36)
                .background(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.appPrimary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Rectangle().fill(Color.appOutlineVariant).frame(height: 0.5)
                Text(settings.orLabel).font(.system(size: 12, weight: .semibold)).foregroundColor(Color.appOutline).tracking(1)
                Rectangle().fill(Color.appOutlineVariant).frame(height: 0.5)
            }
            .padding(.horizontal, 20)

            Button(action: onManual) {
                Text(settings.enterManuallyLabel)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.appPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.appPrimary.opacity(0.12)).cornerRadius(12)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(settings.supportedTypesLabel)
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Color.appOutline)
                    .tracking(0.8).padding(.leading, 4)
                VStack(spacing: 0) {
                    SupportedTypeRow(icon: "bag.fill",               color: Color.appPrimary,           title: settings.appStoreOrderLabel, isLast: false)
                    SupportedTypeRow(icon: "envelope.fill",          color: Color.appTertiary,          title: settings.emailReceiptLabel,  isLast: false)
                    SupportedTypeRow(icon: "building.columns.fill",  color: Color(hex: "1DB954"),       title: settings.bankStatementLabel, isLast: true)
                }
                .glassCard()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct SupportedTypeRow: View {
    let icon: String
    let color: Color
    let title: String
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.2)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            Text(title).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.appOutline)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
            }
        }
    }
}

// MARK: - Step 1: AI Scan Preview
struct ScanStepView: View {
    @Environment(AppSettings.self) var settings
    let onNext: () -> Void
    @State private var pulse = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // ── Version badge ────────────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 11))
                    Text(settings.s("功能预告 · V1.0 上线", "Coming in V1.0"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Color.appPrimary)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color.appPrimary.opacity(0.12))
                .cornerRadius(20)

                // ── Hero ─────────────────────────────────────────────
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.08))
                            .frame(width: 88, height: 88)
                            .scaleEffect(pulse ? 1.18 : 1.0)
                            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                        Circle()
                            .fill(Color.appPrimary.opacity(0.14))
                            .frame(width: 68, height: 68)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(Color.appPrimary)
                    }
                    .onAppear { pulse = true }

                    Text(settings.s("AI 智能扫描", "AI Smart Scanner"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.appOnSurface)

                    Text(settings.s(
                        "拍一张账单截图，AI 自动识别\n服务名称、金额、周期——无需手动输入",
                        "Snap a receipt screenshot — AI auto-fills\nservice name, amount, and billing cycle"
                    ))
                    .font(.system(size: 14))
                    .foregroundColor(Color.appOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.appPrimary.opacity(0.3),
                                      style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )
                .padding(.horizontal, 20)

                // ── Source types with accuracy ───────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text(settings.s("支持三种来源", "3 SUPPORTED SOURCES"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.appOutline)
                        .tracking(0.8)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ScanSourceRow(
                            icon: "bag.fill",
                            color: Color.appPrimary,
                            title: settings.s("App Store 订单", "App Store Order"),
                            accuracy: settings.s("准确率 ≥ 95%", "≥95% accuracy"),
                            isLast: false
                        )
                        ScanSourceRow(
                            icon: "envelope.fill",
                            color: Color.appTertiary,
                            title: settings.s("邮件收据", "Email Receipt"),
                            accuracy: settings.s("准确率 ≥ 85%", "≥85% accuracy"),
                            isLast: false
                        )
                        ScanSourceRow(
                            icon: "building.columns.fill",
                            color: Color(hex: "1DB954"),
                            title: settings.s("银行账单", "Bank Statement"),
                            accuracy: settings.s("准确率 ≥ 70%", "≥70% accuracy"),
                            isLast: true
                        )
                    }
                    .glassCard()
                }
                .padding(.horizontal, 20)

                // ── Confidence scoring preview ───────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(settings.s("置信度系统", "Confidence Scoring"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.appOnSurface)
                        Spacer()
                        Text(settings.s("低置信度字段自动高亮", "Low-confidence fields highlighted"))
                            .font(.system(size: 11))
                            .foregroundColor(Color.appOutline)
                            .multilineTextAlignment(.trailing)
                    }

                    VStack(spacing: 10) {
                        ConfidenceRow(field: settings.s("服务名称", "Service"),  pct: 0.98, high: true)
                        ConfidenceRow(field: settings.s("扣费金额", "Amount"),   pct: 0.95, high: true)
                        ConfidenceRow(field: settings.s("账单周期", "Cycle"),    pct: 0.87, high: false)
                        ConfidenceRow(field: settings.s("下次扣款", "Next date"), pct: 0.72, high: false)
                    }
                }
                .padding(16)
                .glassCard()
                .padding(.horizontal, 20)

                // ── CTA ──────────────────────────────────────────────
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text(settings.s("已了解，手动填写详情", "Got it — Enter Details Manually"))
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.appOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 4)
        }
    }
}

// Source row with accuracy label
private struct ScanSourceRow: View {
    let icon: String
    let color: Color
    let title: String
    let accuracy: String
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.18)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            Text(title).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
            Spacer()
            Text(accuracy)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.appOnSurfaceVariant)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.appOutlineVariant.opacity(0.5))
                    .frame(height: 0.5).padding(.leading, 62)
            }
        }
    }
}

// Confidence bar row
private struct ConfidenceRow: View {
    let field: String
    let pct: Double   // 0.0 – 1.0
    let high: Bool    // true = green/primary, false = orange warning

    var barColor: Color { high ? Color.appPrimary : .orange }

    var body: some View {
        HStack(spacing: 10) {
            Text(field)
                .font(.system(size: 13))
                .foregroundColor(Color.appOnSurface)
                .frame(width: 68, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.appSurfaceHigh).frame(height: 6)
                    Capsule().fill(barColor.opacity(0.75))
                        .frame(width: g.size.width * pct, height: 6)
                        .animation(.easeOut(duration: 0.8), value: pct)
                }
            }
            .frame(height: 6)
            HStack(spacing: 3) {
                if !high {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                }
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(barColor)
            }
            .frame(width: 44, alignment: .trailing)
        }
    }
}

// MARK: - Step 2: Confirm (Form)
struct ConfirmStepView: View {
    @Environment(AppSettings.self) var settings
    @Binding var serviceName: String
    @Binding var amountText: String
    @Binding var billingCycle: Subscription.BillingCycle
    @Binding var nextBillingDate: Date
    @Binding var category: Subscription.Category
    @Binding var currency: Subscription.Currency
    let iconHex: String
    let iconSymbol: String
    var isEditing: Bool = false
    let onSave: () -> Void

    var canSave: Bool {
        !serviceName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var saveLabel: String {
        isEditing ? settings.s("保存修改", "Save Changes") : settings.addButtonLabel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon Preview
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color(hex: iconHex).opacity(0.2)).frame(width: 60, height: 60)
                        Image(systemName: iconSymbol).font(.system(size: 26)).foregroundColor(Color(hex: iconHex))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(serviceName.isEmpty ? settings.serviceNameLabel : serviceName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(serviceName.isEmpty ? Color.appOutline : Color.appOnSurface)
                        Text(settings.iconAutoDetect)
                            .font(.system(size: 12)).foregroundColor(Color.appOnSurfaceVariant)
                    }
                    Spacer()
                }
                .padding(16).glassCard()

                // Fields
                VStack(spacing: 0) {
                    FormField(label: settings.serviceNameLabel, placeholder: settings.serviceNameHint) {
                        TextField(settings.serviceNameHint, text: $serviceName)
                            .formFieldStyle()
                            .multilineTextAlignment(.trailing)
                    }
                    Divider().background(Color.appOutlineVariant.opacity(0.5)).padding(.leading, 16)

                    FormField(label: settings.amountLabel, placeholder: "0.00") {
                        HStack(spacing: 4) {
                            Text(currency.symbol).foregroundColor(Color.appOnSurfaceVariant).font(.system(size: 15))
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .formFieldStyle()
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                    Divider().background(Color.appOutlineVariant.opacity(0.5)).padding(.leading, 16)

                    FormField(label: settings.currencyFieldLabel, placeholder: "") {
                        Picker("", selection: $currency) {
                            ForEach(Subscription.Currency.allCases, id: \.self) { c in
                                Text(c.displayName).tag(c)
                            }
                        }
                        .pickerStyle(.menu).foregroundColor(Color.appPrimary)
                    }
                    Divider().background(Color.appOutlineVariant.opacity(0.5)).padding(.leading, 16)

                    FormField(label: settings.billingCycleLabel, placeholder: "") {
                        Picker("", selection: $billingCycle) {
                            ForEach(Subscription.BillingCycle.allCases, id: \.self) { cycle in
                                Text(settings.billingCycleDisplay(cycle)).tag(cycle)
                            }
                        }
                        .pickerStyle(.menu).foregroundColor(Color.appPrimary)
                    }
                    Divider().background(Color.appOutlineVariant.opacity(0.5)).padding(.leading, 16)

                    FormField(label: settings.nextBillingLabel, placeholder: "") {
                        DatePicker("", selection: $nextBillingDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Divider().background(Color.appOutlineVariant.opacity(0.5)).padding(.leading, 16)

                    FormField(label: settings.categoryLabel, placeholder: "") {
                        Picker("", selection: $category) {
                            ForEach(Subscription.Category.allCases, id: \.self) { cat in
                                Text(settings.categoryDisplay(cat)).tag(cat)
                            }
                        }
                        .pickerStyle(.menu).foregroundColor(Color.appPrimary)
                    }
                }
                .glassCard()

                Button(action: onSave) {
                    Text(saveLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canSave ? Color.appOnPrimary : Color.appOutline)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(canSave ? Color.appPrimary : Color.appSurfaceContainer)
                        .cornerRadius(14)
                }
                .disabled(!canSave)

                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

extension AppSettings {
    var iconAutoDetect: String { s("图标自动识别", "Icon auto-detected from name") }
}

struct FormField<Content: View>: View {
    let label: String
    let placeholder: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.appOnSurface)
                .padding(.leading, 16)
            Spacer()
            content
                .padding(.trailing, 16)
        }
        .frame(minHeight: 52)
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let steps: [String]
    let current: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(i <= current ? Color.appPrimary : Color.appSurfaceContainer)
                            .frame(width: 22, height: 22)
                        if i < current {
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(Color.appOnPrimary)
                        } else {
                            Text("\(i + 1)").font(.system(size: 10, weight: .bold))
                                .foregroundColor(i == current ? Color.appOnPrimary : Color.appOutline)
                        }
                    }
                    Text(steps[i]).font(.system(size: 9, weight: .semibold))
                        .foregroundColor(i <= current ? Color.appPrimary : Color.appOutline).tracking(0.5)
                }
                if i < steps.count - 1 {
                    Rectangle()
                        .fill(i < current ? Color.appPrimary : Color.appOutlineVariant)
                        .frame(height: 1).frame(maxWidth: .infinity).padding(.bottom, 14)
                }
            }
        }
    }
}
