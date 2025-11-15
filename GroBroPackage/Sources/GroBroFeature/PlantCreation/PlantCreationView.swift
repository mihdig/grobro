import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct PlantCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlantCreationViewModel

    public init(viewModel: PlantCreationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Plant Details") {
                    TextField("Plant Name", text: $viewModel.name)
                    TextField("Strain Name (Optional)", text: $viewModel.strainName)
                }

                Section("Growing Info") {
                    Picker("Stage", selection: $viewModel.stage) {
                        ForEach(PlantStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }

                    HStack {
                        Text("Pot Size (Liters)")
                        Spacer()
                        TextField("0", value: $viewModel.potSizeLiters, format: .number)
                            .keyboardType(.decimalPad)
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

                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.savePlant()
                        dismiss()
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
