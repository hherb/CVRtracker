import SwiftUI

struct TutorialView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(HelpContent.tutorialSections) { section in
                    Section {
                        ForEach(section.topics) { topic in
                            NavigationLink {
                                TopicDetailView(topic: topic)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(topic.title)
                                        .font(.headline)
                                    Text(topic.shortDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Label(section.title, systemImage: section.icon)
                    }
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TopicDetailView: View {
    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(topic.shortDescription)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                Divider()

                // Main content
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(topic.detailedDescription)
                        .font(.body)
                        .lineSpacing(4)
                }

                Divider()

                // Clinical relevance
                VStack(alignment: .leading, spacing: 12) {
                    Label("Clinical Significance", systemImage: "stethoscope")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(topic.clinicalRelevance)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A reusable info button that shows a help topic in a sheet
struct InfoButton: View {
    let topic: HelpTopic
    @State private var showingHelp = false

    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .font(.body)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                TopicDetailView(topic: topic)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingHelp = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

/// A label with an attached info button
struct LabelWithInfo: View {
    let text: String
    let topic: HelpTopic

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
            InfoButton(topic: topic)
        }
    }
}

/// A section header with an info button
struct SectionHeaderWithInfo: View {
    let text: String
    let topic: HelpTopic

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
            InfoButton(topic: topic)
        }
    }
}

#Preview {
    TutorialView()
}

#Preview("Topic Detail") {
    NavigationStack {
        TopicDetailView(topic: HelpContent.fractionalPulsePressure)
    }
}
