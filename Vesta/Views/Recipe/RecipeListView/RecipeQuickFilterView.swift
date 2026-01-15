import SwiftUI

struct RecipeQuickFilterView: View {
    @ObservedObject var viewModel: RecipeListViewModel
    let recipes: [Recipe]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                tagMenu
                filterModeMenu
                seasonalityMenu
                mealTypeMenu
                if viewModel.hasActiveFilters {
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

    // MARK: - Tag Menu

    private var tagMenu: some View {
        Menu {
            Button(action: viewModel.setShowAllTags) {
                menuItem(
                    title: NSLocalizedString("All Tags", comment: "Tag filter: all tags"),
                    isSelected: viewModel.selectedTag == nil && !viewModel.showUntagged,
                    shouldLocalize: false
                )
            }

            Button(action: { viewModel.setShowUntagged(true) }) {
                menuItem(
                    title: NSLocalizedString("No Tags", comment: "Tag filter: no tags"),
                    isSelected: viewModel.selectedTag == nil && viewModel.showUntagged,
                    shouldLocalize: false
                )
            }

            let availableTags = viewModel.fetchAllTags(from: recipes)
            if !availableTags.isEmpty {
                Divider()

                ForEach(availableTags, id: \.self) { tag in
                    Button(action: { viewModel.setTag(tag) }) {
                        menuItem(
                            title: tag,
                            isSelected: viewModel.selectedTag == tag,
                            shouldLocalize: false
                        )
                    }
                }
            }
        } label: {
            filterLabel(text: tagDisplayName)
        }
    }

    // MARK: - Filter Mode Menu

    private var filterModeMenu: some View {
        Menu {
            Button(action: { viewModel.setFilterMode(.all) }) {
                menuItem(
                    title: RecipeFilterMode.all.displayName,
                    isSelected: viewModel.filterMode == .all,
                    shouldLocalize: false
                )
            }

            Divider()

            ForEach(RecipeFilterMode.allCases.filter { $0 != .all }, id: \.self) { mode in
                Button(action: { viewModel.setFilterMode(mode) }) {
                    menuItem(
                        title: mode.displayName,
                        isSelected: viewModel.filterMode == mode,
                        shouldLocalize: false
                    )
                }
            }
        } label: {
            filterLabel(text: viewModel.filterMode.displayName)
        }
    }

    // MARK: - Seasonality Menu

    private var seasonalityMenu: some View {
        Menu {
            Button(action: { viewModel.setSeasonality(nil) }) {
                menuItem(
                    title: NSLocalizedString(
                        "All Seasons", comment: "Seasonality filter: all seasons"),
                    isSelected: viewModel.selectedSeasonality == nil,
                    shouldLocalize: false
                )
            }

            Divider()

            ForEach(Seasonality.allCases, id: \.self) { seasonality in
                Button(action: { viewModel.setSeasonality(seasonality) }) {
                    menuItem(
                        title: seasonality.displayName,
                        isSelected: viewModel.selectedSeasonality == seasonality,
                        shouldLocalize: false
                    )
                }
            }
        } label: {
            filterLabel(text: seasonalityDisplayName)
        }
    }

    // MARK: - Meal Type Menu

    private var mealTypeMenu: some View {
        Menu {
            Button(action: { viewModel.setMealType(nil) }) {
                menuItem(
                    title: NSLocalizedString("All Meals", comment: "Meal type filter: all meals"),
                    isSelected: viewModel.selectedMealType == nil,
                    shouldLocalize: false
                )
            }

            Divider()

            ForEach(MealType.allCases, id: \.self) { mealType in
                Button(action: { viewModel.setMealType(mealType) }) {
                    menuItem(
                        title: mealType.displayName,
                        isSelected: viewModel.selectedMealType == mealType,
                        shouldLocalize: false
                    )
                }
            }
        } label: {
            filterLabel(text: mealTypeDisplayName)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func menuItem(title: String, isSelected: Bool, shouldLocalize: Bool = true) -> some View
    {
        let displayTitle =
            shouldLocalize
            ? String(localized: LocalizedStringResource(stringLiteral: title))
            : title

        if isSelected {
            Label(displayTitle, systemImage: "checkmark")
        } else {
            Text(displayTitle)
        }
    }

    private func filterLabel(text: String) -> some View {
        HStack {
            Text(text)
            Image(systemName: "chevron.down")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Display Names

    private var tagDisplayName: String {
        if viewModel.showUntagged {
            return NSLocalizedString("No Tags", comment: "Tag filter: no tags")
        }
        return viewModel.selectedTag
            ?? NSLocalizedString("Tags", comment: "Tag filter default text")
    }

    private var seasonalityDisplayName: String {
        viewModel.selectedSeasonality?.displayName
            ?? NSLocalizedString("Season", comment: "Seasonality filter default text")
    }

    private var mealTypeDisplayName: String {
        viewModel.selectedMealType?.displayName
            ?? NSLocalizedString("Meal", comment: "Meal type filter default text")
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
