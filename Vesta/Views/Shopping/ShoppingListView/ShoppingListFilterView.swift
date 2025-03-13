import SwiftUI

struct ShoppingListFilterView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(
                        NSLocalizedString(
                            "Show Purchased Items",
                            comment: "Filter option for showing purchased items"),
                        isOn: $viewModel.showPurchased
                    )
                }
            }
            .navigationTitle(
                NSLocalizedString(
                    "Filter Shopping List", comment: "Navigation title for shopping list filter")
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button(
                        NSLocalizedString("Done", comment: "Button to dismiss filter view")
                    ) {
                        presentationMode.wrappedValue.dismiss()
                    })
            #endif
        }
    }
}

#Preview {
    ShoppingListFilterView(viewModel: ShoppingListViewModel())
}
