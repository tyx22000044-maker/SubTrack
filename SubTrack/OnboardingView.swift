import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AppSettings.self) var settings
    @State private var page = 0
    @State private var userName = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var nameFieldFocused = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Background glow
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.12))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -60, y: -200)
                Circle()
                    .fill(Color.appSecondary.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100, y: 200)
            }
            .ignoresSafeArea()

            // Pages
            TabView(selection: $page) {
                WelcomePage().tag(0)
                ProfilePage(
                    userName: $userName,
                    selectedItem: $selectedItem,
                    avatarData: $avatarData,
                    onNext: { advance() }
                ).tag(1)
                ReadyPage(
                    userName: userName,
                    avatarData: avatarData,
                    onFinish: { finish() }
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: page)

            // Step dots
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.appPrimary : Color.appOutlineVariant)
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: page)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(settings.colorScheme)
    }

    private func advance() {
        withAnimation { page += 1 }
    }

    private func finish() {
        settings.userName = userName.trimmingCharacters(in: .whitespaces)
        settings.userAvatarData = avatarData
        withAnimation { settings.hasCompletedOnboarding = true }
    }
}

// MARK: - Page 1: Welcome
private struct WelcomePage: View {
    @Environment(AppSettings.self) var settings
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.9), Color(hex: "6650a4")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 20, y: 8)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 36)

            Text("SubTrack")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(Color.appOnSurface)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Text(settings.onboardingSubtitle)
                .font(.system(size: 18))
                .foregroundColor(Color.appOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()

            SwipeButton(label: settings.onboardingSwipeLabel)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Page 2: Profile
private struct ProfilePage: View {
    @Environment(AppSettings.self) var settings
    @Binding var userName: String
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var avatarData: Data?
    let onNext: () -> Void
    @State private var appeared = false
    @FocusState private var focused: Bool

    var canContinue: Bool { !userName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Avatar picker
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color.appSurfaceContainer)
                        .frame(width: 110, height: 110)
                    if let data = avatarData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 38))
                                .foregroundColor(Color.appOutline)
                        }
                    }
                    // Camera badge
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.appOnPrimary)
                        )
                        .offset(x: 36, y: 36)
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 6)
                }
            }
            .onChange(of: selectedItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        avatarData = data
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)

            Text(settings.onboardingNameTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.appOnSurface)
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)

            Text(settings.onboardingNameSubtitle)
                .font(.system(size: 15))
                .foregroundColor(Color.appOnSurfaceVariant)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)

            // Name input
            HStack {
                Image(systemName: "person")
                    .foregroundColor(Color.appOutline)
                    .font(.system(size: 16))
                TextField(settings.onboardingNameHint, text: $userName)
                    .font(.system(size: 17))
                    .foregroundColor(Color.appOnSurface)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { if canContinue { onNext() } }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSurfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                focused ? Color.appPrimary : Color.appOutlineVariant,
                                lineWidth: focused ? 1.5 : 0.5
                            )
                    )
            )
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()

            // Next button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(settings.onboardingNextLabel)
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(canContinue ? Color.appOnPrimary : Color.appOutline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canContinue ? Color.appPrimary : Color.appSurfaceContainer)
                )
            }
            .disabled(!canContinue)
            .padding(.horizontal, 32)
            .padding(.bottom, 100)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }
}

// MARK: - Page 3: Ready
private struct ReadyPage: View {
    @Environment(AppSettings.self) var settings
    let userName: String
    let avatarData: Data?
    let onFinish: () -> Void
    @State private var appeared = false
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: CGFloat = 0

    var displayName: String {
        let name = userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? settings.s("你", "there") : name
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.appPrimary, Color(hex: "6650a4")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 20, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(checkScale)
            .opacity(checkOpacity)
            .padding(.bottom, 36)

            Text(settings.onboardingGreeting + displayName + "！")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color.appOnSurface)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Text(settings.onboardingReady)
                .font(.system(size: 18))
                .foregroundColor(Color.appPrimary)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            VStack(spacing: 10) {
                FeatureRow(icon: "plus.circle.fill", text: settings.onboardingFeature1)
                FeatureRow(icon: "chart.bar.fill",   text: settings.onboardingFeature2)
                FeatureRow(icon: "bell.fill",         text: settings.onboardingFeature3)
            }
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)

            Spacer()
            Spacer()

            Button(action: onFinish) {
                Text(settings.onboardingEnterLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.appOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appPrimary)
                            .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, y: 6)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 100)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                checkScale = 1
                checkOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                appeared = true
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.appPrimary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color.appOnSurfaceVariant)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Swipe Button (Page 1 animated CTA)
private struct SwipeButton: View {
    let label: String
    @State private var offset: CGFloat = 0
    @State private var isDone = false
    private let height: CGFloat = 60
    private let thumbSize: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - thumbSize - 8
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.appSurfaceContainer)
                    .overlay(
                        Text(label)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.appOnSurfaceVariant.opacity(isDone ? 0 : 1))
                    )

                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.appPrimary.opacity(0.3))
                    .frame(width: thumbSize + offset + 4)
                    .clipped()

                // Thumb
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: isDone ? "checkmark" : "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.appOnPrimary)
                    )
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, y: 3)
                    .offset(x: 4 + offset)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                offset = min(max(0, v.translation.width), maxOffset)
                            }
                            .onEnded { v in
                                if offset > maxOffset * 0.75 {
                                    withAnimation(.spring()) { offset = maxOffset; isDone = true }
                                } else {
                                    withAnimation(.spring()) { offset = 0 }
                                }
                            }
                    )
            }
        }
        .frame(height: height)
    }
}

// MARK: - Reusable Avatar View
struct UserAvatarView: View {
    let avatarData: Data?
    let name: String
    let size: CGFloat

    var initials: String {
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        Group {
            if let data = avatarData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if !name.isEmpty {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.appPrimary, Color(hex: "6650a4")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.35, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .fill(Color.appSurfaceContainer)
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(Color.appOutline)
                    )
            }
        }
    }
}
