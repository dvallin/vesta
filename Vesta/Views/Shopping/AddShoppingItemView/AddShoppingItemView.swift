import SwiftData
import SwiftUI

struct AddShoppingItemView: View {
    @EnvironmentObject private var userService: UserManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = AddShoppingItemViewModel()
    @FocusState private var focusedField: FocusableField?

    enum FocusableField: Hashable {
        case name
        case quantity
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(
                        NSLocalizedString("Name", comment: "Item name field placeholder"),
                        text: $viewModel.name
                    )
                    .focused($focusedField, equals: .name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit {
                        if !viewModel.name.isEmpty {
                            viewModel.addItem()
                        }
                    }

                    if viewModel.showQuantityField {
                        HStack {
                            TextField(
                                NSLocalizedString(
                                    "Quantity", comment: "Quantity field placeholder"),
                                text: $viewModel.quantity
                            )
                            .focused($focusedField, equals: .quantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                            .frame(width: 100)

                            Picker("", selection: $viewModel.selectedUnit) {
                                ForEach(Unit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit as Unit?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                if !viewModel.showQuantityField {
                    Button("Add Quantity") {
                        viewModel.toggleQuantityField()
                        focusedField = .quantity
                    }
                }
            }
            .navigationTitle(
                NSLocalizedString(
                    "Add Shopping Item",
                    comment: "Title for the add shopping item screen"
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        NSLocalizedString(
                            "Cancel", comment: "Button to cancel adding a shopping item")
                    ) {
                        viewModel.cancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        NSLocalizedString(
                            "Add Item", comment: "Button to confirm adding a shopping item")
                    ) {
                        viewModel.addItem()
                    }
                    .disabled(viewModel.isAddButtonDisabled)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            focusedField = .name
            viewModel.configureEnvironment(modelContext, dismiss, userService)
        }
    }
}

#Preview {
    AddShoppingItemView()
}
