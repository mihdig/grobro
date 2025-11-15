import SwiftUI
import GroBroDomain

#if os(iOS)
import AVFoundation

@available(iOS 17.0, *)
public struct LightMeterView: View {

    @StateObject private var viewModel: LightMeterViewModel

    public init(plant: Plant?) {
        _viewModel = StateObject(
            wrappedValue: LightMeterViewModel(plant: plant)
        )
    }

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                LightMeterCameraView { iso, exposureSeconds, aperture in
                    viewModel.updateFromCamera(
                        iso: iso,
                        exposureDurationSeconds: exposureSeconds,
                        aperture: aperture
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack {
                    Spacer()
                    Text("Point camera at canopy for a few seconds")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 12)
                }
            }
            .padding(.horizontal)

            measurementSection
            controlsSection

            Text("Estimates only. For precise readings, use a professional PAR meter.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Light Meter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var measurementSection: some View {
        VStack(spacing: 8) {
            if let measurement = viewModel.currentMeasurement {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PPFD")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(measurement.ppfd)) μmol/m²/s")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lux")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(measurement.lux)) lx")
                            .font(.title3)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("DLI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f mol/m²/day", measurement.dli))
                            .font(.title3)
                    }
                }
                .padding()

                if let zone = viewModel.intensityZone {
                    HStack {
                        Circle()
                            .fill(zoneColor(zone))
                            .frame(width: 12, height: 12)

                        Text(zoneMessage(zone: zone))
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            } else {
                Text("Move your camera over the canopy to start measuring.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Light Type")
                Spacer()
                Picker("Light Type", selection: $viewModel.lightType) {
                    ForEach(LightType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Photoperiod")
                Spacer()
                Stepper(
                    value: $viewModel.photoperiodHours,
                    in: 8...24,
                    step: 1
                ) {
                    Text("\(Int(viewModel.photoperiodHours)) h/day")
                }
            }

            Button {
                viewModel.toggleFreezeAndLog()
            } label: {
                HStack {
                    Image(systemName: viewModel.isFrozen ? "play.circle.fill" : "pause.circle.fill")
                    Text(viewModel.isFrozen ? "Resume Live Meter" : "Freeze & Log to Diary")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentMeasurement == nil)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }

    private func zoneColor(_ zone: LightIntensityZone) -> Color {
        switch zone {
        case .tooLow:
            return .yellow
        case .optimal:
            return .green
        case .tooHigh:
            return .red
        }
    }

    private func zoneMessage(zone: LightIntensityZone) -> String {
        switch zone {
        case .tooLow:
            return "Below optimal range for current stage. Increase light if possible."
        case .optimal:
            return "Within recommended range for this stage."
        case .tooHigh:
            return "Above optimal range. Consider raising lights or reducing intensity."
        }
    }
}

@available(iOS 17.0, *)
@MainActor
final class LightMeterViewModel: ObservableObject {

    let plant: Plant?
    private let lightMeterService: LightMeterService
    private let eventStore: EventStore

    @Published var lightType: LightType
    @Published var photoperiodHours: Double
    @Published var currentMeasurement: LightMeasurement?
    @Published var intensityZone: LightIntensityZone?
    @Published var isFrozen: Bool = false

    init(
        plant: Plant?,
        lightMeterService: LightMeterService = LightMeterService(),
        eventStore: EventStore = EventStore()
    ) {
        self.plant = plant
        self.lightMeterService = lightMeterService
        self.eventStore = eventStore
        self.lightType = .fullSpectrumLED
        self.photoperiodHours = plant?.lightHoursPerDay ?? 18
    }

    func updateFromCamera(
        iso: Double,
        exposureDurationSeconds: Double,
        aperture: Double
    ) {
        guard !isFrozen else { return }

        let measurement = lightMeterService.makeMeasurement(
            iso: iso,
            exposureDurationSeconds: exposureDurationSeconds,
            aperture: aperture,
            lightType: lightType,
            photoperiodHours: photoperiodHours
        )

        currentMeasurement = measurement
        if let stage = plant?.stage {
            intensityZone = lightMeterService.intensityZone(ppfd: measurement.ppfd, stage: stage)
        } else {
            intensityZone = nil
        }
    }

    func toggleFreezeAndLog() {
        if isFrozen {
            isFrozen = false
        } else {
            isFrozen = true
            logMeasurementIfNeeded()
        }
    }

    private func logMeasurementIfNeeded() {
        guard let plant else { return }
        guard let measurement = currentMeasurement else { return }

        let event = Event(
            plantId: plant.id,
            type: .lightCheck,
            timestamp: Date(),
            noteText: "Light check at canopy",
            stressTags: [],
            source: .lightMeter,
            environmentalData: nil,
            lightMeasurement: LightMeasurementData(
                ppfd: measurement.ppfd,
                lux: measurement.lux,
                dli: measurement.dli,
                lightTypeIdentifier: lightType.rawValue,
                distanceMeters: nil
            )
        )

        do {
            _ = try eventStore.createEvent(event)
        } catch {
            // For now, fail silently in UI
        }
    }
}

@available(iOS 17.0, *)
struct LightMeterCameraView: UIViewRepresentable {

    let onExposureUpdate: (Double, Double, Double) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.configure(onExposureUpdate: onExposureUpdate)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: ()) {
        uiView.stopSession()
    }
}

@available(iOS 17.0, *)
final class CameraPreviewView: UIView {

    private let session = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var timer: Timer?
    private var onExposureUpdate: ((Double, Double, Double) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    func configure(onExposureUpdate: @escaping (Double, Double, Double) -> Void) {
        self.onExposureUpdate = onExposureUpdate

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        device = captureDevice

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            session.sessionPreset = .high
            session.startRunning()

            let previewLayer = self.layer as? AVCaptureVideoPreviewLayer
            previewLayer?.session = session
            previewLayer?.videoGravity = .resizeAspectFill
            self.previewLayer = previewLayer

            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.sampleExposure()
            }
        } catch {
            // Ignore configuration errors in this lightweight implementation
        }
    }

    func stopSession() {
        timer?.invalidate()
        timer = nil
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func sampleExposure() {
        guard let device,
              let onExposureUpdate else { return }

        let iso = Double(device.iso)
        let durationSeconds = device.exposureDuration.seconds
        let aperture = Double(device.lensAperture)

        DispatchQueue.main.async {
            onExposureUpdate(iso, durationSeconds, aperture)
        }
    }
}

#else

@available(macOS 14.0, *)
public struct LightMeterView: View {

    public init(plant: Plant?) {}

    public var body: some View {
        Text("Light meter is only available on iOS devices with a camera.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
    }
}

#endif

