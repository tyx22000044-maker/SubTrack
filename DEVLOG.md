# SubTrack 开发日志 · Development Log

> 这个文件记录 SubTrack 的完整产品与开发历程。每次新对话开始时，AI 应先读取此文件以恢复上下文。

---

## 项目背景

- **项目名称**：SubTrack — iOS 订阅管理 App
- **开发者**：谈昀轩（tyx22000044-maker）
- **目标**：模拟 AI 产品经理完整工作流，作为求职 Portfolio 项目
- **求职方向**：产品经理 / 管培生（AI + 互联网方向，2026届应届生）
- **开发方式**：零代码基础，全程借助 Claude Code AI 辅助开发
- **GitHub**：https://github.com/tyx22000044-maker/SubTrack
- **技术栈**：SwiftUI (iOS 26) · Swift · @Observable · JSON 持久化

---

## 设计系统

- **主题名称**：Digital Obsidian
- **暗色背景**：`#10141a`
- **主色调（暗）**：`#adc6ff`（浅蓝）
- **主色调（亮）**：`#005BC1`（深蓝）
- **支持模式**：Light / Dark / Auto（UIColor dynamicProvider 实现真正自适应）
- **字体**：SF Pro（系统默认）

---

## 已完成功能（截至 2026-03-26）

### 核心功能
- [x] 订阅管理（增删改查）
- [x] JSON 本地持久化（App 重启数据不丢失）
- [x] 多货币支持（CNY/USD，含汇率换算 ¥7.25/$1）
- [x] 中英双语界面（实时切换，默认中文）
- [x] Light / Dark / Auto 主题真实切换

### 页面
- [x] Dashboard（月度支出卡片、即将续费、订阅列表）
- [x] Subscriptions（筛选 + 排序 + 订阅详情页）
- [x] Insights（月度趋势图、支出分类、3M/6M/1Y 切换）
- [x] Settings（外观/语言/货币设置）

### 用户体验
- [x] Onboarding 引导流程（3页，含滑动按钮动效）
- [x] 真实用户资料（名字 + 头像，从相册选取）
- [x] 空白状态页（首次使用引导）
- [x] 推送通知（到期前3天提醒，支持开关）
- [x] App Icon（自定义图标）

### 待完成
- [ ] 导出数据（CSV + PDF）← 当前正在开发
- [ ] 清除缓存
- [ ] 推送通知（Home Screen Widget）
- [ ] iCloud 同步
- [ ] AI 账单扫描（Vision 框架）
- [ ] App Store 上架

---

## 文件结构

```
SubTrack/
├── SubTrackApp.swift        App 入口，Splash 屏
├── ContentView.swift        主导航（Tab Bar + Onboarding 入口）
├── AppData.swift            数据模型（Subscription, SubscriptionStore, AppSettings）
├── Theme.swift              设计系统（色彩、GlassCard、formFieldStyle）
├── NotificationManager.swift 推送通知管理
├── OnboardingView.swift     用户引导流程（3页）
├── DashboardView.swift      首页
├── SubscriptionsView.swift  订阅列表
├── SubscriptionDetailView.swift 订阅详情
├── InsightsView.swift       财务洞察
├── SettingsView.swift       设置页（含 EditProfileView）
├── AddSubscriptionView.swift 添加订阅
├── SplashView.swift         启动画面
└── AppIconView.swift        App 图标
```

---

## 关键设计决策

| 决策 | 原因 |
|------|------|
| JSON 持久化而非 SwiftData | SwiftUI 26 的 SwiftData 与 @Observable 配合有兼容性风险，JSON 更稳定 |
| 默认语言中文 | 目标用户为中国市场 |
| 默认货币 CNY | 与语言保持一致 |
| AI 功能标注"敬请期待" | 避免空功能影响用户体验 |
| 空白状态代替样本数据 | 提升真实感，避免用户困惑 |
| Add Subscription 用 v1 方案 | 更简洁，支持字体更换 |

---

## PRD 更新记录

- **v0.1**（项目初期）：基础订阅追踪需求
- **v0.2**：加入 AI 功能 Spec（账单识别、智能建议）
- **v0.3**：加入多货币、多语言需求
- **v0.4**（当前）：加入通知、导出、用户档案需求

---

## 给 AI 的注意事项

1. 用户**完全没有代码能力**，所有代码由 AI 编写
2. 编译错误需要立即修复，用户会截图反馈
3. iOS 26 使用新的 `Tab` 类型（与旧代码冲突），已用 `AppTab` 重命名
4. `@Observable` 代替 `ObservableObject`，`@State` 代替 `@StateObject`
5. 所有颜色用 `UIColor dynamicProvider` 实现 Light/Dark 自适应
6. 新文件创建后需要告知用户拖入 Xcode 项目
