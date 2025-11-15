import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct GardenView: View {
    @StateObject private var viewModel: GardenViewModel
    @Environment(ProEntitlementManager.self) private var proManager
    @State private var showingCreatePlant = false
    @State private var showingUpgradePrompt = false
    @State private var showingSettings = false

    public init(viewModel: GardenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.plants.isEmpty {
                    emptyStateView
                } else {
                    plantListView
                }
            }
            .navigationTitle("My Garden")
            .toolbar {
                // Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }

                // Plant count indicator for Free users
                if !proManager.isPro && !viewModel.plants.isEmpty {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text("My Garden")
                                .font(.headline)
                            Text("\(viewModel.plants.count) of \(ProEntitlementManager.freeTierPlantLimit) plants")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        handleAddPlant()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlant) {
                PlantCreationView(viewModel: viewModel.makeCreationViewModel())
            }
            .sheet(isPresented: $showingUpgradePrompt) {
                if #available(iOS 18.0, macOS 15.0, *) {
                    UpgradeToProView()
                } else {
                    UpgradePromptView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .onAppear {
                viewModel.loadPlants()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private func handleAddPlant() {
        // Check if user can create more plants
        let currentCount = viewModel.plants.count
        if proManager.canCreatePlant(currentPlantCount: currentCount) {
            showingCreatePlant = true
        } else {
            // Show upgrade prompt
            showingUpgradePrompt = true
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundColor(.electricGreen)
                .shadow(color: .electricGreen.opacity(0.4), radius: 20)

            Text("No Plants Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)

            Text("Create your first plant to start tracking your grow")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NeonButton("Add First Plant", style: .primary, fullWidth: false) {
                showingCreatePlant = true
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var plantListView: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.plants) { plant in
                        NavigationLink {
                            PlantDetailView(
                                viewModel: viewModel.makeDetailViewModel(for: plant)
                            )
                        } label: {
                            PlantRowView(
                                plant: plant,
                                wateringStatusMessage: viewModel.wateringStatusMessage(for: plant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // Show contextual prompt when user has 3 plants (at limit)
            if viewModel.plants.count >= ProEntitlementManager.freeTierPlantLimit && !proManager.isPro {
                VStack {
                    Spacer()
                    if #available(iOS 18.0, *) {
                        ProFeaturePromptView(promptType: .gardenPlantLimit) {
                            showingUpgradePrompt = true
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .background(
                            LinearGradient(
                                colors: [.clear, Color(red: 1, green: 1, blue: 1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .allowsHitTesting(false),
                            alignment: .bottom
                        )
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
struct PlantRowView: View {
    let plant: Plant
    let wateringStatusMessage: String?

    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 16) {
                // Plant photo with glassmorphic border
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.electricGreen.opacity(0.3), Color.sageGreen.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.electricGreen)
                        }

                    // Health status indicator
                    Circle()
                        .fill(Color.successGreen)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.surfaceDark, lineWidth: 2)
                        )
                        .shadow(color: .successGreen.opacity(0.6), radius: 4)
                        .offset(x: 4, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Text(plant.stage.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    HStack(spacing: 12) {
                        Label {
                            Text("Day \(plant.ageInDays)")
                                .font(.system(size: 12, design: .monospaced))
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .foregroundColor(.tertiaryText)

                        if let wateringMessage = wateringStatusMessage {
                            Label {
                                Text(wateringMessage)
                                    .font(.system(size: 12))
                            } icon: {
                                Image(systemName: "drop.fill")
                            }
                            .foregroundColor(wateringMessage.contains("overdue") ? .criticalRed : .cyanBright)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.tertiaryText)
            }
        }
    }
}
