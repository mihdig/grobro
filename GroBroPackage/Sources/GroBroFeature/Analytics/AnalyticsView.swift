import SwiftUI
import Charts
import GroBroDomain

/// Advanced analytics dashboard for Pro users showing plant growth visualizations
@available(iOS 18.0, macOS 15.0, *)
public struct AnalyticsView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @State private var viewModel: AnalyticsViewModel

    private let plant: Plant

    public init(plant: Plant, analyticsService: AnalyticsDataService) {
        self.plant = plant
        self._viewModel = State(initialValue: AnalyticsViewModel(
            plant: plant,
            analyticsService: analyticsService
        ))
    }

    public var body: some View {
        ZStack {
            if proManager.isPro {
                // Pro user: Show analytics
                analyticsContent
            } else {
                // Free user: Show locked state
                lockedStateView
            }
        }
        .navigationTitle("Analytics")
        .task {
            await viewModel.loadAnalyticsData()
        }
    }

    // MARK: - Analytics Content

    @ViewBuilder
    private var analyticsContent: some View {
        if viewModel.isLoading {
            ProgressView("Loading analytics...")
        } else if viewModel.hasInsufficientData {
            emptyStateView
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    // Date range picker
                    dateRangePicker

                    // Growth Timeline
                    if let growthData = viewModel.growthData {
                        GrowthTimelineChart(data: growthData)
                    }

                    // Photo Timeline
                    if !viewModel.photoTimeline.isEmpty {
                        PhotoTimelineGallery(photos: viewModel.photoTimeline)
                    }

                    // Watering Frequency
                    if !viewModel.wateringData.isEmpty {
                        WateringFrequencyChart(dataPoints: viewModel.wateringData)
                    }

                    // Event Distribution
                    if !viewModel.eventDistribution.isEmpty {
                        EventDistributionChart(data: viewModel.eventDistribution)
                    }

                    // Stage Duration
                    if !viewModel.stageDuration.isEmpty {
                        StageDurationChart(data: viewModel.stageDuration)
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        HStack {
            Text("Time Range:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Range", selection: $viewModel.selectedDateRange) {
                Text("30 Days").tag(DateRangeOption.last30Days)
                Text("90 Days").tag(DateRangeOption.last90Days)
                Text("All Time").tag(DateRangeOption.allTime)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Analytics Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)

            if plant.ageInDays < 7 {
                Text("Analytics will appear as your plant matures. Check back after 7 days!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Start logging events to see trends and patterns")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Error Loading Analytics")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadAnalyticsData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Locked State (Free Users)

    private var lockedStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Advanced Analytics")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Unlock detailed insights with Pro")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureBullet(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Growth Timeline",
                    description: "Track your plant's journey with stage markers"
                )

                FeatureBullet(
                    icon: "drop.fill",
                    title: "Watering Insights",
                    description: "Visualize watering patterns over time"
                )

                FeatureBullet(
                    icon: "chart.pie.fill",
                    title: "Event Analysis",
                    description: "See distribution of all care activities"
                )

                FeatureBullet(
                    icon: "timer",
                    title: "Stage Duration",
                    description: "Compare time spent in each growth phase"
                )
            }
            .padding(.horizontal)

            Button {
                // Show upgrade sheet
                viewModel.showUpgradeSheet = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro")
                }
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .sheet(isPresented: $viewModel.showUpgradeSheet) {
            UpgradeToProView()
        }
    }
}

// MARK: - Feature Bullet

struct FeatureBullet: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class AnalyticsViewModel {

    private let plant: Plant
    private let analyticsService: AnalyticsDataService

    var isLoading = false
    var hasInsufficientData = false
    var errorMessage: String?
    var showUpgradeSheet = false

    var growthData: GrowthTimelineData?
    var wateringData: [WateringDataPoint] = []
    var eventDistribution: [EventDistributionData] = []
    var stageDuration: [StageDurationData] = []
    var photoTimeline: [PhotoTimelineItem] = []

    var selectedDateRange: DateRangeOption = .last90Days {
        didSet {
            Task {
                await refreshData()
            }
        }
    }

    init(plant: Plant, analyticsService: AnalyticsDataService) {
        self.plant = plant
        self.analyticsService = analyticsService
    }

    func loadAnalyticsData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Check if plant has sufficient data
            let hasData = try await analyticsService.hasAnalyticsData(for: plant.id)
            guard hasData else {
                hasInsufficientData = true
                isLoading = false
                return
            }

            // Load all analytics data
            async let growth = analyticsService.getGrowthTimelineData(for: plant.id)
            async let watering = analyticsService.getWateringFrequency(
                for: plant.id,
                dateRange: selectedDateRange.toDateRange(startDate: plant.startDate)
            )
            async let distribution = analyticsService.getEventDistribution(for: plant.id)
            async let duration = analyticsService.getStageDuration(for: plant.id)
            async let photos = analyticsService.getPhotoTimeline(for: plant.id)

            (growthData, wateringData, eventDistribution, stageDuration, photoTimeline) = try await (
                growth,
                watering,
                distribution,
                duration,
                photos
            )

            hasInsufficientData = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshData() async {
        analyticsService.invalidateCache(for: plant.id)
        await loadAnalyticsData()
    }
}

// MARK: - Date Range Option

enum DateRangeOption {
    case last30Days
    case last90Days
    case allTime

    func toDateRange(startDate: Date) -> DateRange? {
        switch self {
        case .last30Days:
            return .last30Days
        case .last90Days:
            return .last90Days
        case .allTime:
            return nil // No filter
        }
    }
}

// MARK: - Preview

#if DEBUG
import GroBroPersistence
#endif

#Preview {
    if #available(iOS 18.0, *) {
        NavigationStack {
            AnalyticsView(
                plant: Plant(
                    name: "Test Plant",
                    startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                    stage: .vegetative
                ),
                analyticsService: AnalyticsDataService(
                    plantStore: PlantStore(persistenceController: PersistenceController.preview),
                    eventStore: EventStore(persistenceController: PersistenceController.preview)
                )
            )
        }
        .environment(ProEntitlementManager())
    } else {
        Text("AnalyticsView requires iOS 18.0 or later")
    }
}
