import SwiftUI
import Charts
import GroBroDomain

/// Environment monitoring tab for AC Infinity integration
/// Displays real-time environmental data and controller settings
struct EnvironmentTabView: View {
    let plantId: UUID

    @Environment(DeviceStore.self) private var deviceStore
    @Environment(EnvironmentalDataStore.self) private var environmentalDataStore

    @State private var selectedTimeRange: TimeRange = .twentyFourHours
    @State private var showingConnectionWizard = false
    @State private var showingAlertConfiguration = false
    @State private var isLoadingHistory = false
    @State private var historyError: String?

    enum TimeRange: String, CaseIterable {
        case twentyFourHours = "24h"
        case sevenDays = "7d"
        case thirtyDays = "30d"

        var displayName: String { rawValue }

        var daysBack: Int {
            switch self {
            case .twentyFourHours: return 1
            case .sevenDays: return 7
            case .thirtyDays: return 30
            }
        }
    }

    init(plantId: UUID) {
        self.plantId = plantId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                contentForCurrentState
            }
            .padding()
        }
        .background(Color.deepSpaceGradient.ignoresSafeArea())
        .sheet(isPresented: $showingConnectionWizard) {
            ACInfinityConnectionWizard(plantId: plantId) { connectedDevice in
                startMonitoringIfNeeded()
                Task { await loadHistoricalData(forceReload: true) }
                showingConnectionWizard = false
            }
        }
        .sheet(isPresented: $showingAlertConfiguration) {
            AlertConfigurationView(plantId: plantId)
        }
        .task(id: selectedTimeRange) {
            await loadHistoricalData()
        }
        .task(id: assignedDevice?.id) {
            await handleDeviceChange()
        }
        .onDisappear {
            environmentalDataStore.stopMonitoring(plantId: plantId)
        }
    }

    // MARK: - Connected View

    @ViewBuilder
    private var contentForCurrentState: some View {
        if let device = assignedDevice {
            connectedView(device: device)
        } else {
            disconnectedView()
        }
    }

    private var assignedDevice: ACInfinityDevice? {
        deviceStore.devices.first { $0.assignedPlantId == plantId }
    }

    private var environmentalData: RealtimeEnvironmentalData {
        environmentalDataStore.dataByPlant[plantId] ?? placeholderEnvironmentalData
    }

    private var placeholderEnvironmentalData: RealtimeEnvironmentalData {
        let fallback = RealtimeEnvironmentalData(
            temperature: 75,
            humidity: 55,
            vpd: RealtimeEnvironmentalData.calculateVPD(temperature: 75, humidity: 55),
            timestamp: .now,
            deviceId: assignedDevice?.id,
            isConnected: assignedDevice?.isConnected ?? false
        )
        return fallback
    }

    private var historicalData: [EnvironmentalDataPoint] {
        environmentalDataStore.historicalDataByPlant[plantId] ?? []
    }

    @ViewBuilder
    private func connectedView(device: ACInfinityDevice) -> some View {
        // Connection Status
        connectionStatusCard(device: device)

        // Large Metric Displays
        metricsGrid

        // VPD Display
        vpdCard

        // 24-Hour Trend Chart
        trendsChart

        // Controller Settings
        controllerSettingsCard(device: device)

        // Action Buttons
        actionButtons
    }

    private func connectionStatusCard(device: ACInfinityDevice) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: device.signalStrength.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(device.isConnected ? .electricGreen : .tertiaryText)
                    .symbolEffect(.pulse, isActive: device.isConnected)

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    HStack(spacing: 8) {
                        let statusColor: Color = device.isConnected ? .electricGreen : .criticalRed

                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)

                        Text(device.isConnected ? "Connected" : "Offline")
                            .font(.system(size: 13))
                            .foregroundColor(statusColor)

                        Text("•")
                            .foregroundColor(.tertiaryText)

                        if device.isConnected {
                            Text("Last sync: \(device.lastSyncDescription)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondaryText)
                        } else {
                            Text("Reconnect to resume monitoring")
                                .font(.system(size: 13))
                                .foregroundColor(.secondaryText)
                        }
                    }

                    Text("Signal: \(device.signalStrength.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }

                Spacer()
            }
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 16) {
            largeMetricCard(
                icon: "thermometer.medium",
                value: String(format: "%.1f°F", environmentalData.temperature),
                label: "Temperature",
                color: .temperatureColor(for: environmentalData.temperature),
                progress: temperatureProgress
            )

            largeMetricCard(
                icon: "drop.fill",
                value: String(format: "%.0f%%", environmentalData.humidity),
                label: "Humidity",
                color: .cyanBright,
                progress: environmentalData.humidity / 100
            )
        }
    }

    private var temperatureProgress: Double {
        // Map 60-90°F to 0-1 progress
        let minTemp: Double = 60
        let maxTemp: Double = 90
        return Swift.min(Swift.max((environmentalData.temperature - minTemp) / (maxTemp - minTemp), 0), 1)
    }

    private func largeMetricCard(
        icon: String,
        value: String,
        label: String,
        color: Color,
        progress: Double
    ) -> some View {
        GlassCard(elevation: .elevated) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)

                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceLight)
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .shadow(color: color.opacity(0.6), radius: 4)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private var vpdCard: some View {
        GlassCard(isHighlighted: environmentalData.status == .optimal) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gauge.medium")
                        .foregroundColor(.vpdColor(for: environmentalData.vpd))

                    Text("Vapor Pressure Deficit (VPD)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Spacer()

                    Button {
                        // Show VPD explanation
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondaryText)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.2f", environmentalData.vpd))
                        .font(.system(size: 48, weight: .semibold, design: .monospaced))
                        .foregroundColor(.vpdColor(for: environmentalData.vpd))
                        .contentTransition(.numericText())

                    Text("kPa")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.tertiaryText)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        statusBadge
                    }
                }

                Text("Optimal range: 0.8 - 1.2 kPa")
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(environmentalData.status.color)
                .frame(width: 8, height: 8)

            Text(environmentalData.status.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(environmentalData.status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(environmentalData.status.color.opacity(0.15))
        )
    }

    private var trendsChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Environmental Trends")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Spacer()

                    // Time range picker
                    Picker("Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                if let historyError {
                    historyErrorView(historyError)
                } else if isLoadingHistory && historicalData.isEmpty {
                    loadingChartPlaceholder
                } else if historicalData.isEmpty {
                    emptyChartPlaceholder
                } else {
                    temperatureChart
                    humidityChart
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)

            Text("No historical data yet")
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)

            Text("Data will appear here once monitoring begins")
                .font(.system(size: 13))
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var loadingChartPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .electricGreen))

            Text("Loading historical data…")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func historyErrorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.warningOrange)
                .font(.system(size: 28))

            Text("Unable to load history")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primaryText)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            NeonButton("Retry", style: .secondary) {
                Task { await loadHistoricalData(forceReload: true) }
            }
            .frame(maxWidth: 180)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var temperatureChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 14))
                    .foregroundColor(.electricGreen)

                Text("Temperature")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }

            Chart(historicalData) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Temp", point.temperature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.electricGreen, Color.neonGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Temp", point.temperature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.electricGreen.opacity(0.3), Color.electricGreen.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel()
                        .foregroundStyle(Color.tertiaryText)
                        .font(.system(size: 11))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel()
                        .foregroundStyle(Color.tertiaryText)
                        .font(.system(size: 11))
                }
            }
            .frame(height: 150)
        }
    }

    private var humidityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.cyanBright)

                Text("Humidity")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }

            Chart(historicalData) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Humidity", point.humidity)
                )
                .foregroundStyle(Color.cyanBright)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Humidity", point.humidity)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cyanBright.opacity(0.3), Color.cyanBright.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel()
                        .foregroundStyle(Color.tertiaryText)
                        .font(.system(size: 11))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel()
                        .foregroundStyle(Color.tertiaryText)
                        .font(.system(size: 11))
                }
            }
            .frame(height: 150)
        }
    }

    private func controllerSettingsCard(device: ACInfinityDevice) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.electricGreen)

                    Text("Controller Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Spacer()
                }

                // Fan Speed
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fan Speed")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)

                        Spacer()

                        Text("\(device.fanSpeed)")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(.electricGreen)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.surfaceLight)
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.greenAccentGradient)
                                .frame(width: geometry.size.width * (Double(device.fanSpeed) / 10), height: 8)
                                .shadow(color: Color.electricGreen.opacity(0.6), radius: 4)
                        }
                    }
                    .frame(height: 8)
                }

                Divider()
                    .background(Color.surfaceLight)

                // Target Temperature
                HStack {
                    Text("Target Temp")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text("\(Int(device.targetTemperature.min))-\(Int(device.targetTemperature.max))°F")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.primaryText)
                }

                // Target Humidity
                HStack {
                    Text("Target RH")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text("\(Int(device.targetHumidity.min))-\(Int(device.targetHumidity.max))%")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.primaryText)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            NeonButton("Configure Alerts", style: .secondary) {
                showingAlertConfiguration = true
            }

            NeonButton(
                "Refresh History",
                style: .secondary,
                isLoading: isLoadingHistory
            ) {
                Task { await loadHistoricalData(forceReload: true) }
            }
        }
    }

    // MARK: - Disconnected View

    @ViewBuilder
    private func disconnectedView() -> some View {
        VStack(spacing: 24) {
            Spacer()

            GlassCard {
                VStack(spacing: 20) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.tertiaryText)

                    VStack(spacing: 8) {
                        Text("No Controller Connected")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.primaryText)

                        Text("Connect an AC Infinity controller to monitor environmental conditions in real-time")
                            .font(.system(size: 15))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    NeonButton("Connect Controller", style: .primary) {
                        showingConnectionWizard = true
                    }
                }
                .padding(.vertical, 20)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                Text("With AC Infinity integration you get:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondaryText)

                featureRow(icon: "thermometer.medium", text: "Real-time temperature & humidity monitoring")
                featureRow(icon: "gauge.medium", text: "Automatic VPD calculation")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Historical data visualization")
                featureRow(icon: "bell.badge", text: "Custom alerts for out-of-range conditions")
                featureRow(icon: "slider.horizontal.3", text: "Remote controller adjustments")
            }
            .padding()

            Spacer()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.electricGreen)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
    }

    // MARK: - Data Loading & Monitoring

    @MainActor
    private func handleDeviceChange() async {
        guard assignedDevice != nil else {
            environmentalDataStore.stopMonitoring(plantId: plantId)
            historyError = nil
            isLoadingHistory = false
            return
        }

        startMonitoringIfNeeded()
        await loadHistoricalData(forceReload: true)
    }

    @MainActor
    private func startMonitoringIfNeeded() {
        guard assignedDevice != nil else { return }
        environmentalDataStore.startMonitoring(plantId: plantId)
    }

    @MainActor
    private func loadHistoricalData(forceReload: Bool = false) async {
        guard assignedDevice != nil else {
            historyError = nil
            isLoadingHistory = false
            return
        }

        if isLoadingHistory && !forceReload {
            return
        }

        isLoadingHistory = true
        historyError = nil

        let endDate = Date()
        let daysBack = selectedTimeRange.daysBack
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: endDate)
            ?? endDate.addingTimeInterval(-Double(daysBack) * 24 * 3600)

        do {
            try await environmentalDataStore.loadHistoricalData(
                plantId: plantId,
                startDate: startDate,
                endDate: endDate
            )
            isLoadingHistory = false
        } catch {
            historyError = error.localizedDescription
            isLoadingHistory = false
        }
    }
}

