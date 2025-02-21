import SwiftData
import SwiftUI

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var meal: Meal

    var body: some View {
        VStack {
            RecipeDetailView(recipe: meal.recipe)
            HStack {
                Text("Scaling Factor:")
                TextField(
                    "Scaling Factor", value: $meal.scalingFactor, formatter: NumberFormatter()
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    do {
                        try modelContext.save()
                    } catch {
                        // show validation issue
                    }
                }
            }
        }
    }
}
