import SwiftUI
import ARKit
import RealityKit
import GroBroDomain

#if os(iOS)

/// AR-based light distance measurement view
@available(iOS 14.0, *)
@MainActor
public struct LightDistanceARView: View {
    @Environment(\.dismiss) private var dismiss
    let plant: Plant
    let onSave: (Double, LightType) -> Void

    @State private var lightMarker: simd_float3?
    @State private var canopyMarker: simd_float3?
    @State private var distance: Double?
    @State private var selectedLightType: LightType = .fullSpectrumLED
    @State private var showTutorial: Bool
    @State private var showManualEntry = false
    @State private var arAvailable = true

    public init(plant: Plant, onSave: @escaping (Double, LightType) -> Void) {
        self.plant = plant
        self.onSave = onSave
        _showTutorial = State(initialValue: !UserDefaults.standard.bool(forKey: "hasSeenLightARTutorial"))
        if let existingType = plant.lightType {
            _selectedLightType = State(initialValue: existingType)
        }
    }

    public var body: some View {
        ZStack {
            if arAvailable && !showManualEntry {
                // AR Camera View
                ARViewContainer(
                    lightMarker: $lightMarker,
                    canopyMarker: $canopyMarker,
                    distance: $distance
                )
                .ignoresSafeArea()

                // AR Overlay UI
                VStack {
                    // Distance display
                    if let dist = distance {
                        distanceCard(dist)
                            .padding(.top, 60)
                    }

                    Spacer()

                    // Instructions
                    instructionCard
                        .padding(.bottom, 20)

                    // Controls
                    controlsCard
                        .padding(.bottom, 40)
                }
                .padding(.horizontal)
            } else {
                // Fallback: Manual entry
                ManualDistanceEntryView(
                    plant: plant,
                    lightType: $selectedLightType,
                    onSave: onSave
                )
            }

            // Tutorial overlay
            if showTutorial && arAvailable && !showManualEntry {
                LightDistanceTutorial(isPresented: $showTutorial)
            }
        }
        .navigationTitle("Measure Light Distance")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Manual") {
                    showManualEntry = true
                }
            }
        }
        .onAppear {
            checkARAvailability()
        }
    }

    private func distanceCard(_ dist: Double) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text("\(Int(dist.rounded()))\"")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.electricGreen)
                }

                VStack(alignment: .leading) {
                    Text("Centimeters")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text("\(Int((dist * 2.54).rounded())) cm")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyanBright)
                }
            }

            // Recommendation
            if let recommendation = getRecommendation(for: dist) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor(recommendation.status))
                        .frame(width: 12, height: 12)

                    Text(recommendation.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .electricGreen.opacity(0.3), radius: 10)
    }

    private var instructionCard: some View {
        Text(instructionText)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primaryText)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var instructionText: String {
        if lightMarker == nil {
            return "☝️ Tap your light source"
        } else if canopyMarker == nil {
            return "🌱 Tap your plant canopy"
        } else {
            return "✅ Measurement complete!"
        }
    }

    private var controlsCard: some View {
        VStack(spacing: 12) {
            // Light type picker
            Picker("Light Type", selection: $selectedLightType) {
                ForEach(LightType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                // Reset button
                Button(action: resetMeasurement) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tertiaryText.opacity(0.2))
                    .foregroundColor(.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Save button
                Button(action: saveMeasurement) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        distance != nil ?
                        LinearGradient(
                            colors: [.electricGreen, .neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : LinearGradient(
                            colors: [.tertiaryText, .tertiaryText],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.deepBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(distance == nil)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func resetMeasurement() {
        lightMarker = nil
        canopyMarker = nil
        distance = nil
    }

    private func saveMeasurement() {
        guard let dist = distance else { return }
        onSave(dist, selectedLightType)
        dismiss()
    }

    private func getRecommendation(for distance: Double) -> LightDistanceRecommendationEngine.DistanceRecommendation? {
        let engine = LightDistanceRecommendationEngine()
        return engine.evaluate(distance: distance, lightType: selectedLightType, stage: plant.stage)
    }

    private func statusColor(_ status: LightDistanceRecommendationEngine.DistanceStatus) -> Color {
        switch status {
        case .optimal:
            return .successGreen
        case .tooClose:
            return .warningOrange
        case .tooFar:
            return .infoCyan
        }
    }

    private func checkARAvailability() {
        arAvailable = ARWorldTrackingConfiguration.isSupported
    }
}

/// UIViewRepresentable wrapper for ARView
@available(iOS 14.0, *)
struct ARViewContainer: UIViewRepresentable {
    @Binding var lightMarker: simd_float3?
    @Binding var canopyMarker: simd_float3?
    @Binding var distance: Double?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        // Enable scene reconstruction if available (LiDAR devices)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(configuration)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            lightMarker: $lightMarker,
            canopyMarker: $canopyMarker,
            distance: $distance
        )
    }

    @MainActor
    class Coordinator: NSObject {
        @Binding var lightMarker: simd_float3?
        @Binding var canopyMarker: simd_float3?
        @Binding var distance: Double?
        var arView: ARView?

        init(
            lightMarker: Binding<simd_float3?>,
            canopyMarker: Binding<simd_float3?>,
            distance: Binding<Double?>
        ) {
            _lightMarker = lightMarker
            _canopyMarker = canopyMarker
            _distance = distance
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            let location = gesture.location(in: arView)
            let results = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .any
            )

            guard let result = results.first else { return }

            let position = simd_make_float3(result.worldTransform.columns.3)

            if lightMarker == nil {
                // First tap: mark light source
                lightMarker = position
                addMarker(at: position, color: .yellow, in: arView)
            } else if canopyMarker == nil {
                // Second tap: mark canopy
                canopyMarker = position
                addMarker(at: position, color: .green, in: arView)

                // Draw measurement line
                if let light = lightMarker {
                    drawMeasurementLine(from: light, to: position, in: arView)

                    // Calculate distance
                    let distanceMeters = simd_distance(light, position)
                    let distanceInches = Double(distanceMeters) * 39.3701
                    distance = distanceInches
                }
            }
        }

        func addMarker(at position: simd_float3, color: UIColor, in arView: ARView) {
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.02),
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )

            let anchor = AnchorEntity(world: position)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
        }

        func drawMeasurementLine(from start: simd_float3, to end: simd_float3, in arView: ARView) {
            // Calculate midpoint for line
            let midpoint = (start + end) / 2

            // Create line using box mesh (stretched cylinder would be better but more complex)
            let distance = simd_distance(start, end)
            let line = ModelEntity(
                mesh: .generateBox(width: 0.005, height: Float(distance), depth: 0.005),
                materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
            )

            // Position and orient the line
            let anchor = AnchorEntity(world: midpoint)

            // Calculate rotation to align with start-end vector
            let direction = normalize(end - start)
            let up = simd_float3(0, 1, 0)
            let angle = acos(dot(direction, up))
            let axis = cross(up, direction)

            if simd_length(axis) > 0.001 {
                line.orientation = simd_quatf(angle: angle, axis: normalize(axis))
            }

            anchor.addChild(line)
            arView.scene.addAnchor(anchor)
        }
    }
}

#endif
