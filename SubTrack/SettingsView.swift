import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(AppSettings.self) var settings
    @Environment(SubscriptionStore.self) var store
    @State private var showEditProfile = false
    @State private var showExportSheet = false
    @State private var showClearAlert = false
    @State private var exportItems: [Any] = []
    @State private var showExportFormatPicker = false
    @State private var showPrivacySheet = false
    @State private var showFeedbackAlert = false
    @State private var showBudgetSheet = false

    /// Reads the actual byte size of the JSON data file on disk.
    private var realDataSize: String {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("subtrack_subscriptions.json")
        let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        switch bytes {
        case 0:              return "0 B"
        case ..<1024:        return "\(bytes) B"
        case ..<(1024*1024): return String(format: "%.1f KB", Double(bytes) / 1024)
        default:             return String(format: "%.2f MB", Double(bytes) / 1_048_576)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(settings.settingsTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appOnSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Profile Card
                Button(action: { showEditProfile = true }) {
                    VStack(spacing: 14) {
                        UserAvatarView(
                            avatarData: settings.userAvatarData,
                            name: settings.userName,
                            size: 80
                        )
                        VStack(spacing: 6) {
                            Text(settings.userName.isEmpty ? settings.s("用户", "User") : settings.userName)
                                .font(.system(size: 20, weight: .semibold)).foregroundColor(Color.appOnSurface)
                            Text(settings.s("点击编辑资料", "Tap to edit profile"))
                                .font(.system(size: 13)).foregroundColor(Color.appPrimary)
                                .padding(.horizontal, 14).padding(.vertical, 4)
                                .background(Color.appPrimary.opacity(0.15)).cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassCard()
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showEditProfile) {
                    EditProfileView()
                        .environment(settings)
                        .preferredColorScheme(settings.colorScheme)
                }

                // Preferences
                SettingsGroup(title: settings.prefsSection) {
                    AppearancePicker(
                        currentIndex: settings.appearanceIndex,
                        label: settings.appearanceLabel,
                        opts: settings.appearanceOpts,
                        onChange: { settings.appearanceIndex = $0 }
                    )
                    SegmentPicker(
                        icon: "globe",
                        color: Color.appPrimary,
                        label: settings.languageLabel,
                        options: ["中文", "EN"],
                        selectedIndex: settings.language,
                        onChange: { settings.language = $0 }
                    )
                    SegmentPicker(
                        icon: "dollarsign.circle.fill",
                        color: Color.appTertiary,
                        label: settings.currencyLabel,
                        options: ["¥ CNY", "$ USD"],
                        selectedIndex: settings.currencyDefault,
                        onChange: { settings.currencyDefault = $0 }
                    )

                    // Budget row
                    Button(action: { showBudgetSheet = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "4CAF50").opacity(0.2))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "gauge.with.dots.needle.33percent")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                            Text(settings.budgetLabel)
                                .font(.system(size: 15))
                                .foregroundColor(Color.appOnSurface)
                            Spacer()
                            Text(settings.monthlyBudget > 0
                                 ? String(format: "%@%.0f", settings.currencyDefault == 0 ? "¥" : "$", settings.monthlyBudget)
                                 : settings.budgetNoneLabel)
                                .font(.system(size: 14))
                                .foregroundColor(Color.appOnSurfaceVariant)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appOutline)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
                        }
                    }
                    .buttonStyle(.plain)

                    // Replay onboarding
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        settings.hasCompletedOnboarding = false
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appPrimary.opacity(0.18))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.appPrimary)
                            }
                            Text(settings.replayOnboardingLabel)
                                .font(.system(size: 15))
                                .foregroundColor(Color.appOnSurface)
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                // Data & Support
                SettingsGroup(title: settings.dataSection) {
                    SettingItem(icon: "hand.raised.fill", color: Color.appPrimary,
                                title: settings.privacyLabel, value: "",
                                action: { showPrivacySheet = true })
                    SettingItem(icon: "bubble.left.fill", color: Color.appTertiary,
                                title: settings.feedbackLabel, value: "",
                                action: {
                                    let email = "feedback@subtrack.app"
                                    if let url = URL(string: "mailto:\(email)"),
                                       UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        showFeedbackAlert = true
                                    }
                                })

                    // Clear Cache
                    Button(action: { showClearAlert = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.appSecondary.opacity(0.2)).frame(width: 34, height: 34)
                                Image(systemName: "trash.fill").font(.system(size: 15)).foregroundColor(Color.appSecondary)
                            }
                            Text(settings.clearCacheLabel).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
                            Spacer()
                            Text(realDataSize)
                                .font(.system(size: 14)).foregroundColor(Color.appOnSurfaceVariant)
                            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.appOutline)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
                        }
                    }
                    .buttonStyle(.plain)

                    // Export
                    Button(action: { showExportFormatPicker = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.appPrimary.opacity(0.2)).frame(width: 34, height: 34)
                                Image(systemName: "square.and.arrow.up.fill").font(.system(size: 15)).foregroundColor(Color.appPrimary)
                            }
                            Text(settings.exportLabel).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.appOutline)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Text("SubTrack Pro v1.0 · © 2026")
                    .font(.system(size: 12)).foregroundColor(Color.appOutline)
                    .padding(.bottom, 90)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        // Export format picker
        .confirmationDialog(
            settings.s("选择导出格式", "Choose Export Format"),
            isPresented: $showExportFormatPicker,
            titleVisibility: .visible
        ) {
            Button("PDF — \(settings.s("精美报告", "Formatted Report"))") {
                let url = generatePDF(subscriptions: store.subscriptions, settings: settings, store: store)
                exportItems = [url]
                showExportSheet = true
            }
            Button("CSV — \(settings.s("表格数据", "Spreadsheet Data"))") {
                let url = csvFileURL(subscriptions: store.subscriptions, settings: settings)
                exportItems = [url]
                showExportSheet = true
            }
            Button(settings.s("取消", "Cancel"), role: .cancel) { }
        }
        // Share sheet
        .sheet(isPresented: $showExportSheet) {
            if let item = exportItems.first as? URL {
                ShareSheet(items: [item])
            }
        }
        // Clear cache alert
        .alert(settings.s("清除所有数据？", "Clear All Data?"), isPresented: $showClearAlert) {
            Button(settings.s("确认清除", "Clear All"), role: .destructive) {
                store.subscriptions = []
            }
            Button(settings.s("取消", "Cancel"), role: .cancel) { }
        } message: {
            Text(settings.s("这将删除所有订阅数据，此操作不可撤销。", "This will delete all subscription data. This action cannot be undone."))
        }
        // Feedback fallback alert (no mail client)
        .alert(settings.s("发送反馈", "Send Feedback"), isPresented: $showFeedbackAlert) {
            Button(settings.s("复制邮箱", "Copy Email")) {
                UIPasteboard.general.string = "feedback@subtrack.app"
            }
            Button(settings.s("取消", "Cancel"), role: .cancel) { }
        } message: {
            Text("feedback@subtrack.app")
        }
        // Budget sheet
        .sheet(isPresented: $showBudgetSheet) {
            BudgetEditView()
                .environment(settings)
                .preferredColorScheme(settings.colorScheme)
        }
        // Privacy Policy sheet
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
                .environment(settings)
        }
    }
}

