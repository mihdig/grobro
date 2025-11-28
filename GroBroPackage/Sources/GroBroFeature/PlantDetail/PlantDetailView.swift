import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    @State private var selectedTab: Int
    @State private var showingDiagnostics = false

    public init(viewModel: PlantDetailViewModel, initialTab: Int = 0) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = State(initialValue: initialTab)
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            overviewTab
                .tabItem {
                    Label("Overview", systemImage: "info.circle")
                }
                .tag(0)

            wateringTab
                .tabItem {
                    Label("Watering", systemImage: "drop.fill")
                }
                .tag(1)

            diagnosticsTab
                .tabItem {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
                .tag(2)

            EnvironmentTabView(plantId: viewModel.plant.id)
                .tabItem {
                    Label("Environment", systemImage: "thermometer.medium")
                }
                .tag(3)

            LightMeterView(plant: viewModel.plant)
                .tabItem {
                    Label("Light", systemImage: "sun.max")
                }
                .tag(4)

            DebugConsoleView(viewModel: viewModel.makeDebugConsoleViewModel())
                .tabItem {
                    Label("Debug", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(5)

            DiaryView(viewModel: viewModel.makeDiaryViewModel())
                .tabItem {
                    Label("Diary", systemImage: "calendar")
                }
                .tag(6)
        }
        .inlineNavigationTitle()
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(viewModel: viewModel.makeDiagnosticsViewModel())
        }
    }

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo/Placeholder
                plantPhotoView

                // Plant Info Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.plant.name)
                                .font(.title)
                                .fontWeight(.bold)

                            if let strainName = viewModel.plant.strainName {
                                Text(strainName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Day \(viewModel.plant.ageInDays)")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Age")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Growing Details
                    VStack(spacing: 12) {
                        DetailRow(
                            label: "Stage",
                            value: viewModel.plant.stage.displayName
                        )

                        if let potSize = viewModel.plant.potSizeLiters {
                            DetailRow(
                                label: "Pot Size",
                                value: "\(String(format: "%.1f", potSize))L"
                            )
                        }

                        if let substrate = viewModel.plant.substrateType {
                            DetailRow(
                                label: "Substrate",
                                value: substrate.displayName
                            )
                        }

                        if let lightHours = viewModel.plant.lightHoursPerDay {
                            DetailRow(
                                label: "Light Hours",
                                value: "\(String(format: "%.1f", lightHours))h/day"
                            )
                        }
                    }

                    if let notes = viewModel.plant.notes, !notes.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private var plantPhotoView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .green.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 250)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green.opacity(0.7))
            }
            .padding(.horizontal)
    }

    private var diagnosticsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Check Plant Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plant Health Check")
                        .font(.headline)

                    Text("Take a photo of your plant to check for potential issues like hydration problems, light stress, leaf conditions, or pests.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button {
                        showingDiagnostics = true
                    } label: {
                        Label("Check Plant", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)

                // Recent Diagnostics History placeholder
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Checks")
                        .font(.headline)

                    Text("No diagnostics history yet. Run your first health check above.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private var wateringTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Watering Status Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Watering Schedule")
                        .font(.headline)

                    if let status = viewModel.wateringStatus {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(status.isOverdue ? .red : .blue)
                                    .font(.title)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(status.statusMessage)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(status.isOverdue ? .red : .blue)

                                    Text("Next watering")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Divider()

                            Text("Next watering date:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(status.nextWateringDate, style: .date)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    } else {
                        Text("No watering events logged yet. Log your first watering in the Diary tab.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)

                // Watering Feedback Card
                if viewModel.wateringStatus != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last Watering Feedback")
                            .font(.headline)

                        Text("How was the timing of your last watering?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            FeedbackButton(
                                title: "Too Early",
                                subtitle: "Soil was still wet",
                                icon: "arrow.up.circle.fill",
                                color: .orange
                            ) {
                                viewModel.applyWateringFeedback(.tooEarly)
                            }

                            FeedbackButton(
                                title: "Just Right",
                                subtitle: "Perfect timing",
                                icon: "checkmark.circle.fill",
                                color: .green
                            ) {
                                viewModel.applyWateringFeedback(.justRight)
                            }

                            FeedbackButton(
                                title: "Too Late",
                                subtitle: "Soil was very dry",
                                icon: "arrow.down.circle.fill",
                                color: .red
                            ) {
                                viewModel.applyWateringFeedback(.tooLate)
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

@available(iOS 17.0, *)
struct FeedbackButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
