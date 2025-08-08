import SwiftData
import SwiftUI

struct MealDetailView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MealDetailViewModel

    init(meal: Meal) {
        _viewModel = StateObject(wrappedValue: MealDetailViewModel(meal: meal))
    }

    var body: some View {
        NavigationView {
            VStack {
                if let recipe = viewModel.meal.recipe {
                    ReadOnlyRecipeDetailView(
                        recipe: recipe, scalingFactor: viewModel.meal.scalingFactor
                    )
                }
                HStack {
                    Text(NSLocalizedString("Scaling Factor:", comment: "Scaling factor label"))
                    TextField(
                        NSLocalizedString("Scaling Factor", comment: "Scaling factor input field"),
                        value: Binding(
                            get: { viewModel.meal.scalingFactor },
                            set: { newValue in
                                guard let currentUser = auth.currentUser else { return }
                                viewModel.meal.setScalingFactor(newValue, currentUser: currentUser)
                            }
                        ),
                        formatter: NumberFormatter()
                    )
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()

                HStack {
                    Text(NSLocalizedString("Meal Type:", comment: "Meal type label"))
                    Picker(
                        NSLocalizedString("Meal Type", comment: "Meal type picker label"),
                        selection: Binding(
                            get: { viewModel.meal.mealType },
                            set: { newValue in
                                viewModel.setMealType(newValue)
                            }
                        )
                    ) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.displayName).tag(mealType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)

                HStack {
                    Text(NSLocalizedString("Due Date:", comment: "Due date label"))
                    if viewModel.meal.todoItem?.dueDate != nil {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.meal.todoItem?.dueDate ?? Date() },
                                set: { newValue in
                                    guard let currentUser = auth.currentUser else { return }
                                    viewModel.meal.setDueDate(newValue, currentUser: currentUser)
                                }
                            ),
                            displayedComponents: .date
                        )
                        Button(NSLocalizedString("Remove", comment: "Remove due date button")) {
                            viewModel.removeDueDate()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button(NSLocalizedString("Set Due Date", comment: "Set due date button")) {
                            guard let currentUser = auth.currentUser else { return }
                            viewModel.meal.setDueDate(Date(), currentUser: currentUser)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle(
                NSLocalizedString("Meal Details", comment: "Meal details screen title")
            )
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            viewModel.cancel()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            viewModel.save()
                        }
                    }
                #endif
            }
            .onAppear {
                viewModel.configureEnvironment(modelContext, dismiss, auth)
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let user = Fixtures.createUser()

        // Create sample recipe with ingredients
        let recipe = Fixtures.bolognese(owner: user)

        // Create todo item
        let todoItem = TodoItem(
            title: "Cook Spaghetti Bolognese",
            details: "Make dinner",
            dueDate: Date().addingTimeInterval(3600),
            owner: user
        )

        // Create meal
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            owner: user
        )

        // Insert objects into context
        context.insert(recipe)
        context.insert(todoItem)
        context.insert(meal)

        return NavigationView {
            MealDetailView(meal: meal)
        }
        .modelContainer(container)

    } catch {
        return Text("Failed to create ModelContainer")
    }
}
