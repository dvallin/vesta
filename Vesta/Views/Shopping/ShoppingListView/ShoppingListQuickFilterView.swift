import SwiftUI

struct ShoppingListQuickFilterView: View {
    @ObservedObject var viewModel: ShoppingListViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    Button(action: {
                        viewModel.showPurchased = false
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if !viewModel.showPurchased {
                            Label("Hide Purchased", systemImage: "checkmark")
                        } else {
                            Text("Hide Purchased")
                        }
                    }

                    Button(action: {
                        viewModel.showPurchased = true
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                    }) {
                        if viewModel.showPurchased {
                            Label("Show Purchased", systemImage: "checkmark")
                        } else {
                            Text("Show Purchased")
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.showPurchased ? "Show Purchased" : "Hide Purchased")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ShoppingListQuickFilterView(viewModel: ShoppingListViewModel())
}
