import SwiftData
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var toastMessages: [ToastMessage] = []

    @Published var searchText: String = ""
    @Published var showPurchased: Bool = false

    @Published var selectedShoppingItem: ShoppingListItem? = nil

    @Published var isPresentingAddShoppingItemView = false
    @Published var isPresentingFilterCriteriaView = false

    init(showPurchased: Bool = false) {
        self.showPurchased = showPurchased
    }

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func saveContext() {
        do {
            try modelContext!.save()
        } catch {
            // handle error
        }
    }

    func togglePurchased(
        _ item: ShoppingListItem, undoAction: @escaping (ShoppingListItem, UUID) -> Void
    ) {
        item.isPurchased.toggle()
        saveContext()

        let id = UUID()
        let actionText = item.isPurchased ? "marked as purchased" : "marked as not purchased"
        let toastMessage = ToastMessage(
            id: id,
            message: "\(item.name) \(actionText)",
            undoAction: {
                undoAction(item, id)
            }
        )
        toastMessages.append(toastMessage)
    }

    func togglePurchased(_ item: ShoppingListItem, id: UUID) {
        item.isPurchased.toggle()
        saveContext()

        toastMessages.removeAll { $0.id == id }
    }

    func deleteItem(_ item: ShoppingListItem) {
        modelContext!.delete(item)
        saveContext()
    }

    func filterItems(shoppingItems: [ShoppingListItem]) -> [ShoppingListItem] {
        return shoppingItems.filter { item in
            let matchesSearchText =
                searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)

            let matchesPurchased = showPurchased || !item.isPurchased

            return matchesSearchText && matchesPurchased
        }
        .sorted { first, second in
            // First sort by purchased status (non-purchased first)
            if first.isPurchased != second.isPurchased {
                return !first.isPurchased
            }

            // Then sort by due date if available
            if let firstDate = first.todoItem.dueDate,
                let secondDate = second.todoItem.dueDate
            {
                return firstDate < secondDate
            } else if first.todoItem.dueDate != nil {
                return true
            } else if second.todoItem.dueDate != nil {
                return false
            }

            // Finally sort by name
            return first.name < second.name
        }
    }
}
