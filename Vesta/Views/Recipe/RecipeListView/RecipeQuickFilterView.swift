import SwiftUI

struct RecipeQuickFilterView: View {
    @ObservedObject var viewModel: RecipeListViewModel
    let recipes: [Recipe]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Filter Mode Menu
                Menu {
                    ForEach(RecipeFilterMode.allCases, id: \.self) { mode in
                        Button(action: {
                            viewModel.filterMode = mode
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                        }) {
                            if viewModel.filterMode == mode {
                                Label(mode.displayName, systemImage: "checkmark")
                            } else {
                                Text(mode.displayName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.filterMode.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Seasonality Filter
                Menu {
                    Button(action: {
                        viewModel.selectedSeasonality = nil
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedSeasonality == nil {
                            Label("All Seasons", systemImage: "checkmark")
                        } else {
                            Text("All Seasons")
                        }
                    }

                    Divider()

                    ForEach(Seasonality.allCases, id: \.self) { seasonality in
                        Button(action: {
                            viewModel.selectedSeasonality = seasonality
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                        }) {
                            if viewModel.selectedSeasonality == seasonality {
                                Label(seasonality.displayName, systemImage: "checkmark")
                            } else {
                                Text(seasonality.displayName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(seasonalityDisplayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Meal Type Filter
                Menu {
                    Button(action: {
                        viewModel.selectedMealType = nil
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedMealType == nil {
                            Label("All Meals", systemImage: "checkmark")
                        } else {
                            Text("All Meals")
                        }
                    }

                    Divider()

                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Button(action: {
                            viewModel.selectedMealType = mealType
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                        }) {
                            if viewModel.selectedMealType == mealType {
                                Label(mealType.displayName, systemImage: "checkmark")
                            } else {
                                Text(mealType.displayName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(mealTypeDisplayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Tags Filter
                Menu {
                    Button(action: {
                        viewModel.selectedTag = nil
                        viewModel.showUntagged = false
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedTag == nil && !viewModel.showUntagged {
                            Label("All Tags", systemImage: "checkmark")
                        } else {
                            Text("All Tags")
                        }
                    }

                    Button(action: {
                        viewModel.selectedTag = nil
                        viewModel.showUntagged = true
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedTag == nil && viewModel.showUntagged {
                            Label("No Tags", systemImage: "checkmark")
                        } else {
                            Text("No Tags")
                        }
                    }

                    let availableTags = viewModel.fetchAllTags(from: recipes)
                    if !availableTags.isEmpty {
                        Divider()

                        ForEach(availableTags, id: \.self) { tag in
                            Button(action: {
                                viewModel.selectedTag = tag
                                viewModel.showUntagged = false
                                HapticFeedbackManager.shared.generateSelectionFeedback()
                            }) {
                                if viewModel.selectedTag == tag {
                                    Label(tag, systemImage: "checkmark")
                                } else {
                                    Text(tag)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(tagDisplayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Clear Filters Button
                if hasActiveFilters {
                    Button(action: {
                        viewModel.resetFilters()
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        HStack {
                            Text("Clear")
                            Image(systemName: "xmark.circle.fill")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var seasonalityDisplayName: String {
        viewModel.selectedSeasonality?.displayName
            ?? NSLocalizedString("Season", comment: "Seasonality filter default text")
    }

    private var mealTypeDisplayName: String {
        viewModel.selectedMealType?.displayName
            ?? NSLocalizedString("Meal", comment: "Meal type filter default text")
    }

    private var tagDisplayName: String {
        if viewModel.showUntagged {
            return NSLocalizedString("No Tags", comment: "Tag filter: no tags")
        }
        return viewModel.selectedTag
            ?? NSLocalizedString("Tags", comment: "Tag filter default text")
    }

    private var hasActiveFilters: Bool {
        viewModel.filterMode != .all || viewModel.selectedSeasonality != nil
            || viewModel.selectedMealType != nil || viewModel.selectedTag != nil
            || viewModel.showUntagged
    }
}

#Preview {
    let viewModel = RecipeListViewModel()
    let recipes = [
        Fixtures.bolognese(),
        Fixtures.curry(),
    ]
    return RecipeQuickFilterView(viewModel: viewModel, recipes: recipes)
}
