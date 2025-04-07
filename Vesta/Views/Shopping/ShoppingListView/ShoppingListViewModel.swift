import SwiftData
import SwiftUI

class ShoppingListViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var userManager: UserManager?

    @Published var toastMessages: [ToastMessage] = []

    @Published var searchText: String = ""
    @Published var showPurchased: Bool = false

    @Published var selectedShoppingItem: ShoppingListItem? = nil

    @Published var isPresentingAddShoppingItemView = false
    @Published var isPresentingFilterCriteriaView = false

    init(showPurchased: Bool = false) {
        self.showPurchased = showPurchased
    }

    func configureContext(_ context: ModelContext, _ userManager: UserManager) {
        self.modelContext = context
        self.userManager = userManager
    }

    func saveContext() -> Bool {
        do {
            try modelContext!.save()
            return true
        } catch {
            return false
        }
    }

    func togglePurchased(
        _ item: ShoppingListItem, undoAction: @escaping (ShoppingListItem, UUID) -> Void
    ) {
        guard let currentUser = userManager?.currentUser else { return }
        item.todoItem?.markAsDone(currentUser: currentUser)

        if saveContext() {
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ marked as %@",
                        comment: "Toast message for marking item as purchased/not purchased"
                    ),
                    item.name,
                    item.isPurchased
                        ? NSLocalizedString("purchased", comment: "Purchased status")
                        : NSLocalizedString("not purchased", comment: "Not purchased status")
                ),
                undoAction: {
                    undoAction(item, id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func undoTogglePurchased(_ item: ShoppingListItem, id: UUID) {
        if let lastEvent = item.todoItem?.undoLastEvent() {
            modelContext!.delete(lastEvent)
        }
        if saveContext() {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            toastMessages.removeAll { $0.id == id }
        }
    }

    func deleteItem(_ item: ShoppingListItem) {
        modelContext!.delete(item)
        if saveContext() {
            HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)
        }
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
            if let firstDate = first.todoItem?.dueDate,
                let secondDate = second.todoItem?.dueDate
            {
                return firstDate < secondDate
            } else if first.todoItem?.dueDate != nil {
                return true
            } else if second.todoItem?.dueDate != nil {
                return false
            }

            // Finally sort by name
            return first.name < second.name
        }
    }
}
