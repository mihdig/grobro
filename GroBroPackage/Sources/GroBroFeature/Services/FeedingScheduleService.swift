import Foundation
import GroBroDomain

/// Service for loading and managing feeding schedules
@MainActor
@Observable
public final class FeedingScheduleService {
    public private(set) var schedules: [FeedingSchedule] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?

    public init() {}

    /// Load all feeding schedules from bundled JSON files
    public func loadSchedules() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            var loadedSchedules: [FeedingSchedule] = []

            // Load GHE Flora Series
            if let floraSchedule = try await loadSchedule(named: "ghe-flora-series") {
                loadedSchedules.append(floraSchedule)
            }

            // Load GHE BioThrive
            if let bioSchedule = try await loadSchedule(named: "ghe-biothrive") {
                loadedSchedules.append(bioSchedule)
            }

            // Load Advanced Nutrients pH Perfect
            if let anSchedule = try await loadSchedule(named: "advanced-nutrients-ph-perfect") {
                loadedSchedules.append(anSchedule)
            }

            schedules = loadedSchedules
        } catch {
            self.error = error
            print("Error loading feeding schedules: \(error)")
        }
    }

    /// Load a specific schedule by product line
    public func schedule(for productLine: ProductLine) -> FeedingSchedule? {
        schedules.first { $0.productLine == productLine }
    }

    /// Get schedules for a specific brand
    public func schedules(for brand: NutrientBrand) -> [FeedingSchedule] {
        schedules.filter { $0.brand == brand }
    }

    /// Get weekly dosage for a specific week in a schedule
    public func weeklyDosage(
        for productLine: ProductLine,
        week: Int
    ) -> WeeklyDosage? {
        guard let schedule = schedule(for: productLine) else { return nil }
        return schedule.weeks.first { $0.weekNumber == week }
    }

    // MARK: - Private Methods

    private func loadSchedule(named name: String) async throws -> FeedingSchedule? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "FeedingSchedules"
        ) else {
            print("Could not find schedule file: \(name).json")
            return nil
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(FeedingSchedule.self, from: data)
    }
}

/// Errors that can occur when loading feeding schedules
public enum FeedingScheduleError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Could not find feeding schedule file: \(name)"
        case .decodingFailed(let name):
            return "Could not decode feeding schedule: \(name)"
        }
    }
}
