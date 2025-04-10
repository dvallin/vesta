import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftData
import SwiftUI

@main
struct VestaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer
    let auth: UserAuthService
    let users: UserService
    let spaces: SpaceService
    let meals: MealService
    let todoItemCategories: TodoItemCategoryService
    let todoItems: TodoItemService
    let recipes: RecipeService
    let shoppingItems: ShoppingListItemService
    let syncService: SyncService
    let todoItemEvents: TodoItemEventService

    init() {
        FirebaseApp.configure()

        do {
            self.sharedModelContainer = try ModelContainerHelper.createModelContainer(
                isStoredInMemoryOnly: false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let modelContext = sharedModelContainer.mainContext
        auth = UserAuthService(modelContext: modelContext)
        users = UserService(modelContext: modelContext)
        spaces = SpaceService(modelContext: modelContext)
        todoItemCategories = TodoItemCategoryService(modelContext: modelContext)
        meals = MealService(modelContext: modelContext)
        todoItems = TodoItemService(modelContext: modelContext)
        recipes = RecipeService(modelContext: modelContext)
        shoppingItems = ShoppingListItemService(modelContext: modelContext)
        todoItemEvents = TodoItemEventService(modelContext: modelContext)
        
        syncService = SyncService(auth: auth, users: users, spaces: spaces, todoItemCategories: todoItemCategories,
                                  meals: meals, todoItems: todoItems, recipes: recipes, shoppingItems: shoppingItems,
                                  todoItemEvents: todoItemEvents, modelContext: modelContext)

        MigrationManager.migrateToSyncableEntities(in: modelContext, auth: auth)

        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            VestaMainPage()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(auth)
        .environmentObject(syncService)
    }
}
