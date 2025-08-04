import SwiftData
import SwiftUI

struct ShoppingListViewInner: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    var shoppingItems: [ShoppingListItem]

    var body: some View {
        VStack {
            ShoppingListQuickFilterView(viewModel: viewModel)
                .padding(.vertical, 8)

            ZStack {
                ShoppingList(
                    viewModel: viewModel,
                    shoppingItems: shoppingItems
                )

                FloatingAddButton {
                    viewModel.isPresentingAddShoppingItemView = true
                }
            }
        }
        .navigationTitle(
            NSLocalizedString("Shopping List", comment: "Shopping list view title")
        )
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
