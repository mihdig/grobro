import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventCreationViewModel

    public init(viewModel: EventCreationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(viewModel.eventType.displayName, systemImage: viewModel.eventType.iconName)
                        .font(.headline)
                }

                // Volume (for watering/feeding/flush)
                if [.watering, .feeding, .flush].contains(viewModel.eventType) {
                    Section("Volume") {
                        HStack {
                            TextField("Amount (Liters)", value: $viewModel.volumeLiters, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }
                }

                // Stress tags (for stress events)
                if viewModel.eventType == .stress {
                    Section("Stress Tags") {
                        ForEach(StressTag.allCases, id: \.self) { tag in
                            Toggle(tag.displayName, isOn: Binding(
                                get: { viewModel.stressTags.contains(tag) },
                                set: { isOn in
                                    if isOn {
                                        viewModel.stressTags.insert(tag)
                                    } else {
                                        viewModel.stressTags.remove(tag)
                                    }
                                }
                            ))
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $viewModel.noteText)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add \(viewModel.eventType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEvent()
                        dismiss()
                    }
                }
            }
        }
    }
}
