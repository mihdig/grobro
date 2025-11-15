import SwiftUI
import GroBroDomain

/// Multi-step wizard for connecting AC Infinity Controller 69 Pro
/// Handles discovery, pairing, authentication, and plant assignment
struct ACInfinityConnectionWizard: View {
    let plantId: UUID?
    let onComplete: (ACInfinityDevice) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(DeviceStore.self) private var deviceStore
    @State private var currentStep: WizardStep = .deviceSelection
    @State private var selectedDevice: DiscoveredDevice?
    @State private var authUsername: String = ""
    @State private var authPassword: String = ""
    @State private var isAuthenticating: Bool = false
    @State private var authError: String?
    @State private var showingManualEntry: Bool = false
    @State private var manualDeviceId: String = ""
    @State private var connectedDevice: ACInfinityDevice?

    enum WizardStep {
        case deviceSelection
        case authentication
        case plantAssignment
        case success
    }

    private var discoveredDevices: [DiscoveredDevice] {
        deviceStore.discoveredDevices
    }

    private var isScanning: Bool {
        deviceStore.isScanning
    }

    init(plantId: UUID? = nil, onComplete: @escaping (ACInfinityDevice) -> Void) {
        self.plantId = plantId
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressBar

                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                        }
                        .padding()
                    }

                    // Bottom actions
                    bottomActions
                }
            }
            .navigationTitle("Connect Controller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
            .onAppear {
                startScanning()
            }
            .onDisappear {
                deviceStore.stopScanning()
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.surfaceLight)
                    .frame(height: 4)

                // Progress
                Rectangle()
                    .fill(Color.greenAccentGradient)
                    .frame(width: geometry.size.width * progressPercentage, height: 4)
                    .shadow(color: Color.electricGreen.opacity(0.4), radius: 4)
            }
        }
        .frame(height: 4)
        .animation(.spring(response: 0.3), value: currentStep)
    }

    private var progressPercentage: Double {
        switch currentStep {
        case .deviceSelection: return 0.25
        case .authentication: return 0.50
        case .plantAssignment: return 0.75
        case .success: return 1.0
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .deviceSelection:
            deviceSelectionStep
        case .authentication:
            authenticationStep
        case .plantAssignment:
            plantAssignmentStep
        case .success:
            successStep
        }
    }

    // MARK: - Device Selection Step

    private var deviceSelectionStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 64))
                    .foregroundColor(.electricGreen)
                    .symbolEffect(.pulse, isActive: isScanning)

                Text("Looking for Controllers")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)

                Text("Make sure your AC Infinity controller is powered on and nearby")
                    .font(.system(size: 15))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Discovered devices
            if discoveredDevices.isEmpty {
                scanningPlaceholder
            } else {
                deviceList
            }

            // Manual entry option
            Button {
                showingManualEntry = true
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Enter Device ID Manually")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.electricGreen)
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            manualDeviceEntry
        }
    }

    private var scanningPlaceholder: some View {
        GlassCard {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .electricGreen))
                    .scaleEffect(1.5)

                Text("Scanning for devices...")
                    .font(.system(size: 15))
                    .foregroundColor(.secondaryText)

                Text("This may take a few moments")
                    .font(.system(size: 13))
                    .foregroundColor(.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private var deviceList: some View {
        VStack(spacing: 12) {
            Text("Found \(discoveredDevices.count) controller\(discoveredDevices.count == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(discoveredDevices) { device in
                deviceCard(device: device)
            }
        }
    }

    private func deviceCard(device: DiscoveredDevice) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedDevice = device
            }
        } label: {
            GlassCard(isHighlighted: selectedDevice?.id == device.id) {
                HStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 32))
                        .foregroundColor(.electricGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)

                        Text(device.model.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)

                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { index in
                                Rectangle()
                                    .fill(index < device.signalStrength.bars ? Color.electricGreen : Color.surfaceLight)
                                    .frame(width: 6, height: CGFloat(4 + index * 2))
                            }

                            Text(device.signalStrength.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.tertiaryText)
                        }
                    }

                    Spacer()

                    if selectedDevice?.id == device.id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.electricGreen)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var manualDeviceEntry: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Enter the device ID found on your AC Infinity controller")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()

                    GlassCard {
                        TextField("Device ID", text: $manualDeviceId)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.primaryText)
                            .padding()
                    }
                    .padding(.horizontal)

                    NeonButton(
                        "Use Device",
                        style: .primary,
                        isDisabled: manualDeviceId.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        let id = manualDeviceId.trimmingCharacters(in: .whitespaces)
                        selectedDevice = DiscoveredDevice(
                            id: id,
                            name: "Controller \(id)",
                            model: .controller69Pro,
                            signalStrength: .good
                        )
                        showingManualEntry = false
                        manualDeviceId = ""
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingManualEntry = false
                    }
                    .foregroundColor(.electricGreen)
                }
            }
        }
    }

    // MARK: - Authentication Step

    private var authenticationStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.electricGreen)

                Text("Device Credentials")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)

                if let device = selectedDevice {
                    Text(device.name)
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                }

                Text("Enter your AC Infinity account credentials to authorize this connection")
                    .font(.system(size: 15))
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Form
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email / Username")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        TextField("Email", text: $authUsername)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .foregroundColor(.primaryText)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .padding(4)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        SecureField("Password", text: $authPassword)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .foregroundColor(.primaryText)
                            .textContentType(.password)
                    }
                    .padding(4)
                }

                if let error = authError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.criticalRed)

                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.criticalRed)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.criticalRed.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.criticalRed.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Help text
            VStack(spacing: 8) {
                Text("Don't have an AC Infinity account?")
                    .font(.system(size: 13))
                    .foregroundColor(.tertiaryText)

                Button("Create Account on AC Infinity") {
                    // Open AC Infinity website
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.electricGreen)
            }
        }
    }

    // MARK: - Plant Assignment Step

    private var plantAssignmentStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.electricGreen)

                Text("Assign to Plant")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)

                Text("Which plant should this controller monitor?")
                    .font(.system(size: 15))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            if plantId != nil {
                // Auto-assigned
                GlassCard(isHighlighted: true) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.electricGreen)

                        Text("Auto-assigned to current plant")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primaryText)

                        Text("You can change this later in settings")
                            .font(.system(size: 13))
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                // Show plant selector
                plantSelector
            }

            // Alert configuration preview
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.cyanBright)

                        Text("Default Alert Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        alertSettingRow(label: "Temperature", range: "70-80°F")
                        alertSettingRow(label: "Humidity", range: "50-70%")
                        alertSettingRow(label: "VPD", range: "0.8-1.2 kPa")
                    }

                    Text("You can customize these in the Environment tab")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
    }

    private var plantSelector: some View {
        VStack(spacing: 12) {
            Text("Select a plant")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // TODO: Load actual plants
            GlassCard {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.electricGreen)

                    Text("Sample Plant")
                        .foregroundColor(.primaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.tertiaryText)
                }
            }

            Button {
                // Assign later
            } label: {
                Text("Skip - I'll assign later")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.electricGreen)
            }
        }
    }

    private func alertSettingRow(label: String, range: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)

            Spacer()

            Text(range)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.primaryText)
        }
    }

    // MARK: - Success Step

    private var successStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.electricGreen.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                Circle()
                    .stroke(Color.electricGreen, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.electricGreen)
            }

            VStack(spacing: 12) {
                Text("Connected Successfully!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primaryText)

                if let device = connectedDevice {
                    Text(device.name)
                        .font(.system(size: 17))
                        .foregroundColor(.secondaryText)
                }

                Text("Your controller is now monitoring environmental conditions")
                    .font(.system(size: 15))
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Features
            VStack(spacing: 16) {
                successFeature(icon: "thermometer.medium", text: "Real-time temp & humidity")
                successFeature(icon: "chart.line.uptrend.xyaxis", text: "Historical data tracking")
                successFeature(icon: "bell.badge", text: "Automatic alerts enabled")
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func successFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.electricGreen)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)

            Spacer()
        }
    }

    // MARK: - Bottom Actions

    @ViewBuilder
    private var bottomActions: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.surfaceLight)

            HStack(spacing: 12) {
                if currentStep != .deviceSelection && currentStep != .success {
                    NeonButton("Back", style: .secondary, fullWidth: false) {
                        goBack()
                    }
                }

                Spacer()

                if currentStep == .success {
                    NeonButton("Done", style: .primary) {
                        finishWizard()
                    }
                } else {
                    NeonButton(
                        nextButtonTitle,
                        style: .primary,
                        isLoading: isAuthenticating || isScanning,
                        isDisabled: !canProceed
                    ) {
                        goNext()
                    }
                }
            }
            .padding()
        }
        .background(Color.deepBackground)
    }

    private var nextButtonTitle: String {
        switch currentStep {
        case .deviceSelection: return "Continue"
        case .authentication: return "Authenticate"
        case .plantAssignment: return "Complete Setup"
        case .success: return "Done"
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .deviceSelection:
            return selectedDevice != nil
        case .authentication:
            return !authUsername.isEmpty && !authPassword.isEmpty
        case .plantAssignment:
            return true
        case .success:
            return true
        }
    }

    // MARK: - Navigation

    private func goNext() {
        switch currentStep {
        case .deviceSelection:
            withAnimation(.spring(response: 0.3)) {
                currentStep = .authentication
            }

        case .authentication:
            authenticate()

        case .plantAssignment:
            completeSetup()

        case .success:
            finishWizard()
        }
    }

    private func goBack() {
        withAnimation(.spring(response: 0.3)) {
            switch currentStep {
            case .authentication:
                currentStep = .deviceSelection
            case .plantAssignment:
                currentStep = .authentication
            default:
                break
            }
        }
    }

    // MARK: - Actions

    private func startScanning() {
        Task {
            await deviceStore.startScanning()
        }
    }

    private func authenticate() {
        guard let selectedDevice else { return }

        isAuthenticating = true
        authError = nil

        Task {
            do {
                let device = try await deviceStore.connect(
                    discoveredDevice: selectedDevice,
                    username: authUsername,
                    password: authPassword,
                    plantId: plantId
                )

                await MainActor.run {
                    connectedDevice = device
                    deviceStore.stopScanning()
                    isAuthenticating = false
                    withAnimation(.spring(response: 0.3)) {
                        currentStep = .plantAssignment
                    }
                }
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                    isAuthenticating = false
                }
            }
        }
    }

    private func completeSetup() {
        withAnimation(.spring(response: 0.4)) {
            currentStep = .success
        }

        // Celebration haptic
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func finishWizard() {
        guard let finalDevice = connectedDevice else { return }

        onComplete(finalDevice)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Connection Wizard") {
    ACInfinityConnectionWizard(plantId: UUID()) { device in
        print("Connected device: \(device.name)")
    }
    .environment(DeviceStore.preview)
}
