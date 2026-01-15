import SwiftUI

struct QuickFilterView: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryMenu
                filterModeMenu
                priorityMenu
                if viewModel.hasActiveFilters {
                    Button(action: {
                        viewModel.reset()
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
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        Menu {
            Button(action: viewModel.setShowAllCategories) {
                menuItem(
                    title: "todos.quick-filter-view.categories.all",
                    isSelected: viewModel.selectedCategory == nil && !viewModel.showNoCategory
                )
            }

            Button(action: { viewModel.setShowNoCategory(true) }) {
                menuItem(
                    title: "todos.quick-filter-view.categories.none",
                    isSelected: viewModel.selectedCategory == nil && viewModel.showNoCategory
                )
            }

            Divider()

            ForEach(viewModel.fetchCategories(), id: \.name) { category in
                Button(action: { viewModel.setCategory(category) }) {
                    menuItem(
                        title: category.name,
                        isSelected: viewModel.selectedCategory == category,
                        shouldLocalize: false
                    )
                }
            }
        } label: {
            filterLabel(text: categoryDisplayName)
        }
    }

    // MARK: - Filter Mode Menu

    private var filterModeMenu: some View {
        Menu {
            Button(action: { viewModel.setFilterMode(.all) }) {
                menuItem(
                    title: FilterMode.all.displayName,
                    isSelected: viewModel.filterMode == .all,
                    shouldLocalize: false
                )
            }

            Divider()

            ForEach(FilterMode.allCases.filter { $0 != .all && $0 != .overdue }, id: \.self) {
                mode in
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

    // MARK: - Priority Menu

    private var priorityMenu: some View {
        Menu {
            Button(action: { viewModel.setPriority(nil) }) {
                menuItem(
                    title: "todos.quick-filter-view.priority.all",
                    isSelected: viewModel.selectedPriority == nil
                )
            }

            Divider()

            ForEach(priorityOptions, id: \.value) { option in
                Button(action: { viewModel.setPriority(option.value) }) {
                    menuItem(
                        title: option.title,
                        isSelected: viewModel.selectedPriority == option.value
                    )
                }
            }
        } label: {
            filterLabel(text: priorityDisplayName)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func menuItem(title: String, isSelected: Bool, shouldLocalize: Bool = true) -> some View
    {
        let displayTitle =
            shouldLocalize
            ? String(localized: LocalizedStringResource(stringLiteral: title)) : title

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

    // MARK: - Data and Display Names

    private let priorityOptions = [
        (value: 1, title: "todos.quick-filter-view.priority.highest"),
        (value: 2, title: "todos.quick-filter-view.priority.high"),
        (value: 3, title: "todos.quick-filter-view.priority.medium"),
        (value: 4, title: "todos.quick-filter-view.priority.low"),
    ]

    private var priorityDisplayName: String {
        switch viewModel.selectedPriority {
        case 1:
            return String(localized: "todos.quick-filter-view.priority.highest")
        case 2:
            return String(localized: "todos.quick-filter-view.priority.high")
        case 3:
            return String(localized: "todos.quick-filter-view.priority.medium")
        case 4:
            return String(localized: "todos.quick-filter-view.priority.low")
        default:
            return String(localized: "todos.quick-filter-view.priority.default")
        }
    }

    private var categoryDisplayName: String {
        if viewModel.showNoCategory {
            return String(localized: "todos.quick-filter-view.categories.none")
        }
        return viewModel.selectedCategory?.name
            ?? String(localized: "todos.quick-filter-view.categories.all")
    }
}

#Preview {
    QuickFilterView(viewModel: TodoListViewModel())
}
