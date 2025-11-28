import SwiftUI
import PhotosUI
import GroBroDomain

@available(iOS 17.0, *)
public struct DiagnosticsView: View {
    @StateObject private var viewModel: DiagnosticsViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: DiagnosticsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .selectingPhoto:
                    photoSelectionView
                case .analyzing:
                    analyzingView
                case .result(let result):
                    DiagnosticsResultView(result: result, plant: viewModel.plant)
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Plant Check")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var photoSelectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Take a Photo")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take a clear photo of your plant's leaves to check for potential issues")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                PhotosPicker(
                    selection: $viewModel.selectedPhoto,
                    matching: .images
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .padding()
        .sheet(isPresented: $viewModel.showCamera) {
            // Camera capture sheet placeholder
            // In production, integrate with iOS camera
            Text("Camera functionality would go here")
        }
    }

    private var analyzingView: some View {
        VStack {
            Spacer()

            GlassLoadingIndicator(
                title: "Analyzing your plant...",
                subtitle: "This may take a few moments",
                style: .fullWidth
            )

            Spacer()
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

@available(iOS 17.0, *)
public struct DiagnosticsResultView: View {
    let result: DiagnosticsResult
    let plant: Plant

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analysis Complete")
                                .font(.headline)

                            if let confidence = result.overallConfidence {
                                Text("Confidence: \(Int(confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    Text(result.healthSummary)
                        .font(.body)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)

                // Status Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Diagnostic Details")
                        .font(.headline)

                    StatusDetailRow(
                        label: "Hydration",
                        value: result.hydrationStatus.displayName,
                        icon: "drop.fill"
                    )

                    StatusDetailRow(
                        label: "Light Stress",
                        value: result.lightStressStatus.displayName,
                        icon: "sun.max.fill"
                    )

                    StatusDetailRow(
                        label: "Leaf Condition",
                        value: result.leafConditionStatus.displayName,
                        icon: "leaf.fill"
                    )

                    StatusDetailRow(
                        label: "Pests",
                        value: result.pestsStatus.displayName,
                        icon: "ant.fill"
                    )
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)

                // Checklist
                VStack(alignment: .leading, spacing: 16) {
                    Text("What to Check")
                        .font(.headline)

                    ForEach(Array(result.checklistItems.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.title3)

                            Text(item)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
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
}

@available(iOS 17.0, *)
struct StatusDetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}