extension RealtimeEnvironmentalData {
    var color: Color {
        switch status {
        case .optimal: return .electricGreen
        case .caution: return .warningOrange
        case .critical: return .criticalRed
        case .offline: return .tertiaryText
        }
    }
}

// MARK: - Alert Configuration View

struct AlertConfigurationView: View {
    let plantId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(EnvironmentalDataStore.self) private var environmentalDataStore

    @State private var thresholds = EnvironmentalThresholds()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Temperature Alerts")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primaryText)

                                rangeSlider(
                                    label: "Acceptable Range",
                                    minValue: $thresholds.temperatureMin,
                                    maxValue: $thresholds.temperatureMax,
                                    range: 60...90,
                                    unit: "°F"
                                )
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Humidity Alerts")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primaryText)

                                rangeSlider(
                                    label: "Acceptable Range",
                                    minValue: $thresholds.humidityMin,
                                    maxValue: $thresholds.humidityMax,
                                    range: 30...80,
                                    unit: "%"
                                )
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("VPD Alerts")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primaryText)

                                rangeSlider(
                                    label: "Acceptable Range",
                                    minValue: $thresholds.vpdMin,
                                    maxValue: $thresholds.vpdMax,
                                    range: 0.4...2.0,
                                    unit: " kPa"
                                )
                            }
                        }

                        NeonButton("Save Alert Settings", style: .primary) {
                            saveThresholds()
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Alert Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
        }
        .onAppear {
            loadThresholds()
        }
    }

    @MainActor
    private func saveThresholds() {
        environmentalDataStore.updateThresholds(thresholds, for: plantId)
        dismiss()
    }

    @MainActor
    private func loadThresholds() {
        thresholds = environmentalDataStore.thresholds(for: plantId)
    }

    private func rangeSlider(
        label: String,
        minValue: Binding<Double>,
        maxValue: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)

            HStack {
                Text("\(Int(minValue.wrappedValue))\(unit)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .frame(width: 70, alignment: .leading)

                Text("-")
                    .foregroundColor(.tertiaryText)

                Text("\(Int(maxValue.wrappedValue))\(unit)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .frame(width: 70, alignment: .trailing)
            }

            // TODO: Implement custom range slider
            // For now using standard sliders
            HStack(spacing: 12) {
                Slider(value: minValue, in: range)
                    .tint(Color.electricGreen)
                Slider(value: maxValue, in: range)
                    .tint(Color.cyanBright)
            }
        }
    }
}

// MARK: - Preview

@MainActor
private func makeConnectedPreview() -> some View {
    let deviceStore = DeviceStore.preview
    let envStore = EnvironmentalDataStore(deviceStore: deviceStore)
    let plantId = UUID()

    if let device = deviceStore.connectedDevices.first {
        deviceStore.assignToPlant(device, plantId: plantId)
    }

    envStore.generateMockData(for: plantId)

    return EnvironmentTabView(plantId: plantId)
        .environment(deviceStore)
        .environment(envStore)
}

#Preview("Environment Tab - Connected") {
    makeConnectedPreview()
}

// MARK: - Environment Status Color Extension

extension RealtimeEnvironmentalData.EnvironmentStatus {
    var color: Color {
        switch self {
        case .optimal:
            return .electricGreen
        case .caution:
            return .yellow
        case .critical:
            return .red
        case .offline:
            return .tertiaryText
        }
    }
}

#Preview("Environment Tab - Disconnected") {
    let deviceStore = DeviceStore()
    let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

    return EnvironmentTabView(plantId: UUID())
        .environment(deviceStore)
        .environment(envStore)
}
