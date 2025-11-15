import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct DiaryView: View {
    @StateObject private var viewModel: DiaryViewModel
    @State private var showingEventCreation = false
    @State private var selectedEventType: EventType = .watering

    public init(viewModel: DiaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        FilterButton(
                            type: type,
                            isSelected: viewModel.selectedTypes.contains(type),
                            action: { viewModel.toggleFilter(type) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))

            // Events list
            if viewModel.filteredEvents.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.filteredEvents) { event in
                        EventRowView(event: event)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteEvents(at: indexSet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Diary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button {
                            selectedEventType = type
                            showingEventCreation = true
                        } label: {
                            Label(type.displayName, systemImage: type.iconName)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEventCreation) {
            EventCreationView(
                viewModel: viewModel.makeEventCreationViewModel(type: selectedEventType)
            )
        }
        .onAppear {
            viewModel.loadEvents()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Events")
                .font(.headline)

            Text("Tap + to add your first event")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(iOS 17.0, *)
struct FilterButton: View {
    let type: EventType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(type.displayName, systemImage: type.iconName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

@available(iOS 17.0, *)
struct EventRowView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.iconName)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.headline)

                if event.type == .lightCheck, let measurement = event.lightMeasurement {
                    Text(lightSummary(from: measurement))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let noteText = event.noteText {
                    Text(noteText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let volume = event.volumeLiters {
                    Text("\(String(format: "%.1f", volume))L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !event.stressTags.isEmpty {
                    Text(event.stressTags.map { $0.displayName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Text(event.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func lightSummary(from measurement: LightMeasurementData) -> String {
        let ppfdText: String
        if let ppfd = measurement.ppfd {
            ppfdText = "\(Int(ppfd)) μmol/m²/s"
        } else {
            ppfdText = "PPFD n/a"
        }

        if let lux = measurement.lux {
            return "\(ppfdText) • \(Int(lux)) lx"
        } else {
            return ppfdText
        }
    }
}
