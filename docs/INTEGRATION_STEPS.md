# Smart Greenhouse - Integration Steps (30 Minutes)

**Status:** Ready to integrate
**Estimated Time:** 30 minutes
**Required Files:** All created ✅

---

## Step 1: Update GroBroApp.swift (5 min)

**File:** `/Users/pokrasote/Dev/grobro/GroBro/GroBroApp.swift`

**Replace entire file with:**

```swift
import SwiftUI
import GroBroFeature
import GroBroDomain
import GroBroPersistence

@main
struct AppEntry: App {
    // Initialize persistence controller once at app startup
    @MainActor
    private let persistenceController = PersistenceController.shared

    // Initialize Pro entitlement manager
    @MainActor
    @State private var proManager = ProEntitlementManager()

    // NEW: Smart Greenhouse stores
    @MainActor
    @State private var deviceStore = DeviceStore()

    @MainActor
    @State private var environmentalDataStore: EnvironmentalDataStore

    @MainActor
    private var plantStore: PlantStore {
        PlantStore(persistenceController: persistenceController)
    }

    @MainActor
    private var eventStore: EventStore {
        EventStore(persistenceController: persistenceController)
    }

    init() {
        // Initialize device store first
        let deviceStore = DeviceStore()
        self._deviceStore = State(initialValue: deviceStore)

        // Initialize environmental data store with device store dependency
        self._environmentalDataStore = State(
            initialValue: EnvironmentalDataStore(deviceStore: deviceStore)
        )
    }

    var body: some Scene {
        WindowGroup {
            GardenContainerView(plantStore: plantStore, eventStore: eventStore)
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environment(proManager)
                .environment(deviceStore)              // NEW
                .environment(environmentalDataStore)   // NEW
        }
    }
}
```

**What changed:**
- ✅ Added `DeviceStore` initialization
- ✅ Added `EnvironmentalDataStore` initialization
- ✅ Injected both via `.environment()`

---

## Step 2: Add Environment Tab to PlantDetailView (10 min)

**File:** Find your `PlantDetailView.swift` (likely in `GroBroPackage/Sources/GroBroFeature/Views/PlantDetail/`)

### 2a. Add environment tab enum

```swift
// In PlantDetailView.swift, update your Tab enum:

enum Tab: Hashable {
    case overview
    case watering
    case diagnostics
    case environment  // NEW!
    case light
    case ai
    case timeline
}
```

### 2b. Add tab to TabView

```swift
// In your TabView, add this new tab:

TabView(selection: $selectedTab) {
    // ... existing tabs ...

    // NEW: Environment Tab
    EnvironmentTabView(plantId: plant.id)
        .tabItem {
            Label("Environment", systemImage: "thermometer.medium")
        }
        .tag(Tab.environment)

    // ... rest of tabs ...
}
```

### 2c. Update tab bar icons (if you're customizing them)

```swift
// If you have custom tab bar styling, add:
case .environment:
    Image(systemName: "thermometer.medium")
        .foregroundColor(selectedTab == .environment ? .electricGreen : .secondaryText)
```

---

## Step 3: Create Device Integrations Settings Screen (10 min)

**File:** Create `/Users/pokrasote/Dev/grobro/GroBroPackage/Sources/GroBroFeature/Views/Settings/DeviceIntegrationsView.swift`

**Content:**

```swift
import SwiftUI

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
        DeviceIntegrationsView()
            .environment(DeviceStore.preview)
    }
}
```

---

## Step 4: Add Device Integrations to Settings (5 min)

**File:** Find your Settings view (likely `SettingsView.swift`)

**Add this to your settings list:**

```swift
// In your Settings List:

Section("Integrations") {
    NavigationLink {
        DeviceIntegrationsView()
    } label: {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(.electricGreen)

            Text("Device Integrations")
                .foregroundColor(.primaryText)
        }
    }
    .listRowBackground(Color.surfaceDark.opacity(0.5))
}
```

---

## Step 5: Build & Test (2 min)

### 5a. Build the project

```bash
# In Xcode:
Cmd+B (Build)

# Or terminal:
cd /Users/pokrasote/Dev/grobro
xcodebuild -workspace GroBro.xcworkspace -scheme GroBro -sdk iphonesimulator
```

