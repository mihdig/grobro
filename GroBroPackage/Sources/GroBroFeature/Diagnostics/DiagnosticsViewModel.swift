import Foundation
import PhotosUI
import SwiftUI
import GroBroDomain

/// State for the diagnostics flow
public enum DiagnosticsState {
    case selectingPhoto
    case analyzing
    case result(DiagnosticsResult)
    case error(String)
}

@MainActor
public final class DiagnosticsViewModel: ObservableObject {
    @Published public var state: DiagnosticsState = .selectingPhoto
    @Published public var selectedPhoto: PhotosPickerItem? {
        didSet {
            if selectedPhoto != nil {
                Task {
                    await loadAndAnalyzePhoto()
                }
            }
        }
    }
    @Published public var showCamera = false

    public let plant: Plant
    private let diagnosticsService: DiagnosticsService

    public init(plant: Plant, diagnosticsService: DiagnosticsService = DiagnosticsService()) {
        self.plant = plant
        self.diagnosticsService = diagnosticsService
    }

    /// Loads the selected photo and runs diagnostics
    private func loadAndAnalyzePhoto() async {
        guard let item = selectedPhoto else { return }

        state = .analyzing

        do {
            // Load image data from PhotosPicker
            guard let data = try await item.loadTransferable(type: Data.self) else {
                state = .error("Failed to load image")
                return
            }

            // Run diagnostics
            let result = try await diagnosticsService.runDiagnostics(
                image: data,
                for: plant
            )

            state = .result(result)
        } catch {
            state = .error("Failed to analyze image: \(error.localizedDescription)")
        }
    }

    /// Resets the diagnostics flow to start over
    public func reset() {
        state = .selectingPhoto
        selectedPhoto = nil
    }
}
