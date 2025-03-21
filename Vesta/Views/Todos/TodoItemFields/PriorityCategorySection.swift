import SwiftUI

struct PriorityCategorySection: View {
    @Binding var priority: Int
    @Binding var category: String
    @Binding var matchingCategories: [TodoItemCategory]
    @FocusState.Binding  var focusedField: String?

    var updateMatchingCategories: () -> Void

    var body: some View {
        Section(
            header: Text(
                NSLocalizedString(
                    "Priority & Category", comment: "Section header for priority and category")
            )
        ) {
            Picker(
                NSLocalizedString("Priority", comment: "Priority picker label"),
                selection: $priority
            ) {
                Text(NSLocalizedString("Highest", comment: "Highest priority"))
                    .tag(1)
                Text(NSLocalizedString("High", comment: "High priority"))
                    .tag(2)
                Text(NSLocalizedString("Medium", comment: "Medium priority"))
                    .tag(3)
                Text(NSLocalizedString("Low", comment: "Low priority"))
                    .tag(4)
            }

            TextField(
                NSLocalizedString("Enter category", comment: "Category text field placeholder"),
                text: $category
            )
            .onChange(of: category) { _, _ in
                updateMatchingCategories()
            }
            .focused($focusedField, equals: "category")

            if !matchingCategories.isEmpty {
                List(matchingCategories, id: \.name) { category in
                    Text(category.name)
                        .onTapGesture {
                            self.category = category.name
                            focusedField = nil
                        }
                }
            }
        }
    }
}