// MARK: - Share Sheet (UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Settings Group
struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.appOutline)
                .tracking(0.8)
                .padding(.leading, 4)
            VStack(spacing: 0) { content }.glassCard()
        }
    }
}

// MARK: - Setting Item
struct SettingItem: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { row }
                    .buttonStyle(.plain)
            } else {
                row
            }
        }
    }

    private var row: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.2)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            Text(title).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
            Spacer()
            if !value.isEmpty {
                Text(value).font(.system(size: 13)).foregroundColor(Color.appOnSurfaceVariant)
            }
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.appOutline)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
            }
        }
    }
}

// MARK: - Appearance Picker
struct AppearancePicker: View {
    let currentIndex: Int
    let label: String
    let opts: [String]
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.appPrimary.opacity(0.2)).frame(width: 34, height: 34)
                Image(systemName: "circle.lefthalf.filled").font(.system(size: 15)).foregroundColor(Color.appPrimary)
            }
            Text(label).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
            Spacer()
            HStack(spacing: 2) {
                ForEach(opts.indices, id: \.self) { i in
                    Button(opts[i]) { onChange(i) }
                        .font(.system(size: 12, weight: currentIndex == i ? .semibold : .regular))
                        .foregroundColor(currentIndex == i ? Color.appOnPrimary : Color.appOnSurfaceVariant)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(currentIndex == i ? Color.appPrimary : Color.clear)
                        .cornerRadius(6)
                }
            }
            .background(Color.appSurfaceHigh).cornerRadius(8)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
        }
    }
}

