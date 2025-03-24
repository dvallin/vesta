import SwiftUI

struct QuickFilterView: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    Button(action: {
                        viewModel.filterMode = .all
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.filterMode == .all {
                            Label(FilterMode.all.displayName, systemImage: "checkmark")
                        } else {
                            Text(FilterMode.all.displayName)
                        }
                    }

                    Divider()

                    ForEach(FilterMode.allCases.filter { $0 != .all && $0 != .overdue }, id: \.self)
                    { mode in
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

                Menu {
                    Button(action: {
                        viewModel.selectedPriority = nil
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedPriority == nil {
                            Label("All Priorities", systemImage: "checkmark")
                        } else {
                            Text("All Priorities")
                        }
                    }

                    Divider()

                    Button(action: {
                        viewModel.selectedPriority = 1
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedPriority == 1 {
                            Label("Highest", systemImage: "checkmark")
                        } else {
                            Text("Highest")
                        }
                    }

                    Button(action: {
                        viewModel.selectedPriority = 2
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedPriority == 2 {
                            Label("High", systemImage: "checkmark")
                        } else {
                            Text("High")
                        }
                    }

                    Button(action: {
                        viewModel.selectedPriority = 3
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedPriority == 3 {
                            Label("Medium", systemImage: "checkmark")
                        } else {
                            Text("Medium")
                        }
                    }

                    Button(action: {
                        viewModel.selectedPriority = 4
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedPriority == 4 {
                            Label("Low", systemImage: "checkmark")
                        } else {
                            Text("Low")
                        }
                    }
                } label: {
                    HStack {
                        Text(priorityDisplayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                Menu {
                    Button(action: {
                        viewModel.selectedCategory = nil
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.selectedCategory == nil {
                            Label("All Categories", systemImage: "checkmark")
                        } else {
                            Text("All Categories")
                        }
                    }

                    Divider()

                    ForEach(viewModel.fetchCategories(), id: \.name) { category in
                        Button(action: {
                            viewModel.selectedCategory = category
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                        }) {
                            if viewModel.selectedCategory == category {
                                Label(category.name, systemImage: "checkmark")
                            } else {
                                Text(category.name)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(categoryDisplayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    private var priorityDisplayName: String {
        switch viewModel.selectedPriority {
        case 1:
            return NSLocalizedString("Highest", comment: "Highest priority filter")
        case 2:
            return NSLocalizedString("High", comment: "High priority filter")
        case 3:
            return NSLocalizedString("Medium", comment: "Medium priority filter")
        case 4:
            return NSLocalizedString("Low", comment: "Low priority filter")
        default:
            return NSLocalizedString("Priority", comment: "Priority filter default text")
        }
    }

    private var categoryDisplayName: String {
        viewModel.selectedCategory?.name
            ?? NSLocalizedString("None", comment: "Category filter default text")
    }
}

#Preview {
    QuickFilterView(viewModel: TodoListViewModel())
}
