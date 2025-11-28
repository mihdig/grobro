import SwiftUI
import GroBroDomain

/// Form for manually logging environmental data
@available(iOS 18.0, macOS 15.0, *)
public struct ManualEnvironmentForm: View {
    let plantId: UUID
    let eventStore: EventStore
    @Environment(\.dismiss) private var dismiss
    @State private var userSettings = UserSettings.shared

    @State private var temperature: Double = 75
    @State private var humidity: Double = 60
    @State private var notes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    public init(plantId: UUID, eventStore: EventStore) {
        self.plantId = plantId
        self.eventStore = eventStore
    }

    private var calculatedVPD: Double {
        EnvironmentalData.calculateVPD(
            temperatureFahrenheit: temperature,
            humidityPercent: humidity
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Temperature input
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Temperature", systemImage: "thermometer.medium")
                                    .font(.headline)
                                    .foregroundColor(.primaryText)

                                HStack {
                                    Slider(value: $temperature, in: 50...100, step: 1)
                                        .tint(.electricGreen)

                                    Text(userSettings.formatTemperature(temperature))
                                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                                        .foregroundColor(.primaryText)
                                        .frame(minWidth: 80, alignment: .trailing)
                                }
                            }
                        }

                        // Humidity input
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Humidity", systemImage: "drop.fill")
                                    .font(.headline)
                                    .foregroundColor(.primaryText)

                                HStack {
                                    Slider(value: $humidity, in: 0...100, step: 1)
                                        .tint(.cyanBright)

                                    Text(userSettings.formatHumidity(humidity))
                                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                                        .foregroundColor(.primaryText)
                                        .frame(minWidth: 80, alignment: .trailing)
                                }
                            }
                        }

                        // Auto-calculated VPD
                        GlassCard(elevation: .subtle) {
                            HStack {
                                Label("VPD (Auto-calculated)", systemImage: "gauge.medium")
                                    .font(.headline)
                                    .foregroundColor(.primaryText)

                                Spacer()

                                Text(userSettings.formatVPD(calculatedVPD))
                                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                                    .foregroundColor(Color.vpdColor(for: calculatedVPD))
                            }
                        }

                        // Optional notes
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Notes (Optional)", systemImage: "note.text")
                                    .font(.headline)
                                    .foregroundColor(.primaryText)

                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(.primaryText)
                                    .background(Color.surfaceLight.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Environment")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .foregroundColor(.electricGreen)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveEvent() {
        let envData = EnvironmentalData(
            temperatureFahrenheit: temperature,
            humidityPercent: humidity,
            vpdKilopascal: calculatedVPD,
            deviceName: nil,
            visualStyle: .manual
        )

        let event = Event(
            plantId: plantId,
            type: .environment,
            timestamp: Date(),
            noteText: notes.isEmpty ? nil : notes,
            source: .manual,
            environmentalData: envData
        )

        do {
            _ = try eventStore.createEvent(event)
            dismiss()
        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
            showError = true
        }
    }
}
