import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct PlantCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OnboardingManager.self) private var onboardingManager
    @StateObject private var viewModel: PlantCreationViewModel

    public init(viewModel: PlantCreationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Step 1 · Plant Details") {
                    Text("Give your plant a clear name and optional strain so you can quickly recognize it in your garden.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Plant Name", text: $viewModel.name)
                    TextField("Strain Name (Optional)", text: $viewModel.strainName)

                    if !viewModel.isValid {
                        Text("A plant name is required before you can save.")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }

                Section("Step 2 · Growing Info") {
                    Text("Select the stage and basic container setup so GroBro can tune watering and analytics later.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Stage", selection: $viewModel.stage) {
                        ForEach(PlantStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }

                    HStack {
                        Text("Pot Size (Liters)")
                        Spacer()
                        TextField("0", value: $viewModel.potSizeLiters, format: .number)
                            .decimalKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Picker("Substrate Type", selection: $viewModel.substrateType) {
                        Text("None").tag(nil as SubstrateType?)
                        ForEach(SubstrateType.allCases, id: \.self) { substrate in
                            Text(substrate.displayName).tag(substrate as SubstrateType?)
                        }
                    }
                }

                Section("Step 3 · Notes (Optional)") {
                    Text("Capture any special details, goals, or issues you want to remember for this plant.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                }

                Section {
                    Text("You can always edit these details later from the plant page, so it’s okay to start simple.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Plant")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let didSave = viewModel.savePlant()
                        if didSave {
                            onboardingManager.completeFirstPlant()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}