### 5b. Run on Simulator

```bash
# Select iPhone 17 simulator
# Press Cmd+R (Run)
```

### 5c. Test the flow

1. **Open app** → See Garden
2. **Tap a plant** → See Plant Detail
3. **Tap Environment tab** → See disconnected state
4. **Tap "Connect Controller"** → Connection wizard opens
5. **Wait 2 seconds** → Devices appear
6. **Tap a device** → Continue to auth
7. **Enter any email/password (6+ chars)** → Authentication succeeds
8. **Continue** → Plant assignment
9. **Tap "Complete Setup"** → Success screen
10. **Tap "Done"** → Back to Environment tab with LIVE DATA! 🎉

---

## Step 6: Enable Mock Monitoring (Optional - For Demo)

**To see data updating in real-time:**

**File:** `EnvironmentTabView.swift`

**Add to `.onAppear`:**

```swift
.onAppear {
    #if DEBUG
    // Start mock monitoring for demo
    if device == nil {
        // Generate mock device
        var mockDevice = ACInfinityDevice.mock
        mockDevice.assignedPlantId = plantId
        deviceStore.add(mockDevice)

        // Start mock updates
        envDataStore.startMockMonitoring(plantId: plantId)
    }
    #endif

    // Regular monitoring
    envDataStore.startMonitoring(plantId: plantId)
}
```

---

## Troubleshooting

### Issue: "Cannot find 'DeviceStore' in scope"

**Fix:** Make sure imports are correct in files:

```swift
import GroBroFeature  // Contains DeviceStore, EnvironmentalDataStore
import GroBroDomain   // Contains models
```

---

### Issue: "Type 'EnvironmentalDataStore' has no member 'init'"

**Fix:** Make sure init is public:

```swift
// In EnvironmentalDataStore.swift, check:
public init(deviceStore: DeviceStore) { ... }
```

---

### Issue: Preview not working

**Fix:** Add preview store:

```swift
#Preview {
    EnvironmentTabView(plantId: UUID())
        .environment(DeviceStore.preview)
        .environment(EnvironmentalDataStore.preview)
}
```

---

## What You'll See

### Before Connection:
- Empty state with "Connect Controller" button
- Feature list
- Clean UI with glassmorphic cards

### After Connection:
- ✅ Connection status card (green pulsing)
- ✅ Large temp/humidity displays
- ✅ VPD calculation with status badge
- ✅ Beautiful trend charts
- ✅ Controller settings display
- ✅ Action buttons (Configure Alerts, View History)
- ✅ Data updating every 5 seconds with smooth animations!

---

## Quick Checklist

**Files to modify:**
- [ ] `GroBro/GroBroApp.swift` - Add stores
- [ ] `PlantDetailView.swift` - Add Environment tab
- [ ] Create `DeviceIntegrationsView.swift` - New settings screen
- [ ] `SettingsView.swift` - Add integrations link

**Files already created (no changes needed):**
- [x] `SmartGreenhouseColors.swift`
- [x] `GlassCard.swift`
- [x] `NeonButton.swift`
- [x] `EnvironmentalWidget.swift`
- [x] `EnvironmentTabView.swift`
- [x] `ACInfinityConnectionWizard.swift`
- [x] `ACInfinityService.swift`
- [x] `DeviceStore.swift`
- [x] `EnvironmentalDataStore.swift`
- [x] Models (`EnvironmentalData.swift`, `ACInfinityDevice.swift`)

---

## Next Steps After Integration

1. **Test on real device** (not just simulator)
2. **Take screenshots** for App Store
3. **Get AC Infinity API credentials**
4. **Replace mock mode** with real API
5. **Add push notifications** for alerts
6. **Ship to TestFlight!** 🚀

---

## Support

**Issues? Questions?**
- Check `docs/smart-greenhouse-services-integration-guide.md`
- Review `docs/smart-greenhouse-design-spec.md`
- All components have SwiftUI Previews - test them!

---

**Total Integration Time: ~30 minutes** ⏱️

**Result: Beautiful, working Smart Greenhouse experience!** 🎉
