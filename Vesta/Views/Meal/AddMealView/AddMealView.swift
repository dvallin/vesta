import SwiftData
import SwiftUI

struct AddMealView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var recipes: [Recipe]

    @StateObject private var viewModel = AddMealViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(recipes) { recipe in
                    Button(action: {
                        selectRecipe(recipe)
                    }) {
                        RecipeRow(recipe: recipe)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(NSLocalizedString("Add Meal", comment: "Add meal screen title"))
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .alert(
                NSLocalizedString("Error", comment: "Error alert title"),
                isPresented: $viewModel.showingErrorAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Error alert OK button"),
                    role: .cancel
                ) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss, auth)
        }
    }

    private func selectRecipe(_ recipe: Recipe) {
        Task {
            await viewModel.createMeal(with: recipe)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let user = Fixtures.createUser()
        let recipes = [
            Fixtures.bolognese(owner: user),
            Fixtures.curry(owner: user),
            Recipe(title: "Apple Pie", details: "Classic dessert", owner: user),
        ]

        for recipe in recipes {
            context.insert(recipe)
        }

        let authService = UserAuthService(modelContext: context)
        return AddMealView()
            .modelContainer(container)
            .environmentObject(authService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
