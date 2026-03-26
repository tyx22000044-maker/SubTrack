import SwiftUI

enum AppTab: Int {
    case dashboard, subscriptions, insights, settings
    var icon: String {
        switch self {
        case .dashboard:     return "house.fill"
        case .subscriptions: return "checklist"
        case .insights:      return "chart.bar.fill"
        case .settings:      return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var store    = SubscriptionStore()
    @State private var settings = AppSettings()
    @State private var selectedTab: AppTab = .dashboard
    @State private var showAdd = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            Group {
                switch selectedTab {
                case .dashboard:     DashboardView(onSeeAll: { selectedTab = .subscriptions })
                case .subscriptions: SubscriptionsView()
                case .insights:      InsightsView()
                case .settings:      SettingsView()
                }
            }
            CustomTabBar(selectedTab: $selectedTab, onAdd: { showAdd = true })
        }
        .environment(store)
        .environment(settings)
        .preferredColorScheme(settings.colorScheme)
        .sheet(isPresented: $showAdd) {
            AddSubscriptionView()
                .environment(store)
                .environment(settings)
        }
        .task {
            await NotificationManager.shared.rescheduleAll(for: store.subscriptions)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !settings.hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
                .environment(settings)
                .environment(store)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Environment(AppSettings.self) var settings
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(tab: .dashboard,     label: settings.tabHome,          selectedTab: $selectedTab)
            TabBarItem(tab: .subscriptions, label: settings.tabSubscriptions, selectedTab: $selectedTab)

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 10, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.appOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -6)

            TabBarItem(tab: .insights,  label: settings.tabInsights,  selectedTab: $selectedTab)
            TabBarItem(tab: .settings,  label: settings.tabSettings,  selectedTab: $selectedTab)
        }
        .frame(height: 60)
        .background(
            Rectangle()
                .fill(Color.appSurface)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.appOutlineVariant).frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarItem: View {
    let tab: AppTab
    let label: String
    @Binding var selectedTab: AppTab
    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 20))
                Text(label).font(.system(size: 10))
            }
            .foregroundColor(isSelected ? Color.appPrimary : Color.appOutline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

#Preview { ContentView() }
