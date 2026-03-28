import SwiftUI

// MARK: - App Settings
@Observable
class AppSettings {
    var appearanceIndex: Int {
        didSet { UserDefaults.standard.set(appearanceIndex, forKey: "st_appearance") }
    }
    var language: Int {
        didSet { UserDefaults.standard.set(language, forKey: "st_language") }
    }
    var currencyDefault: Int {
        didSet { UserDefaults.standard.set(currencyDefault, forKey: "st_currency") }
    }
    var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "st_userName") }
    }
    var userAvatarData: Data? {
        didSet { UserDefaults.standard.set(userAvatarData, forKey: "st_avatarData") }
    }
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "st_onboarded") }
    }
    /// 0 means no budget set
    var monthlyBudget: Double {
        didSet { UserDefaults.standard.set(monthlyBudget, forKey: "st_monthlyBudget") }
    }

    init() {
        let d = UserDefaults.standard
        appearanceIndex        = d.object(forKey: "st_appearance")     != nil ? d.integer(forKey: "st_appearance") : 1
        language               = d.object(forKey: "st_language")       != nil ? d.integer(forKey: "st_language")   : 0
        currencyDefault        = d.object(forKey: "st_currency")       != nil ? d.integer(forKey: "st_currency")   : 0
        userName               = d.string(forKey: "st_userName") ?? ""
        userAvatarData         = d.data(forKey: "st_avatarData")
        hasCompletedOnboarding = d.bool(forKey: "st_onboarded")
        monthlyBudget          = d.object(forKey: "st_monthlyBudget")  != nil ? d.double(forKey: "st_monthlyBudget") : 0
    }

    var colorScheme: ColorScheme? {
        switch appearanceIndex {
        case 0: return .light
        case 1: return .dark
        default: return nil
        }
    }
}

// MARK: - Localization helper
extension AppSettings {
    func s(_ zh: String, _ en: String) -> String { language == 0 ? zh : en }

    // Tab
    var tabHome: String          { s("首页", "Home") }
    var tabSubscriptions: String { s("订阅", "Subscriptions") }
    var tabInsights: String      { s("洞察", "Insights") }
    var tabSettings: String      { s("设置", "Settings") }

    // Dashboard
    var monthlySpendingLabel: String  { s("月度支出", "MONTHLY SPENDING") }
    var projectedLabel: String        { s("预计月支出", "Projected / Month") }
    var vsLastMonthLabel: String      { s("较上月", "vs last month") }
    var priorityRenewalsLabel: String { s("即将续费", "Priority Renewals") }
    var monthlySubsLabel: String      { s("本月订阅", "Monthly Subscriptions") }
    var seeAllLabel: String           { s("查看全部 →", "See All →") }
    var remindMeLabel: String         { s("设置提醒", "Remind Me") }

    // Subscriptions
    var subscriptionsTitle: String { s("订阅管理", "Subscriptions") }
    var filterAll: String          { s("全部", "All") }
    var filterActive: String       { s("活跃", "Active") }
    var filterExpiring: String     { s("即将到期", "Expiring Soon") }
    var filterPaused: String       { s("已暂停", "Paused") }

    // Insights
    var insightsTitle: String     { s("财务洞察", "Financial Insights") }
    var totalSpendLabel: String   { s("总支出", "Total Spend") }
    var monthlyAvgLabel: String   { s("月均支出", "Monthly Avg") }
    var peakMonthLabel: String    { s("峰值月份", "Peak Month") }
    var monthlyTrendLabel: String { s("月度趋势", "Monthly Trend") }
    var breakdownLabel: String    { s("支出分类", "Expenditure Breakdown") }
    var aiSugLabel: String        { s("AI 建议", "AI Suggestions") }

    // Settings
    var settingsTitle: String     { s("设置", "Settings") }
    var accountSection: String    { s("账户", "ACCOUNT") }
    var prefsSection: String      { s("偏好设置", "PREFERENCES") }
    var dataSection: String       { s("数据与支持", "DATA & SUPPORT") }
    var appearanceLabel: String   { s("外观", "Appearance") }
    var languageLabel: String     { s("语言", "Language") }
    var currencyLabel: String     { s("货币", "Currency") }
    var privacyLabel: String      { s("隐私政策", "Privacy Policy") }
    var feedbackLabel: String     { s("反馈建议", "Give Feedback") }
    var clearCacheLabel: String   { s("清除缓存", "Clear Cache") }
    var exportLabel: String       { s("导出订阅数据", "Export Subscriptions") }
    var appearanceOpts: [String]  { language == 0 ? ["浅色","深色","自动"] : ["Light","Dark","Auto"] }

