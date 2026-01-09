import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.fill")
                }

            BPEntryView()
                .tabItem {
                    Label("Add BP", systemImage: "plus.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("BP History", systemImage: "list.bullet")
                }

            LipidHistoryView()
                .tabItem {
                    Label("Lipids", systemImage: "drop.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }

            TutorialView()
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
