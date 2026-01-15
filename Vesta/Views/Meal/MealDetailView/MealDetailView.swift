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
        NavigationStack {
            VStack {
                if let recipe = viewModel.meal.recipe {
                    ReadOnlyRecipeDetailView(
                        recipe: recipe, scalingFactor: viewModel.meal.scalingFactor
                    )
                }
                HStack {
                    Text(
                        String(localized: "meal.detail-view.scaling-factor.label")
                    )
                    TextField(
                        String(localized: "meal.detail-view.scaling-factor.field"),
                        value: Binding(
                            get: { viewModel.meal.scalingFactor },
                            set: { newValue in viewModel.setScalingFactor(newValue) }
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
                    Text(
                        NSLocalizedString(
                            "meal.detail-view.meal-type.label", comment: "Meal type label"))
                    Picker(
                        NSLocalizedString(
                            "meal.detail-view.meal-type.field", comment: "Meal type picker label"),
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
                    Text(
                        String(localized: "meal.detail-view.due-date.label")
                    )
                    if viewModel.meal.todoItem?.dueDate != nil {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.meal.todoItem?.dueDate ?? Date() },
                                set: { newValue in viewModel.setDueDate(newValue) }
                            ),
                            displayedComponents: .date
                        )
                        Button(
                            String(localized: "meal.detail-view.due-date.remove")
                        ) {
                            viewModel.removeDueDate()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button(
                            String(localized: "meal.detail-view.due-date.set")
                        ) {
                            viewModel.setDueDate(Date())
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle(
                String(localized: "meal.detail-view.title")
            )
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(String(localized: "ui.toolbar.cancel")) {
                            viewModel.cancel()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String(localized: "ui.toolbar.save")) {
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
