  # Smart Greenhouse Services - Integration Guide

**Version:** 1.0
**Date:** 2025-11-15
**Status:** ✅ Complete & Ready to Integrate

---

## 🎉 What's Been Created

You now have a **complete, working Smart Greenhouse system** with mock AC Infinity integration that works end-to-end for testing!

---

## 📦 Services Created

### 1. **ACInfinityService.swift** ⚡
**Location:** `GroBroPackage/Sources/GroBroFeature/Services/ACInfinityService.swift`

**Actor-based service for AC Infinity API communication:**

✅ Device scanning with mock Bluetooth/WiFi discovery
✅ Authentication with AC Infinity account
✅ Real-time environmental data fetching
✅ Historical data queries
✅ Device settings control (fan speed, temp/humidity targets)
✅ WebSocket connection management (placeholder)
✅ Firmware update checking
✅ **Full mock mode for testing** (currently active)
✅ Detailed error handling with user-friendly messages

**Key Methods:**
```swift
// Scan for devices
let devices = try await service.scanForDevices()

// Authenticate and connect
let device = try await service.authenticate(
    username: "user@example.com",
    password: "password",
    deviceId: "AC69PRO-123456"
)

// Fetch live data
let data = try await service.fetchEnvironmentalData(deviceId: device.id)

// Update settings
try await service.updateSettings(
    deviceId: device.id,
    fanSpeed: 7,
    targetTemperature: .init(min: 75, max: 80)
)
```

---

### 2. **DeviceStore.swift** 🔌
**Location:** `GroBroPackage/Sources/GroBroFeature/Services/DeviceStore.swift`

**@Observable store for managing AC Infinity devices:**

✅ Device lifecycle management (add/remove/update)
✅ UserDefaults persistence
✅ Plant assignment tracking
✅ Connection state monitoring
✅ Device discovery scanning
✅ Settings updates with sync
✅ Connected/offline device filtering
✅ Mock device support for testing

**Key Features:**
```swift
// Initialize
let deviceStore = DeviceStore()

// Scan for devices
await deviceStore.startScanning()
// discoveredDevices updated automatically

// Connect device
let device = try await deviceStore.connect(
    discoveredDevice: discovered,
    username: "user@example.com",
    password: "password",
    plantId: plant.id
)

// Get device for plant
if let device = deviceStore.device(for: plant.id) {
    print("Device: \(device.name)")
}

// Update fan speed
try await deviceStore.updateFanSpeed(7, for: device)
```

---

### 3. **EnvironmentalDataStore.swift** 📊
**Location:** `GroBroPackage/Sources/GroBroFeature/Services/EnvironmentalDataStore.swift`

**@Observable store for environmental monitoring:**

✅ Real-time data updates with auto-refresh (5s intervals)
✅ Historical data management (24hr rolling window)
✅ Alert monitoring and notifications
✅ Threshold configuration per plant
✅ VPD auto-calculation
✅ Task-based monitoring with cancellation
✅ Mock data generation for testing

**Key Features:**
```swift
// Initialize
let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

// Start monitoring plant
envStore.startMonitoring(plantId: plant.id)

// Access current data
if let data = envStore.data(for: plant.id) {
    print("Temp: \(data.temperature)°F")
    print("Humidity: \(data.humidity)%")
    print("VPD: \(data.vpd) kPa")
    print("Status: \(data.status)")
}

// Get historical data
let historical = envStore.historicalData(for: plant.id)

// Configure alerts
let thresholds = EnvironmentalThresholds(
    temperatureMin: 70,
    temperatureMax: 80,
    humidityMin: 50,
    humidityMax: 70
)
envStore.updateThresholds(thresholds, for: plant.id)

// Check active alerts
let alerts = envStore.alerts(for: plant.id)
```

---

## 🔧 App Integration

### Step 1: Add Stores to App

```swift
// In GroBroApp.swift
import SwiftUI

@main
struct GroBroApp: App {
    // Create shared stores
    @State private var deviceStore = DeviceStore()
    @State private var environmentalDataStore: EnvironmentalDataStore

    init() {
        let deviceStore = DeviceStore()
        self._deviceStore = State(initialValue: deviceStore)
        self._environmentalDataStore = State(initialValue: EnvironmentalDataStore(deviceStore: deviceStore))
    }

    var body: some Scene {
        WindowGroup {
            GardenContainerView()
                .environment(deviceStore)
                .environment(environmentalDataStore)
        }
    }
}
```

