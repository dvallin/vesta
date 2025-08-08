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
    let meals: MealService
    let todoItemCategories: TodoItemCategoryService
    let todoItems: TodoItemService
    let recipes: RecipeService
    let shoppingItems: ShoppingListItemService
    let syncService: SyncService
    let inviteService: UserInviteService
    let entitySharingService: EntitySharingService
    let cleanupService: CleanupService

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
        todoItemCategories = TodoItemCategoryService(modelContext: modelContext)
        meals = MealService(modelContext: modelContext)
        todoItems = TodoItemService(modelContext: modelContext)
        recipes = RecipeService(modelContext: modelContext)
        shoppingItems = ShoppingListItemService(modelContext: modelContext)

        // Create Firebase API client for use with invite service
        let firebaseApi = FirebaseAPIClient()
        inviteService = UserInviteService(modelContext: modelContext, apiClient: firebaseApi)

        // Create entity sharing service
        entitySharingService = EntitySharingService(
            modelContext: modelContext,
            todoItemService: todoItems,
            mealService: meals,
            recipeService: recipes,
            shoppingItemService: shoppingItems
        )

        // Create cleanup service
        cleanupService = CleanupService(modelContext: modelContext)

        syncService = SyncService(
            auth: auth, users: users, todoItemCategories: todoItemCategories,
            meals: meals, todoItems: todoItems, recipes: recipes, shoppingItems: shoppingItems,
            modelContext: modelContext)

        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            VestaMainPage()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(auth)
        .environmentObject(syncService)
        .environmentObject(inviteService)
        .environmentObject(entitySharingService)
        .environmentObject(cleanupService)
    }
}
