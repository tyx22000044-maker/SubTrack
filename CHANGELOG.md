# CHANGELOG · SubTrack 开发日志

> 记录每一次迭代的完整内容，按时间倒序排列。
> Full development history, newest first.
>
> 格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)

---

## [0.4.0] — 2026-03-26 · 交互体验修复 UX Polish

本次迭代集中修复了 4 个最影响使用体验的问题。
Focused sprint fixing the 4 highest-impact UX gaps.

### ✅ 新增 / Added
- **编辑订阅**：长按或点击详情页「编辑」按钮，可修改已有订阅的所有字段（金额、周期、分类等），修改后数据实时持久化。Edit Subscription: tap "Edit" in the detail view to modify any field, changes persist immediately.
- **搜索功能**：订阅列表页搜索栏，点击放大镜展开，实时过滤订阅名称，与筛选器（活跃/即将到期/已暂停）联动生效。Live search bar in Subscriptions with animated show/hide, combined with filter pills.
- **"查看全部 →" 跳转**：Dashboard 首页的「查看全部」按钮现在直接跳转到订阅管理 Tab。"See All →" on Dashboard now navigates to the Subscriptions tab.

### 🔧 修复 / Fixed
- **Insights 真实数据**：月度趋势图不再使用随机乘数模拟，改为根据每个订阅的 `startDate` 实际计算各月支出，新增的订阅只在其开始日期之后才计入历史数据。Monthly trend chart now calculates real historical data based on each subscription's start date.
- **Insights 货币符号**：趋势图和统计卡片现在根据「货币」设置显示正确的 ¥/$ 符号，并做汇率换算。Stats now respect the user's preferred currency (CNY/USD) with proper conversion.

---

## [0.3.0] — 2026-03-24 · 数据管理 & 用户档案 Data & Profile

### ✅ 新增 / Added
- **导出功能**：支持导出 PDF 报告（含品牌设计、订阅明细表格、月度总支出）和 CSV 表格数据，通过系统分享面板分享到任意 App。Export subscriptions as a branded PDF report or CSV spreadsheet via share sheet.
- **清除缓存**：设置页一键清空所有订阅数据（带二次确认弹窗）。Clear all data with a confirmation alert.
- **用户头像**：Onboarding 和设置页均支持从相册选取头像，展示为圆形裁剪；无头像时自动显示姓名首字母渐变图标。Photo picker for avatar with initials fallback.
- **编辑个人资料**：设置页点击头像卡片即可进入编辑界面，修改昵称和头像，即时生效。Tap profile card in Settings to edit name and avatar.
- **推送通知**：订阅详情页和即将续费卡片均可设置本地提醒，在到期前 3 天上午 9:00 推送（中英双语内容）。权限拒绝时引导跳转系统设置。Local push notifications 3 days before renewal, bilingual, with permission handling.
- **通知状态持久化**：App 启动时自动重新注册所有已设置的提醒。Notifications rescheduled on every app launch.

### 🔧 修复 / Fixed
- **订阅详情「设置提醒」状态**：进入详情页时自动检查该订阅是否已有提醒，按钮状态实时同步。Reminder button correctly reflects existing scheduled state.
- **「标记已取消」同步取消通知**：取消订阅时自动撤销已设置的推送提醒。Cancelling a subscription also cancels its notification.

---

## [0.2.0] — 2026-03-14 · 核心功能完整版 Core Feature Complete

### ✅ 新增 / Added
- **Onboarding 引导流程**：3 页滑动引导（欢迎 → 设置头像&昵称 → 完成），含自定义滑动按钮动效（拖拽超过 75% 触发）。3-page onboarding with custom swipe-to-continue button animation.
- **空白状态页**：首次使用时 Dashboard 和订阅列表均显示动态空白引导，弹簧动画入场。Empty state views with spring animations on Dashboard and Subscriptions.
- **用户个人资料**：用户名和头像存储于 UserDefaults，跨 App 重启保留。User name and avatar persist via UserDefaults.
- **订阅详情页**：查看完整付款信息、付款历史（最近 3 次）、累计支出、首次订阅时间；支持标记取消、设置提醒、查看收据（即将上线）。Full subscription detail view with payment history and cumulative spend.
- **订阅列表筛选 & 排序**：支持按状态筛选（全部/活跃/即将到期/已暂停），支持按续费时间/金额/分类/名称排序。Filter and sort subscriptions by multiple criteria.
- **进度条倒计时**：首页订阅行显示账单周期进度条，根据 `nextBillingDate` 和周期长度实时计算。Real billing cycle progress bar in Dashboard rows.
- **多货币支持**：CNY/USD 双货币，固定汇率 ¥7.25/$1，首页总支出自动换算统一货币显示。Multi-currency with exchange rate conversion on Dashboard total.
- **App Icon**：自定义应用图标。Custom app icon.
- **GitHub 同步**：项目托管至 GitHub，通过 SSH 认证完成远程配置。Project hosted on GitHub via SSH.

