import SwiftData
import SwiftUI

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]

    @State private var selectedRecipe: Recipe?
    @State private var selectedDate: Date
    @State private var scalingFactor: Double = 1.0

    init(selectedDate: Date) {
        _selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                Picker("Recipe", selection: $selectedRecipe) {
                    ForEach(recipes) { recipe in
                        Text(recipe.title).tag(recipe as Recipe?)
                    }
                }
                TextField("Scaling Factor", value: $scalingFactor, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        do {
                            if let recipe = selectedRecipe {
                                let todoItem = TodoItem(
                                    title: recipe.title, details: recipe.details,
                                    dueDate: selectedDate)
                                let meal = Meal(
                                    scalingFactor: scalingFactor, todoItem: todoItem, recipe: recipe
                                )
                                modelContext.insert(todoItem)
                                modelContext.insert(meal)
                                try modelContext.save()
                                dismiss()
                            }
                        } catch {
                            // show validation issue
                        }
                    }
                }
            }
        }
    }
}
