import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hammer.circle.fill",
            iconColor: Color(hex: "#F5A623"),
            title: "Plan Construction Phases",
            subtitle: "Break your project into organized phases — Foundation, Walls, Roof, Electrical, and more.",
            feature1: "Customizable phase templates",
            feature2: "Phase progress tracking",
            bg: LinearGradient(colors: [Color(hex:"#1A2B4A"), Color(hex:"#2D4270")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            iconColor: Color(hex: "#34C759"),
            title: "Track Building Progress",
            subtitle: "Monitor task completion, photo documentation, and real-time progress across your entire project.",
            feature1: "Photo progress by phase",
            feature2: "Task completion analytics",
            bg: LinearGradient(colors: [Color(hex:"#0F3D2E"), Color(hex:"#1E6645")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            iconColor: Color(hex: "#FF6B35"),
            title: "Control Deadlines & Materials",
            subtitle: "Stay on schedule with deadline reminders, material planning, and full budget management.",
            feature1: "Smart deadline reminders",
            feature2: "Material & budget control",
            bg: LinearGradient(colors: [Color(hex:"#3D1A0F"), Color(hex:"#7A3520")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
    ]

    var body: some View {
        ZStack {
            pages[currentPage].bg.ignoresSafeArea().animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.btSubhead()).foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24).padding(.top, 60)
                }

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom controls
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == currentPage ? Color.white : Color.white.opacity(0.35))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // CTA button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else { finish() }
                    }) {
                        HStack(spacing: 10) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .font(.btHeadline())
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(pages[currentPage].iconColor)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
                }
            }
        }
    }

    private func finish() {
        appState.hasCompletedOnboarding = true
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let feature1: String
    let feature2: String
    let bg: LinearGradient
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon scene
            ZStack {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 180, height: 180)
                Circle().fill(Color.white.opacity(0.06)).frame(width: 140, height: 140)
                ZStack {
                    Circle().fill(page.iconColor).frame(width: 100, height: 100)
                        .shadow(color: page.iconColor.opacity(0.5), radius: 20, x: 0, y: 10)
                    Image(systemName: page.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)
            }

            // Text
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.btTitle())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                Text(page.subtitle)
                    .font(.btBody())
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 32)

            // Feature rows
            VStack(spacing: 12) {
                FeatureRow(text: page.feature1, color: page.iconColor, delay: 0.4, appeared: appeared)
                FeatureRow(text: page.feature2, color: page.iconColor, delay: 0.5, appeared: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }
}

struct FeatureRow: View {
    let text: String
    let color: Color
    let delay: Double
    let appeared: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }
            Text(text).font(.btSubhead()).foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay), value: appeared)
    }
}
