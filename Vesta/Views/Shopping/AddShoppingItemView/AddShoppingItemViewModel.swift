import SwiftData
import SwiftUI

class AddShoppingItemViewModel: ObservableObject {
    private var auth: UserAuthService?
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var categoryService: TodoItemCategoryService?
    private var syncService: SyncService?

    @Published var name: String = ""
    @Published var showQuantityField: Bool = false
    @Published var quantity: String = ""
    @Published var selectedUnit: Unit? = nil

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService,
        _ syncService: SyncService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.dismiss = dismiss
        self.auth = auth
        self.syncService = syncService
    }

    var isAddButtonDisabled: Bool {
        name.isEmpty
    }

    func toggleQuantityField() {
        showQuantityField = true
        selectedUnit = .piece
    }

    @MainActor
    func addItem() {
        guard let modelContext = modelContext else { return }
        guard let currentUser = auth?.currentUser else { return }

        let shoppingCategory = categoryService?.fetchOrCreate(
            named: NSLocalizedString("Shopping", comment: "Shopping category name")
        )
        let todoTitle = String(
            format: NSLocalizedString("Buy %@", comment: "Shopping list item details"),
            name
        )
        let todoDetails = NSLocalizedString(
            "Shopping item", comment: "Default details text for shopping items"
        )
        let todoItem = TodoItem.create(
            title: todoTitle,
            details: todoDetails,
            category: shoppingCategory,
            owner: currentUser
        )

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let quantityDouble = numberFormatter.number(from: quantity)?.doubleValue

        let newItem = ShoppingListItem(
            name: name,
            quantity: quantityDouble,
            unit: selectedUnit,
            todoItem: todoItem,
            owner: currentUser
        )

        modelContext.insert(todoItem)
        modelContext.insert(newItem)

        if saveContext() {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            _ = syncService?.pushLocalChanges()
        }

        dismiss?()
    }

    private func saveContext() -> Bool {
        guard let modelContext = modelContext else { return false }
        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func cancel() {
        dismiss?()
    }
}
