import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case addBP
    case bpHistory
    case lipids
    case profile
    case learn
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            mainTabView
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "heart.fill")
                }

            BPEntryView()
                .tag(AppTab.addBP)
                .tabItem {
                    Label("Add BP", systemImage: "plus.circle.fill")
                }

            HistoryView()
                .tag(AppTab.bpHistory)
                .tabItem {
                    Label("BP History", systemImage: "list.bullet")
                }

            LipidHistoryView()
                .tag(AppTab.lipids)
                .tabItem {
                    Label("Lipids", systemImage: "drop.fill")
                }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }

            TutorialView()
                .tag(AppTab.learn)
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
        }
        .tint(.red)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BPReading.self, UserProfile.self, LipidReading.self], inMemory: true)
}
