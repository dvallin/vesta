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

            if !matchingCategories.isEmpty && focusedField == "category" {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(matchingCategories, id: \.name) { category in
                        Button(action: {
                            self.category = category.name
                            focusedField = nil
                        }) {
                            Text(category.name)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                        }
                        .background(Color(.systemBackground))
                        .contentShape(Rectangle())

                        if category != matchingCategories.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .transition(.opacity)
            }
        }
    }
}

#Preview("Default") {
    struct DefaultContainer: View {
        @State private var priority = 3
        @State private var category = ""
        @State private var matchingCategories: [TodoItemCategory] = []
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: {}
                )
            }
        }
    }

    return DefaultContainer()
}

#Preview("With Category Suggestions") {
    struct SuggestionsContainer: View {
        @State private var priority = 2
        @State private var category = "Wor"
        @State private var matchingCategories: [TodoItemCategory] = [
            TodoItemCategory(name: "Work"),
            TodoItemCategory(name: "Workshop"),
            TodoItemCategory(name: "Workout")
        ]
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: {}
                )
            }
            .onAppear {
                focusedField = "category"
            }
        }
    }

    return SuggestionsContainer()
}

#Preview("High Priority with Category") {
    struct HighPriorityContainer: View {
        @State private var priority = 1
        @State private var category = "Personal"
        @State private var matchingCategories: [TodoItemCategory] = []
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: {}
                )
            }
        }
    }

    return HighPriorityContainer()
}

#Preview("Low Priority with Long Category") {
    struct LowPriorityContainer: View {
        @State private var priority = 4
        @State private var category = "Home Improvement"
        @State private var matchingCategories: [TodoItemCategory] = []
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: {}
                )
            }
        }
    }

    return LowPriorityContainer()
}
