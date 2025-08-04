import SwiftUI

enum MealPlanFilterMode: String, CaseIterable {
    case all = "all"
    case currentWeek = "current_week"
    case lastWeek = "last_week"
    case nextWeek = "next_week"

    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("All Meals", comment: "Filter for active meals only")
        case .currentWeek:
            return NSLocalizedString("This Week", comment: "Filter for current week meals")
        case .lastWeek:
            return NSLocalizedString("Last Week", comment: "Filter for last week meals")
        case .nextWeek:
            return NSLocalizedString("Next Week", comment: "Filter for next week meals")
        }
    }
}

struct MealPlanQuickFilterView: View {
    @ObservedObject var viewModel: MealPlanViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(MealPlanFilterMode.allCases, id: \.self) { mode in
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
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    MealPlanQuickFilterView(viewModel: MealPlanViewModel())
}
