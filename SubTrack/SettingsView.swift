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

                // Account
                SettingsGroup(title: settings.accountSection) {
                    SettingItem(icon: "phone.fill",   color: Color.appPrimary,          title: settings.s("手机号码", "Phone Number"), value: "+86 138-0000-0000")
                    SettingItem(icon: "apple.logo",   color: Color.appOnSurfaceVariant, title: "Apple ID",    value: "a.thompson@icloud.com")
                    SettingItem(icon: "lock.fill",    color: Color.appTertiary,         title: "FaceTime",    value: settings.s("已启用", "Enabled"))
                    SettingItem(icon: "message.fill", color: Color(hex: "25D366"),      title: "WhatsApp",    value: settings.s("已连接", "Connected"), isLast: true)
                }
                .padding(.horizontal, 20)

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
                        onChange: { settings.currencyDefault = $0 },
                        isLast: true
                    )
                }
                .padding(.horizontal, 20)

                // Data & Support
                SettingsGroup(title: settings.dataSection) {
                    SettingItem(icon: "hand.raised.fill",  color: Color.appOutline, title: settings.privacyLabel,  value: "")
                    SettingItem(icon: "bubble.left.fill",  color: Color.appOutline, title: settings.feedbackLabel, value: "")

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

    var body: some View {
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