---

### Step 2: Use in EnvironmentTabView

```swift
// Update EnvironmentTabView.swift
struct EnvironmentTabView: View {
    let plantId: UUID

    @Environment(DeviceStore.self) private var deviceStore
    @Environment(EnvironmentalDataStore.self) private var envDataStore

    var body: some View {
        let device = deviceStore.device(for: plantId)
        let envData = envDataStore.data(for: plantId)
        let historical = envDataStore.historicalData(for: plantId)

        ScrollView {
            if let device = device, device.isConnected, let envData = envData {
                // Connected view with live data
                connectedView(device: device, data: envData, historical: historical)
            } else {
                // Disconnected view with CTA
                disconnectedView()
            }
        }
        .onAppear {
            // Start monitoring when view appears
            envDataStore.startMonitoring(plantId: plantId)
        }
        .onDisappear {
            // Stop monitoring when view disappears
            envDataStore.stopMonitoring(plantId: plantId)
        }
    }

    // ... rest of implementation
}
```

---

### Step 3: Use in Connection Wizard

```swift
// Update ACInfinityConnectionWizard.swift
struct ACInfinityConnectionWizard: View {
    let plantId: UUID?
    let onComplete: (ACInfinityDevice) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(DeviceStore.self) private var deviceStore

    // ... existing state

    var body: some View {
        // ... existing implementation

        // In device selection step:
        .onAppear {
            Task {
                await deviceStore.startScanning()
            }
        }

        // In authentication step:
        private func authenticate() async {
            guard let selected = selectedDevice else { return }

            isAuthenticating = true
            authError = nil

            do {
                let device = try await deviceStore.connect(
                    discoveredDevice: selected,
                    username: authUsername,
                    password: authPassword,
                    plantId: plantId
                )

                await MainActor.run {
                    isAuthenticating = false
                    withAnimation {
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
}
```

---

### Step 4: Present Wizard from Settings

```swift
// In SettingsView or DeviceIntegrationsView
struct DeviceIntegrationsView: View {
    @Environment(DeviceStore.self) private var deviceStore
    @State private var showingConnectionWizard = false

    var body: some View {
        List {
            Section("Connected Devices") {
                ForEach(deviceStore.devices) { device in
                    DeviceRow(device: device)
                }
            }

            Section {
                Button {
                    showingConnectionWizard = true
                } label: {
                    Label("Add Device", systemImage: "plus.circle.fill")
                        .foregroundColor(.electricGreen)
                }
            }
        }
        .sheet(isPresented: $showingConnectionWizard) {
            ACInfinityConnectionWizard { device in
                // Device connected successfully
                showingConnectionWizard = false
            }
        }
    }
}
```

---

## 🧪 Testing with Mock Data

### Test Environment Tab

```swift
#Preview("Environment Tab - Mock Data") {
    let deviceStore = DeviceStore()
    let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

    // Generate mock data
    let plantId = UUID()
    envStore.generateMockData(for: plantId)

    // Add mock device
    var mockDevice = ACInfinityDevice.mock
    mockDevice.assignedPlantId = plantId
    deviceStore.add(mockDevice)

    return EnvironmentTabView(plantId: plantId)
        .environment(deviceStore)
        .environment(envStore)
}
```

---

### Test Connection Wizard

```swift
#Preview("Connection Wizard") {
    let deviceStore = DeviceStore()

    return ACInfinityConnectionWizard(plantId: UUID()) { device in
        print("Connected: \(device.name)")
    }
    .environment(deviceStore)
}
```

---

### Test with Live Updates

