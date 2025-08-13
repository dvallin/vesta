import SwiftUI

struct PriorityCategorySection: View {
    @Binding var priority: Int
    @Binding var category: String
    @Binding var matchingCategories: [TodoItemCategory]
    @FocusState.Binding var focusedField: String?

    var updateMatchingCategories: (String) -> Void

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

            AutocompleteSelector(
                title: NSLocalizedString("Category", comment: "Category section title"),
                placeholder: NSLocalizedString(
                    "Enter category", comment: "Category text field placeholder"),
                selectedItem: $category,
                suggestions: Array<SelectorEntry>.from(matchingCategories, keyPath: \.name),
                onTextChange: { text in
                    updateMatchingCategories(text)
                },
                onItemSelected: { categoryName in
                    category = categoryName
                    updateMatchingCategories(categoryName)
                }
            )
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
                    updateMatchingCategories: { _ in }
                )
            }
        }
    }

    return DefaultContainer()
}

#Preview("With Category") {
    struct CategoryContainer: View {
        @State private var priority = 2
        @State private var category = "Work"
        @State private var matchingCategories: [TodoItemCategory] = []
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: { _ in }
                )
            }
        }
    }

    return CategoryContainer()
}

#Preview("With Category Suggestions") {
    struct SuggestionsContainer: View {
        @State private var priority = 2
        @State private var category = "Wor"
        @State private var matchingCategories: [TodoItemCategory] = [
            TodoItemCategory(name: "Work"),
            TodoItemCategory(name: "Workshop"),
            TodoItemCategory(name: "Workout"),
        ]
        @FocusState private var focusedField: String?

        var body: some View {
            Form {
                PriorityCategorySection(
                    priority: $priority,
                    category: $category,
                    matchingCategories: $matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: { _ in }
                )
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
                    updateMatchingCategories: { _ in }
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
                    updateMatchingCategories: { _ in }
                )
            }
        }
    }

    return LowPriorityContainer()
}
