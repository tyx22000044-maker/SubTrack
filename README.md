# SubTrack 📱

**智能订阅管理 · AI-Powered Subscription Tracker**

> 一款原生 iOS 订阅管理应用，同时也是一个完整的 **AI 产品经理工作流实践项目**。
> A native iOS subscription tracker, and a complete demonstration of an AI-native PM workflow.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2026-blue?logo=apple)
![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey?logo=apple)
![Status](https://img.shields.io/badge/Status-In%20Development-green)

---

## 🎯 项目背景 · Background

SubTrack 不只是一个 App，更是我模拟 AI 产品经理完整工作流的实战项目。

从零开始，**全程借助 AI 工具**，独立完成了：

```
用户调研 → PRD 文档 → 高保真交互原型 → iOS 原生开发 → 持续迭代
User Research → PRD → Hi-fi Prototype → Native iOS Dev → Iteration
```

> 零代码基础，AI 协作开发，产出可运行的真实产品。
> Zero coding background. AI-assisted development. Shipped a working product.

---

## ✨ 核心功能 · Features

| 功能 | 描述 |
|------|------|
| 📊 **订阅总览** | 月度支出汇总，多货币自动换算（CNY/USD） |
| ⏰ **续费提醒** | 到期倒计时进度条，即将续费高亮预警 |
| 📈 **财务洞察** | 3个月/6个月/1年支出趋势图与分类分析 |
| ➕ **智能添加** | 手动录入 + AI 扫描识别（即将上线） |
| 🎨 **主题切换** | Light / Dark / Auto 自适应外观 |
| 🌐 **中英双语** | 支持中文简体与英语实时切换 |
| 👤 **用户档案** | 头像、昵称、个人资料管理 |
| 🚀 **Onboarding** | 全新用户引导流程，滑动交互设计 |

---

## 🛠 技术栈 · Tech Stack

- **Framework**: SwiftUI (iOS 26)
- **Architecture**: `@Observable` + Environment 状态管理
- **Persistence**: JSON 本地持久化（文件系统）
- **Design System**: Digital Obsidian — 自建暗色主题设计系统
- **Adaptive UI**: `UIColor dynamicProvider` 实现真正的 Light/Dark 自适应
- **Photos**: `PhotosUI` — 用户头像从相册选取

---

## 🗂 产品设计文档 · PM Artifacts

本项目完整保留了产品设计过程中的所有文档：

- **PRD** — 产品需求文档（用户故事、功能优先级矩阵）
- **原型** — 8 个高保真交互页面（HTML 可运行原型）
- **设计系统** — Digital Obsidian 色彩规范、组件规范
- **AI 功能 Spec** — 账单识别、智能建议等 AI 功能技术规格

---

## 📱 页面结构 · App Structure

```
SubTrack
├── 首页 (Dashboard)        月度支出卡片 + 即将续费 + 订阅列表
├── 订阅管理 (Subscriptions) 全部订阅 + 筛选 + 排序 + 详情页
├── 财务洞察 (Insights)      趋势图 + 分类占比 + 数据汇总
└── 设置 (Settings)         外观/语言/货币 + 个人资料管理
```

---

## 🚀 运行方式 · Getting Started

```bash
# Clone the repo
git clone https://github.com/tyx22000044-maker/SubTrack.git

# Open in Xcode
open SubTrack/SubTrack.xcodeproj
```

**Requirements**: Xcode 26+ · iOS 26 SDK · Apple Developer Account (free tier)

---

## 🗺 产品路线图 · Roadmap

- [x] 核心订阅管理（增删改查 + **编辑**）
- [x] 数据本地持久化
- [x] 多货币支持 + 汇率换算
- [x] 中英双语界面
- [x] Light / Dark / Auto 主题
- [x] 用户 Onboarding 引导流程
- [x] 用户档案（头像 + 昵称）
- [x] 订阅详情页
- [x] 排序与筛选 + **搜索**
- [x] 推送通知（续费到期提醒）
- [x] 数据导出（PDF 报告 + CSV）
- [x] Insights 真实历史数据趋势图
- [ ] Home Screen Widget
- [ ] AI 账单扫描识别
- [ ] iCloud 数据同步
- [ ] App Store 上架

---

## 💡 关于这个项目 · About

这个项目的核心价值不只在于功能本身，而在于**用 AI 工具驱动完整产品生命周期**的方法论实践：

- 用 AI 进行竞品分析和用户故事撰写
- 用 AI 辅助生成高保真 HTML 交互原型
- 用 AI 协作完成零基础的 iOS 原生开发
- 在每一次迭代中模拟真实 PM 的决策过程

> "工具会变，但产品思维和用户洞察是永恒的。"

---

📋 **完整开发日志** → [CHANGELOG.md](./CHANGELOG.md)

*Built with ❤️ and AI · 2025–2026*
