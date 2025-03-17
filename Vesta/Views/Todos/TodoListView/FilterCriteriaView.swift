import SwiftUI

struct FilterCriteriaView: View {
    @ObservedObject var viewModel: TodoListViewModel

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text(
                        NSLocalizedString("Filter Mode", comment: "Filter criteria section header"))
                ) {
                    Picker(
                        NSLocalizedString("Filter Mode", comment: "Filter mode picker label"),
                        selection: $viewModel.filterMode
                    ) {
                        ForEach(FilterMode.allCases.filter { $0 != .overdue }, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.filterMode) { _, _ in
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }
                }

                Section {
                    Toggle(
                        NSLocalizedString(
                            "Show Completed Items", comment: "Toggle for showing completed items"),
                        isOn: $viewModel.showCompletedItems
                    )
                    .onChange(of: viewModel.showCompletedItems) { _, _ in
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }
                }
            }
            .navigationTitle(
                NSLocalizedString(
                    "Filter Criteria", comment: "Navigation title for filter criteria view")
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                        presentationMode.wrappedValue.dismiss()
                    })
            #endif
        }
        .presentationDetents([.medium, .large])
    }
}

enum FilterMode: String, CaseIterable {
    case all
    case today
    case noDueDate
    case overdue

    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("Show All", comment: "Filter mode: show all items")
        case .today:
            return NSLocalizedString("Only Today", comment: "Filter mode: show only today's items")
        case .noDueDate:
            return NSLocalizedString(
                "No Due Date", comment: "Filter mode: show items with no due date")
        case .overdue:
            return NSLocalizedString("Overdue", comment: "Filter mode: show overdue items")
        }
    }
}

#Preview {
    FilterCriteriaView(viewModel: TodoListViewModel())
}
