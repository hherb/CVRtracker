import SwiftUI

struct TutorialView: View {
    var body: some View {
        NavigationStack {
            List {
                // Medical Disclaimer Section
                Section {
                    MedicalDisclaimerCard()
                }

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

                // Research references (if any)
                if !topic.references.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Research References", systemImage: "book.closed")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Tap to open in your browser")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(topic.references) { ref in
                            Link(destination: ref.url) {
                                HStack {
                                    Text(ref.title)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
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

/// A prominent medical disclaimer card with link to sources
struct MedicalDisclaimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Medical Information")
                    .font(.headline)
            }

            Text("This app provides health information based on published clinical guidelines and peer-reviewed research. Each topic includes citations to source materials.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            Text("This information is for educational purposes only and is not intended to replace professional medical advice, diagnosis, or treatment. Always consult your healthcare provider.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 8)
    }
}

/// A compact medical disclaimer for inline use in other views
struct CompactMedicalDisclaimer: View {
    @State private var showingLearnMore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "cross.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("For educational purposes only. Not medical advice.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Sources") {
                    showingLearnMore = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showingLearnMore) {
            NavigationStack {
                TutorialView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingLearnMore = false
                            }
                        }
                    }
            }
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

#Preview("Topic with References") {
    NavigationStack {
        TopicDetailView(topic: HelpContent.understandingPulsePressure)
    }
}