    // Add Subscription
    var addSubTitle: String         { s("添加订阅", "Add Subscription") }
    var aiSubtitle: String          { s("AI 智能账单识别", "AI-powered bill recognition") }
    var tapToScanLabel: String      { s("点击扫描或上传", "Tap to Scan or Upload") }
    var orLabel: String             { s("或", "OR") }
    var enterManuallyLabel: String  { s("手动输入", "Enter Manually") }
    var supportedTypesLabel: String { s("支持类型", "SUPPORTED TYPES") }
    var appStoreOrderLabel: String  { s("App Store 订单", "App Store Order") }
    var emailReceiptLabel: String   { s("邮件收据", "Email Receipt") }
    var bankStatementLabel: String  { s("银行对账单", "Bank Statement") }
    var serviceNameLabel: String    { s("服务名称", "Service Name") }
    var serviceNameHint: String     { s("如 Netflix、Spotify", "e.g. Netflix, Spotify") }
    var amountLabel: String         { s("金额", "Amount") }
    var billingCycleLabel: String   { s("账单周期", "Billing Cycle") }
    var nextBillingLabel: String    { s("下次扣款日", "Next Billing Date") }
    var categoryLabel: String       { s("分类", "Category") }
    var addButtonLabel: String      { s("添加订阅", "Add Subscription") }
    var currencyFieldLabel: String  { s("货币", "Currency") }

    // Detail
    var paymentInfoLabel: String      { s("付款信息", "PAYMENT INFO") }
    var serviceFeeLabel: String       { s("服务费用", "Service Fee") }
    var nextPaymentLabel: String      { s("下次扣款", "Next Payment") }
    var firstSubscribedLabel: String  { s("首次订阅", "First Subscribed") }
    var totalSpentLabel: String       { s("累计支出", "Total Spent") }
    var paymentHistoryLabel: String   { s("付款记录", "PAYMENT HISTORY") }
    var communityRatingLabel: String  { s("社区评分", "COMMUNITY RATING") }
    var setReminderLabel: String      { s("设置续费提醒", "Set Renewal Reminder") }
    var viewReceiptLabel: String      { s("查看收据", "View Receipt") }
    var cancelSubLabel: String        { s("标记为已取消", "Mark as Cancelled") }
    var editLabel: String             { s("编辑", "Edit") }
    var monthsLabel: String           { s("个月", " months") }

    // Status badges
    var activeLabel: String    { s("活跃", "ACTIVE") }
    var pausedLabel: String    { s("已暂停", "PAUSED") }
    var cancelledLabel: String { s("已取消", "CANCELLED") }

    // Budget
    var budgetLabel: String          { s("月度预算", "Monthly Budget") }
    var setBudgetLabel: String        { s("设置预算", "Set Budget") }
    var budgetNoneLabel: String       { s("未设置", "Not set") }
    var budgetRemainingLabel: String  { s("剩余", "remaining") }
    var budgetExceededLabel: String   { s("超出预算", "Over budget") }

    // Reactivate
    var reactivateLabel: String       { s("重新激活", "Reactivate") }

    // Onboarding strings (bilingual)
    var onboardingSubtitle: String    { s("智能追踪每一笔订阅\n掌控你的数字消费", "Smart tracking for every subscription\nTake control of your digital spending") }
    var onboardingSwipeLabel: String  { s("滑动开始", "Swipe to Begin") }
    var onboardingNameTitle: String   { s("你叫什么名字？", "What's your name?") }
    var onboardingNameSubtitle: String { s("这将显示在你的个人主页", "This will appear on your profile") }
    var onboardingNameHint: String    { s("输入你的名字", "Enter your name") }
    var onboardingNextLabel: String   { s("下一步", "Next") }
    var onboardingEnterLabel: String  { s("进入 SubTrack", "Enter SubTrack") }
    var onboardingFeature1: String    { s("添加你的订阅服务", "Add your subscriptions") }
    var onboardingFeature2: String    { s("追踪每月支出趋势", "Track monthly spending") }
    var onboardingFeature3: String    { s("到期前收到提醒通知", "Get notified before renewal") }
    var onboardingReady: String       { s("SubTrack 已就绪", "SubTrack is ready") }
    var onboardingGreeting: String    { s("你好，", "Hello, ") }

