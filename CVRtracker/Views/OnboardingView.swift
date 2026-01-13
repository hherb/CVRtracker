import SwiftUI

/// Onboarding walkthrough shown on first app launch
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.text.square.fill",
            iconColor: .red,
            title: "Welcome to CVR Tracker",
            description: "Track your cardiovascular health with clinically-validated metrics beyond just blood pressure numbers.",
            detail: "This app helps you understand your vascular health by calculating Fractional Pulse Pressure (fPP), an indicator of arterial stiffness."
        ),
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .orange,
            title: "Understand Arterial Stiffness",
            description: "Your arteries stiffen with age and cardiovascular risk factors. fPP helps track this important health indicator.",
            detail: "Values below 0.40 suggest healthy, elastic arteries. Higher values may indicate increased vascular stiffness that warrants attention."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .blue,
            title: "Track Trends Over Time",
            description: "Regular readings help identify patterns and changes in your vascular health.",
            detail: "The app analyzes your readings to show whether your pulse pressure and mean arterial pressure are stable, improving, or need attention."
        ),
        OnboardingPage(
            icon: "person.fill.questionmark",
            iconColor: .green,
            title: "Get Started",
            description: "Complete your profile and add your first blood pressure reading to begin.",
            detail: "For the most accurate risk assessment, add your age, lipid panel results, and any relevant health conditions in the Profile tab."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom controls
            VStack(spacing: 20) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)

                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
            .padding(.top, 20)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

/// Data model for an onboarding page
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let detail: String
}

/// View for a single onboarding page
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.iconColor)
                .padding(.bottom, 8)

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Detail
            Text(page.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
