import SwiftData
import SwiftUI

struct AddMealView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]

    @StateObject var viewModel: AddMealViewModel

    init(selectedDate: Date) {
        _viewModel = StateObject(wrappedValue: AddMealViewModel(selectedDate: selectedDate))
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker(
                    NSLocalizedString("Date", comment: "Date picker label"),
                    selection: $viewModel.selectedDate, displayedComponents: .date)
                Picker(
                    NSLocalizedString("Recipe", comment: "Recipe picker label"),
                    selection: $viewModel.selectedRecipe
                ) {
                    ForEach(recipes) { recipe in
                        Text(recipe.title).tag(recipe as Recipe?)
                    }
                }
                TextField(
                    NSLocalizedString("Scaling Factor", comment: "Scaling factor input field"),
                    value: $viewModel.scalingFactor, formatter: NumberFormatter()
                )
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif

                Picker(
                    NSLocalizedString("Meal Type", comment: "Meal type picker label"),
                    selection: $viewModel.selectedMealType
                ) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Text(mealType.displayName).tag(mealType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle(NSLocalizedString("Add Meal", comment: "Add meal screen title"))
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            Task {
                                viewModel.cancel()
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            Task {
                                viewModel.save()
                            }
                        }
                    }
                #endif
            }
            .alert(
                NSLocalizedString("Validation Error", comment: "Validation error alert title"),
                isPresented: $viewModel.showingValidationAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Validation error accept button"),
                    role: .cancel
                ) {}
            } message: {
                Text(viewModel.validationMessage)
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss, auth)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let user = Fixtures.createUser()
        let bolognese = Fixtures.bolognese(owner: user)
        let curry = Fixtures.curry(owner: user)

        for recipe in [bolognese, curry] {
            context.insert(recipe)
        }

        return AddMealView(selectedDate: Date())
            .modelContainer(container)

    } catch {
        return Text("Failed to create ModelContainer")
    }
}