    // Settings extras
    var replayOnboardingLabel: String { s("重看新手引导", "Replay Onboarding") }
    var annualSummaryLabel: String    { s("今年支出", "Year to Date") }

    // Billing cycle display
    func billingCycleDisplay(_ cycle: Subscription.BillingCycle) -> String {
        switch cycle {
        case .monthly: return s("月付", "Monthly")
        case .yearly:  return s("年付", "Yearly")
        case .weekly:  return s("周付", "Weekly")
        }
    }
    func categoryDisplay(_ cat: Subscription.Category) -> String {
        switch cat {
        case .entertainment: return s("娱乐", "Entertainment")
        case .productivity:  return s("效率工具", "Productivity")
        case .cloud:         return s("云服务", "Cloud")
        case .music:         return s("音乐", "Music")
        case .other:         return s("其他", "Other")
        }
    }
}

// MARK: - Subscription Model
struct Subscription: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var billingCycle: BillingCycle
    var nextBillingDate: Date
    var category: Category
    var status: Status
    var iconHex: String
    var iconSymbol: String
    var currency: Currency = .usd
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()

    enum BillingCycle: String, Codable, CaseIterable {
        case monthly = "Monthly"
        case yearly  = "Yearly"
        case weekly  = "Weekly"
    }
    enum Category: String, Codable, CaseIterable {
        case entertainment = "Entertainment"
        case productivity  = "Productivity"
        case cloud         = "Cloud"
        case music         = "Music"
        case other         = "Other"
    }
    enum Status: String, Codable, CaseIterable {
        case active    = "Active"
        case paused    = "Paused"
        case cancelled = "Cancelled"
    }
    enum Currency: String, Codable, CaseIterable {
        case usd = "USD"
        case cny = "CNY"
        var symbol: String { self == .cny ? "¥" : "$" }
        var displayName: String { self == .cny ? "人民币 (¥)" : "美元 ($)" }
    }

    var monthlyAmount: Double {
        switch billingCycle {
        case .monthly: return amount
        case .yearly:  return amount / 12
        case .weekly:  return amount * 4.33
        }
    }
    var daysUntilRenewal: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0)
    }
    var isExpiringSoon: Bool { daysUntilRenewal <= 7 }

    var billingCycleDays: Int {
        switch billingCycle {
        case .monthly: return 30
        case .yearly:  return 365
        case .weekly:  return 7
        }
    }
    /// 0.0 = just renewed, 1.0 = due today
    var cycleProgress: Double {
        let total = Double(billingCycleDays)
        let remaining = Double(daysUntilRenewal)
        return min(1.0, max(0.0, 1.0 - remaining / total))
    }

    var totalMonthsSubscribed: Int {
        max(1, Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 1)
    }
    var totalSpent: Double { monthlyAmount * Double(totalMonthsSubscribed) }

    func formattedAmount() -> String {
        String(format: "%@%.2f", currency.symbol, amount)
    }
    func formattedMonthly() -> String {
        String(format: "%@%.2f", currency.symbol, monthlyAmount)
    }
}

// MARK: - Subscription Store  (with JSON persistence)
@Observable
class SubscriptionStore {
    var subscriptions: [Subscription] = [] {
        didSet { save() }
    }

    static let usdToCnyRate: Double = 7.25

