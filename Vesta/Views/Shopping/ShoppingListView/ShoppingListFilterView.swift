import SwiftUI

struct ShoppingListFilterView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Show Purchased Items", isOn: $viewModel.showPurchased)
                }
            }
            .navigationTitle("Filter Shopping List")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    })
            #endif
        }
    }
}

#Preview {
    ShoppingListFilterView(viewModel: ShoppingListViewModel())
}