### 🔧 修复 / Fixed
- **Light 模式对比度**：`appOnPrimary` 颜色在浅色模式下改为白色（原深蓝色在浅色背景上不可读）。Light mode primary button text color fixed from dark navy to white.
- **`enum Tab` 命名冲突**：iOS 26 SwiftUI 新增了原生 `Tab` 类型，将自定义枚举重命名为 `AppTab` 解决冲突。Renamed `Tab` enum to `AppTab` to avoid iOS 26 SwiftUI conflict.
- **`@Observable` 迁移**：将所有 `ObservableObject` 替换为 `@Observable`，`@StateObject` → `@State`，`@EnvironmentObject` → `@Environment`，适配 Swift 6 严格并发。Full migration from ObservableObject to @Observable for Swift 6 compliance.
- **`formFieldStyle()` 作用域**：将扩展从 `TextField` 移至 `View` 以修复编译错误。Moved `formFieldStyle()` extension from `TextField` to `View`.
- **表单字段对齐**：添加订阅界面所有输入项统一右对齐，视觉一致性修复。Form field alignment fixed across all input rows.

---

## [0.1.0] — 2026-03-09 · 项目初始化 Initial Release

### ✅ 新增 / Added
- **项目立项**：确定产品方向（iOS 订阅管理 App），完成 PRD v0.1 ~ v0.4，包含用户故事、功能优先级矩阵、AI 功能 Spec。Product direction set; PRD written across 4 versions.
- **HTML 原型**：8 个高保真交互页面，Digital Obsidian 设计系统（暗色 `#10141a`，主色 `#adc6ff`/`#005BC1`，玻璃拟态卡片）。Hi-fi HTML prototype with Digital Obsidian design system.
- **Xcode 工程搭建**：创建 SwiftUI 项目，配置文件结构，集成 Digital Obsidian 主题系统（`UIColor dynamicProvider` 实现真正的 Light/Dark 自适应）。Xcode project bootstrapped with adaptive theme system.
- **数据模型**：`Subscription`（Codable）、`SubscriptionStore`（@Observable，JSON 持久化）、`AppSettings`（外观/语言/货币，UserDefaults 持久化）。Core data models with JSON persistence.
- **四大主页面**：Dashboard、Subscriptions、Insights（月度趋势图 + 分类分析）、Settings（外观/语言/货币切换）。All 4 main screens with navigation.
- **添加订阅流程**：3 步表单（选择方式 → AI 扫描 → 手动填写），服务名称自动识别图标（Netflix、Spotify 等 15 个预设）。3-step add subscription flow with automatic icon detection.
- **中英双语**：全界面实时切换中文/英文，默认中文。Real-time bilingual switching (ZH/EN), default Chinese.
- **Light / Dark / Auto 主题**：三档外观切换，`UIColor dynamicProvider` 实现跨组件自适应。3-mode appearance switching.
- **数据持久化**：JSON 文件存储，App 重启数据不丢失。JSON persistence survives app restarts.

---

## 待开发 · Upcoming

- [ ] AI 账单扫描识别（Vision 框架）AI bill scanning via Vision
- [ ] Home Screen Widget
- [ ] iCloud 数据同步 iCloud sync
- [ ] App Store 上架 App Store submission
- [ ] 社区评分功能 Community ratings

---

*SubTrack · 谈昀轩 · 2025–2026 · [GitHub](https://github.com/tyx22000044-maker/SubTrack)*