    // MARK: Persistence
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("subtrack_subscriptions.json")
    }

    init() {
        subscriptions = Self.loadFromDisk() ?? []
    }

    private static func loadFromDisk() -> [Subscription]? {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Subscription].self, from: data) else { return nil }
        return decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(subscriptions) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    // MARK: Computed
    var totalMonthlySpend: Double {
        subscriptions.filter { $0.status == .active }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var cnyMonthlyTotal: Double {
        subscriptions.filter { $0.status == .active && $0.currency == .cny }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var usdMonthlyTotal: Double {
        subscriptions.filter { $0.status == .active && $0.currency == .usd }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var totalInCNY: Double { cnyMonthlyTotal + usdMonthlyTotal * SubscriptionStore.usdToCnyRate }
    var totalInUSD: Double { usdMonthlyTotal + cnyMonthlyTotal / SubscriptionStore.usdToCnyRate }
    var upcomingRenewals: [Subscription] {
        subscriptions.filter { $0.status == .active && $0.isExpiringSoon }
            .sorted { $0.daysUntilRenewal < $1.daysUntilRenewal }
    }

    // MARK: Mutations
    func add(_ subscription: Subscription) {
        subscriptions.insert(subscription, at: 0)
    }
    func update(_ subscription: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[idx] = subscription
        }
    }

    func togglePause(_ id: UUID) {
        if let idx = subscriptions.firstIndex(where: { $0.id == id }) {
            if subscriptions[idx].status == .paused {
                // Resuming — advance nextBillingDate to future if it expired during pause
                subscriptions[idx].status = .active
                subscriptions[idx].nextBillingDate = advanceToFuture(
                    subscriptions[idx].nextBillingDate,
                    cycle: subscriptions[idx].billingCycle
                )
            } else {
                subscriptions[idx].status = .paused
            }
        }
    }

    func reactivate(_ id: UUID) {
        if let idx = subscriptions.firstIndex(where: { $0.id == id }) {
            subscriptions[idx].status = .active
            subscriptions[idx].nextBillingDate = advanceToFuture(
                subscriptions[idx].nextBillingDate,
                cycle: subscriptions[idx].billingCycle
            )
        }
    }

    /// Advances a date forward by billing cycle until it's in the future.
    private func advanceToFuture(_ date: Date, cycle: Subscription.BillingCycle) -> Date {
        let cal = Calendar.current
        let (component, value): (Calendar.Component, Int) = {
            switch cycle {
            case .monthly: return (.month,      1)
            case .yearly:  return (.year,       1)
            case .weekly:  return (.weekOfYear, 1)
            }
        }()
        var next = date
        while next <= Date() {
            next = cal.date(byAdding: component, value: value, to: next) ?? next
        }
        return next
    }

    func markCancelled(_ id: UUID) {
        if let idx = subscriptions.firstIndex(where: { $0.id == id }) {
            subscriptions[idx].status = .cancelled
            NotificationManager.shared.cancelReminder(for: id)
        }
    }
    func delete(_ id: UUID) {
        NotificationManager.shared.cancelReminder(for: id)
        subscriptions.removeAll { $0.id == id }
    }
}

// MARK: - Sample Data
let sampleSubscriptions: [Subscription] = {
    func date(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
    func start(_ monthsAgo: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -monthsAgo, to: Date()) ?? Date()
    }
    return [
        Subscription(name: "Netflix",     amount: 15.49,  billingCycle: .monthly, nextBillingDate: date(12), category: .entertainment, status: .active, iconHex: "E50914", iconSymbol: "play.rectangle.fill",  currency: .usd, startDate: start(18)),
        Subscription(name: "Spotify",     amount: 9.99,   billingCycle: .monthly, nextBillingDate: date(20), category: .music,          status: .active, iconHex: "1DB954", iconSymbol: "music.note",           currency: .usd, startDate: start(24)),
        Subscription(name: "Adobe CC",    amount: 599.88, billingCycle: .yearly,  nextBillingDate: date(3),  category: .productivity,   status: .active, iconHex: "FF3A2D", iconSymbol: "a.circle.fill",        currency: .usd, startDate: start(36)),
        Subscription(name: "Apple One",   amount: 68.00,  billingCycle: .monthly, nextBillingDate: date(2),  category: .entertainment,  status: .active, iconHex: "98989D", iconSymbol: "apple.logo",           currency: .cny, startDate: start(28)),
        Subscription(name: "Disney+",     amount: 7.99,   billingCycle: .monthly, nextBillingDate: date(25), category: .entertainment,  status: .active, iconHex: "113CCF", iconSymbol: "star.circle.fill",     currency: .usd, startDate: start(12)),
        Subscription(name: "iCloud+ 2TB", amount: 68.00,  billingCycle: .monthly, nextBillingDate: date(18), category: .cloud,          status: .active, iconHex: "3478F6", iconSymbol: "icloud.fill",          currency: .cny, startDate: start(30)),
    ]
}()
