import SwiftUI
import GroBroDomain

struct DeviceIntegrationsView: View {
    @Environment(DeviceStore.self) private var deviceStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingConnectionWizard = false

    var body: some View {
        ZStack {
            Color.deepBackground.ignoresSafeArea()

            List {
                Section {
                    Text("AC Infinity controllers provide real-time environmental monitoring for your plants")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .listRowBackground(Color.clear)
                }

                if !deviceStore.devices.isEmpty {
                    Section("Connected Devices") {
                        ForEach(deviceStore.devices, id: \.id) { device in
                            DeviceRow(device: device)
                        }
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))
                }

                Section {
                    Button {
                        showingConnectionWizard = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.electricGreen)

                            Text("Add Device")
                                .foregroundColor(.primaryText)
                        }
                    }
                    .listRowBackground(Color.surfaceDark.opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Device Integrations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConnectionWizard) {
            ACInfinityConnectionWizard { device in
                showingConnectionWizard = false
            }
        }
    }
}

struct DeviceRow: View {
    let device: ACInfinityDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: device.signalStrength.iconName)
                    .foregroundColor(device.isConnected ? .electricGreen : .tertiaryText)

                Text(device.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                Circle()
                    .fill(device.isConnected ? Color.electricGreen : Color.tertiaryText)
                    .frame(width: 8, height: 8)
            }

            HStack {
                Text("Firmware: \(device.firmwareVersion)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)

                Spacer()

                if device.isConnected {
                    Text("Last sync: \(device.lastSyncDescription)")
                        .font(.system(size: 13))
                        .foregroundColor(.tertiaryText)
                } else {
                    Text("Offline")
                        .font(.system(size: 13))
                        .foregroundColor(.criticalRed)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        let deviceStore = DeviceStore.preview
        let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

        DeviceIntegrationsView()
            .environment(deviceStore)
            .environment(envStore)
    }
}