// MARK: - Segment Picker (Language / Currency)
struct SegmentPicker: View {
    let icon: String
    let color: Color
    let label: String
    let options: [String]
    let selectedIndex: Int
    let onChange: (Int) -> Void
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.2)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            Text(label).font(.system(size: 15)).foregroundColor(Color.appOnSurface)
            Spacer()
            HStack(spacing: 2) {
                ForEach(options.indices, id: \.self) { i in
                    Button(options[i]) { onChange(i) }
                        .font(.system(size: 12, weight: selectedIndex == i ? .semibold : .regular))
                        .foregroundColor(selectedIndex == i ? Color.appOnPrimary : Color.appOnSurfaceVariant)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(selectedIndex == i ? Color.appPrimary : Color.clear)
                        .cornerRadius(6)
                }
            }
            .background(Color.appSurfaceHigh).cornerRadius(8)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.appOutlineVariant.opacity(0.5)).frame(height: 0.5).padding(.leading, 62)
            }
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileView: View {
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarData: Data?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 32) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                UserAvatarView(avatarData: avatarData, name: name, size: 100)
                                Circle()
                                    .fill(Color.appPrimary)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.appOnPrimary)
                                    )
                                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 4)
                            }
                        }
                        .onChange(of: selectedItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    avatarData = data
                                }
                            }
                        }
                        .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(settings.s("名字", "Name"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.appOnSurfaceVariant)
                                .padding(.horizontal, 4)
                            HStack {
                                TextField(settings.s("你的名字", "Your name"), text: $name)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color.appOnSurface)
                                    .focused($focused)
                                if !name.isEmpty {
                                    Button { name = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.appOutline)
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appSurfaceContainer)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                focused ? Color.appPrimary : Color.appOutlineVariant,
                                                lineWidth: focused ? 1.5 : 0.5
                                            )
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle(settings.s("编辑资料", "Edit Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.s("取消", "Cancel")) { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.s("保存", "Save")) {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { settings.userName = trimmed }
                        if let data = avatarData { settings.userAvatarData = data }
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appPrimary)
                }
            }
            .onAppear {
                name = settings.userName
                avatarData = settings.userAvatarData
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
            }
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss

    private struct PolicySection {
        let icon: String
        let title: String
        let body: String
    }

    private var sections: [PolicySection] {
        settings.language == 0 ? cnSections : enSections
    }

    private let cnSections: [PolicySection] = [
        PolicySection(
            icon: "lock.shield.fill",
            title: "数据存储",
            body: "SubTrack 的所有数据均存储在您的设备本地，不会上传至任何服务器。我们无法访问您的订阅信息。"
        ),
        PolicySection(
            icon: "eye.slash.fill",
            title: "隐私保护",
            body: "我们不收集任何个人身份信息、使用习惯或设备数据。您的隐私完全由您掌控。"
        ),
        PolicySection(
            icon: "bell.fill",
            title: "通知权限",
            body: "仅在您主动设置提醒时，应用才会申请通知权限。推送内容仅包含您设置的订阅提醒，不包含广告。"
        ),
        PolicySection(
            icon: "photo.fill",
            title: "相册权限",
            body: "仅在您上传头像时，应用才会访问相册。图片数据保存在本地，不会外传。"
        ),
        PolicySection(
            icon: "trash.fill",
            title: "数据删除",
            body: "您可以随时在设置页面清除所有数据，也可以直接卸载应用来彻底删除全部内容。"
        ),
        PolicySection(
            icon: "envelope.fill",
            title: "联系我们",
            body: "如有任何疑问，请发送邮件至 feedback@subtrack.app，我们会在 3 个工作日内回复。"
        ),
    ]

    private let enSections: [PolicySection] = [
        PolicySection(
            icon: "lock.shield.fill",
            title: "Data Storage",
            body: "All SubTrack data is stored locally on your device and never uploaded to any server. We have no access to your subscription information."
        ),
        PolicySection(
            icon: "eye.slash.fill",
            title: "Privacy Protection",
            body: "We collect no personal information, usage data, or device identifiers. Your privacy is entirely in your control."
        ),
        PolicySection(
            icon: "bell.fill",
            title: "Notifications",
            body: "The app only requests notification permission when you actively set a reminder. Push notifications contain only your subscription reminders — no ads."
        ),
        PolicySection(
            icon: "photo.fill",
            title: "Photo Library",
            body: "The app accesses your photo library only when you upload a profile avatar. Images are stored locally and never shared."
        ),
        PolicySection(
            icon: "trash.fill",
            title: "Data Deletion",
            body: "You can clear all data at any time from the Settings page, or uninstall the app to permanently remove everything."
        ),
        PolicySection(
            icon: "envelope.fill",
            title: "Contact Us",
            body: "For any questions, email us at feedback@subtrack.app. We respond within 3 business days."
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header blurb
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.appPrimary.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.appPrimary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settings.s("SubTrack 隐私政策", "SubTrack Privacy Policy"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.appOnSurface)
                                Text(settings.s("最后更新：2026年3月", "Last updated: March 2026"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.appOnSurfaceVariant)
                            }
                        }
                        .padding(16)
                        .glassCard()

                        // Policy sections
                        VStack(spacing: 0) {
                            ForEach(Array(sections.enumerated()), id: \.offset) { idx, section in
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appPrimary.opacity(0.12))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: section.icon)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.appPrimary)
                                    }
                                    .padding(.top, 1)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(section.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface)
                                        Text(section.body)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.appOnSurfaceVariant)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineSpacing(3)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .overlay(alignment: .bottom) {
                                    if idx < sections.count - 1 {
                                        Rectangle()
                                            .fill(Color.appOutlineVariant.opacity(0.4))
                                            .frame(height: 0.5)
                                            .padding(.leading, 62)
                                    }
                                }
                            }
                        }
                        .glassCard()

                        Text(settings.s("SubTrack Pro v1.0 · © 2026 · 保留所有权利",
                                        "SubTrack Pro v1.0 · © 2026 · All rights reserved"))
                            .font(.system(size: 11))
                            .foregroundColor(Color.appOutline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(settings.s("隐私政策", "Privacy Policy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.s("关闭", "Close")) { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

// MARK: - Budget Edit Sheet
private struct BudgetEditView: View {
    @Environment(AppSettings.self) var settings
    @Environment(\.dismiss) var dismiss
    @State private var budgetText = ""

    private var symbol: String { settings.currencyDefault == 0 ? "¥" : "$" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle().fill(Color(hex: "4CAF50").opacity(0.15)).frame(width: 72, height: 72)
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                    .padding(.top, 32)

                    VStack(spacing: 6) {
                        Text(settings.budgetLabel)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.appOnSurface)
                        Text(settings.s(
                            "设置后，首页支出卡片将显示预算进度",
                            "Dashboard will show your budget progress"
                        ))
                        .font(.system(size: 14))
                        .foregroundColor(Color.appOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    // Input
                    HStack(spacing: 10) {
                        Text(symbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.appOnSurfaceVariant)
                        TextField("0", text: $budgetText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color.appOnSurface)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40).padding(.vertical, 20)
                    .background(Color.appSurfaceContainer)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            let val = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
                            settings.monthlyBudget = val
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            Text(settings.s("保存预算", "Save Budget"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.appOnPrimary)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.appPrimary).cornerRadius(14)
                        }

                        if settings.monthlyBudget > 0 {
                            Button {
                                settings.monthlyBudget = 0
                                dismiss()
                            } label: {
                                Text(settings.s("清除预算", "Clear Budget"))
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.appSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle(settings.setBudgetLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.s("取消", "Cancel")) { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
            .onAppear {
                if settings.monthlyBudget > 0 {
                    budgetText = String(format: "%.0f", settings.monthlyBudget)
                }
            }
        }
    }
}
