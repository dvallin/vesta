import SwiftData
import SwiftUI

class AddShoppingItemViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var categoryService: TodoItemCategoryService?

    @Published var name: String = ""
    @Published var showQuantityField: Bool = false
    @Published var quantity: String = ""
    @Published var selectedUnit: Unit? = nil

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.dismiss = dismiss
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

        let shoppingCategory = categoryService?.fetchOrCreate(
            named: NSLocalizedString("Shopping", comment: "Shopping category name")
        )

        let todoItem = TodoItem(
            title: String(
                format: NSLocalizedString(
                    "Buy %@",
                    comment: "Format for todo item title, where %@ is the item name"
                ),
                name
            ),
            details: NSLocalizedString(
                "Shopping item",
                comment: "Default details text for shopping items"
            ),
            category: shoppingCategory
        )

        let quantityDouble = Double(quantity)

        let newItem = ShoppingListItem(
            name: name,
            quantity: quantityDouble,
            unit: selectedUnit,
            todoItem: todoItem
        )

        modelContext.insert(todoItem)
        modelContext.insert(newItem)

        if saveContext() {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
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