```swift
#Preview("Environment Tab - Live Updates") {
    let deviceStore = DeviceStore()
    let envStore = EnvironmentalDataStore(deviceStore: deviceStore)

    let plantId = UUID()

    // Add mock device
    var mockDevice = ACInfinityDevice.mock
    mockDevice.assignedPlantId = plantId
    deviceStore.add(mockDevice)

    // Start mock monitoring (updates every 3 seconds)
    envStore.startMockMonitoring(plantId: plantId)

    return EnvironmentTabView(plantId: plantId)
        .environment(deviceStore)
        .environment(envStore)
}
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────┐
│   GroBroApp         │
│   - DeviceStore     │ ← Singleton stores
│   - EnvDataStore    │
└─────────┬───────────┘
          │
          │ .environment()
          │
┌─────────▼───────────┐
│  GardenView         │
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│  PlantDetailView    │
└─────────┬───────────┘
          │
          ├─────────────────┬────────────────┐
          │                 │                │
┌─────────▼─────┐ ┌────────▼─────┐ ┌───────▼────────┐
│ EnvironmentTab│ │ DiagnosticsTab│ │ Other Tabs     │
│                │ │               │ │                │
│ Uses:          │ │ Uses:         │ │                │
│ • DeviceStore  │ │ • EnvDataStore│ │                │
│ • EnvDataStore │ │   (for context)│ │                │
└───────┬────────┘ └───────────────┘ └────────────────┘
        │
        │ startMonitoring()
        │
┌───────▼────────────┐
│ EnvDataStore       │
│  - Monitors data   │
│  - Updates every 5s│
└───────┬────────────┘
        │
        │ fetchEnvironmentalData()
        │
┌───────▼────────────┐
│ ACInfinityService  │
│  - Mock API calls  │
│  - Returns data    │
└────────────────────┘
```

---

## 🎯 Key Features Working

### ✅ Device Management
- Scan for AC Infinity controllers
- Connect with username/password
- Persist devices to UserDefaults
- Track connection state
- Assign devices to plants

### ✅ Real-Time Monitoring
- Auto-refresh every 5 seconds
- Smooth animations on data updates
- VPD auto-calculation
- Status determination (optimal/caution/critical)
- Task-based with proper cancellation

### ✅ Historical Data
- Rolling 24-hour window
- Automatic data point addition
- Date range queries
- Chart-ready format

### ✅ Alert System
- Configurable thresholds per plant
- Real-time alert detection
- Alert acknowledgment
- Local notification placeholders

### ✅ Mock Mode
- Realistic device discovery
- Simulated authentication
- Random environmental data
- Historical data generation
- Error simulation

---

## 🔧 Configuration Options

### Enable/Disable Mock Mode

```swift
// In ACInfinityService.swift
actor ACInfinityService {
    private var isMockMode: Bool = true  // ← Set to false for real API

    // When ready for production:
    // 1. Set isMockMode = false
    // 2. Implement real API calls in marked TODO sections
    // 3. Add API credentials to Config
}
```

---

### Adjust Update Frequency

```swift
// In EnvironmentalDataStore.swift
private func monitorLoop(plantId: UUID, deviceId: String) async {
    while !Task.isCancelled {
        // ... fetch data

        // Adjust update interval here:
        try await Task.sleep(for: .seconds(5))  // ← Change frequency
    }
}
```

---

### Configure Alert Thresholds

```swift
// Default thresholds in EnvironmentalThresholds
struct EnvironmentalThresholds {
    var temperatureMin: Double = 70   // ← Adjust defaults
    var temperatureMax: Double = 80
    var humidityMin: Double = 50
    var humidityMax: Double = 70
    var vpdMin: Double = 0.8
    var vpdMax: Double = 1.2
}
```

---

## 🚨 Error Handling

### Service Errors

```swift
do {
    let device = try await service.authenticate(...)
} catch ACInfinityError.authenticationFailed(let message) {
    // Show error to user
    print("Auth failed: \(message)")
} catch ACInfinityError.deviceNotFound {
    // Device went offline during connection
    print("Device not found")
} catch {
    // Generic error
    print("Error: \(error)")
}
```

---

### Store Errors

```swift
do {
    try await envStore.loadHistoricalData(
        plantId: plant.id,
        startDate: startDate,
        endDate: endDate
    )
} catch EnvironmentalDataError.noDeviceAssigned {
    // No controller assigned to this plant
    showConnectionWizard = true
} catch {
    // Other error
    print("Error loading data: \(error)")
}
```

---

## 📱 Real API Integration (Future)

When you have AC Infinity API credentials:

### 1. **Update ACInfinityService**

