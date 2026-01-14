import SwiftUI
import UIKit

/// Multi-page onboarding view shown on first launch
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .red,
            title: "Track Your Heart Health",
            description: "Monitor your blood pressure readings and see how your cardiovascular health changes over time.",
            detail: "Enter your systolic and diastolic values to automatically calculate pulse pressure and arterial stiffness indicators.",
            reference: "2017 ACC/AHA Blood Pressure Guideline",
            referenceURL: URL(string: "https://doi.org/10.1161/HYP.0000000000000065")
        ),
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .blue,
            title: "Understand Arterial Stiffness",
            description: "Fractional Pulse Pressure (fPP) is a non-invasive measure that indicates how flexible your arteries are.",
            detail: "Stiffer arteries require your heart to work harder and may indicate increased cardiovascular risk. Track your fPP over time to see trends.",
            reference: "European Heart Journal: Expert Consensus on Arterial Stiffness",
            referenceURL: URL(string: "https://doi.org/10.1093/eurheartj/ehl254")
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .green,
            title: "Visualize Your Trends",
            description: "See how your measurements change over time with interactive charts and trend analysis.",
            detail: "Understanding whether your pulse pressure is increasing or decreasing helps you and your doctor make informed decisions.",
            reference: "Hypertension: Pulse Pressure and CV Mortality",
            referenceURL: URL(string: "https://doi.org/10.1161/01.HYP.32.3.560")
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: .orange,
            title: "Know Your Risk",
            description: "Calculate your 10-year and 30-year cardiovascular risk using the validated Framingham Risk Score.",
            detail: "Based on decades of research from the Framingham Heart Study, this tool estimates your probability of a cardiovascular event.",
            reference: "D'Agostino et al. (2008): General CV Risk Profile",
            referenceURL: URL(string: "https://doi.org/10.1161/CIRCULATIONAHA.107.699579")
        ),
        OnboardingPage(
            icon: "cross.case.fill",
            iconColor: .purple,
            title: "Important Disclaimer",
            description: "This app is for educational purposes only and is not a substitute for professional medical advice.",
            detail: "Always consult your healthcare provider before making any changes to your health regimen. The information provided is based on published clinical guidelines."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom section with page indicator and button
            VStack(spacing: 20) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Navigation buttons
                HStack {
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
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    } else {
                        Button("Get Started") {
                            hasCompletedOnboarding = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground))
    }
}

/// Data model for an onboarding page
private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let detail: String
    let reference: String?
    let referenceURL: URL?

    init(icon: String, iconColor: Color, title: String, description: String, detail: String,
         reference: String? = nil, referenceURL: URL? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.detail = detail
        self.reference = reference
        self.referenceURL = referenceURL
    }
}

/// View for a single onboarding page
private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.iconColor)
                .padding()
                .background(
                    Circle()
                        .fill(page.iconColor.opacity(0.1))
                        .frame(width: 150, height: 150)
                )

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Description
            VStack(spacing: 16) {
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(page.detail)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 30)

            // Reference link (if available)
            if let reference = page.reference, let url = page.referenceURL {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(.caption2)
                        Text(reference)
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