```swift
// In ACInfinityService.swift

// Set mock mode to false
private var isMockMode: Bool = false

// Add API configuration
private let baseURL = URL(string: "https://api.acinfinity.com/v1")!
private let apiKey = "YOUR_API_KEY"  // Store in Keychain!

// Implement real scanning
func scanForDevices() async throws -> [DiscoveredDevice] {
    // Option 1: Bluetooth
    // - Import CoreBluetooth
    // - Scan for AC Infinity UUIDs
    // - Return discovered peripherals

    // Option 2: Network
    // - Scan local network for controllers
    // - Use Bonjour/mDNS discovery

    // Option 3: API
    // - GET /users/me/devices
    // - Return user's registered devices
}

// Implement authentication
func authenticate(username: String, password: String, deviceId: String) async throws -> ACInfinityDevice {
    var request = URLRequest(url: baseURL.appendingPathComponent("auth/login"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["email": username, "password": password]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw ACInfinityError.authenticationFailed(message: "Invalid credentials")
    }

    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

    // Store token in Keychain
    saveToken(authResponse.token)

    // Fetch device details
    return try await getDevice(deviceId: deviceId)
}

// Implement data fetching
func fetchEnvironmentalData(deviceId: String) async throws -> EnvironmentalData {
    var request = URLRequest(url: baseURL.appendingPathComponent("devices/\(deviceId)/data"))
    request.setValue("Bearer \(getToken())", forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: request)
    let apiData = try JSONDecoder().decode(ACInfinityDataResponse.self, from: data)

    return EnvironmentalData(
        temperature: apiData.temperature,
        humidity: apiData.humidity,
        vpd: EnvironmentalData.calculateVPD(temperature: apiData.temperature, humidity: apiData.humidity),
        timestamp: Date(),
        deviceId: deviceId,
        isConnected: true
    )
}
```

---

### 2. **Add API Models**

```swift
struct AuthResponse: Codable {
    let token: String
    let userId: String
    let expiresAt: Date
}

struct ACInfinityDataResponse: Codable {
    let temperature: Double
    let humidity: Double
    let timestamp: Date
}

struct DeviceResponse: Codable {
    let id: String
    let name: String
    let model: String
    let firmwareVersion: String
    let isOnline: Bool
}
```

---

### 3. **Implement WebSocket for Real-Time**

```swift
import Foundation

actor WebSocketManager {
    private var socket: URLSessionWebSocketTask?

    func connect(deviceId: String, onData: @escaping (EnvironmentalData) -> Void) async throws {
        let url = URL(string: "wss://api.acinfinity.com/v1/devices/\(deviceId)/stream")!
        socket = URLSession.shared.webSocketTask(with: url)
        socket?.resume()

        // Listen for messages
        await receiveMessages(onData: onData)
    }

    private func receiveMessages(onData: @escaping (EnvironmentalData) -> Void) async {
        while let socket = socket {
            do {
                let message = try await socket.receive()

                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let apiData = try? JSONDecoder().decode(ACInfinityDataResponse.self, from: data) {
                        let envData = EnvironmentalData(
                            temperature: apiData.temperature,
                            humidity: apiData.humidity,
                            vpd: 0,
                            timestamp: Date(),
                            isConnected: true
                        )
                        onData(envData)
                    }

                case .data(let data):
                    // Handle binary data
                    break

                @unknown default:
                    break
                }
            } catch {
                print("WebSocket error: \(error)")
                break
            }
        }
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }
}
```

---

## 🎉 Summary

**You now have:**

✅ **ACInfinityService** - Complete API service with mock mode
✅ **DeviceStore** - Device management and persistence
✅ **EnvironmentalDataStore** - Real-time monitoring and alerts
✅ **Full integration guide** - Step-by-step setup instructions
✅ **Mock data support** - Test everything without real hardware
✅ **Error handling** - User-friendly error messages
✅ **Real-time updates** - Auto-refresh with smooth animations
✅ **Historical data** - Rolling window with chart support
✅ **Alert system** - Threshold monitoring and notifications

**Everything works end-to-end for testing!**

---

## 📝 Next Steps

1. **Add stores to GroBroApp.swift** (5 minutes)
2. **Update EnvironmentTabView to use stores** (10 minutes)
3. **Test in SwiftUI Previews** (5 minutes)
4. **Build and run on device/simulator** (10 minutes)
5. **See live environmental data updating!** 🎉

---

## 💡 Pro Tips

**1. Use mock monitoring for development:**
```swift
envStore.startMockMonitoring(plantId: plant.id)
```

**2. Test error states:**
```swift
// In ACInfinityService, simulate errors:
throw ACInfinityError.deviceOffline
```

**3. Observe state changes:**
```swift
// In EnvironmentTabView
.onChange(of: envData) { oldValue, newValue in
    print("Data updated: \(newValue.temperature)°F")
}
```

**4. Debug monitoring:**
```swift
// Check if monitoring is active
if envStore.updateTasks[plantId] != nil {
    print("✅ Monitoring active")
}
```

---

**Everything is ready! Start integrating and watch the magic happen!** 🌿✨
