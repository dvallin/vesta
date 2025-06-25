import SwiftData
import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItemCategory.name) var categories: [TodoItemCategory]

    @StateObject private var viewModel = CategoryManagementViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline)
                        }

                        Spacer()

                        Toggle(
                            isOn: Binding(
                                get: { category.isFreezable },
                                set: { newValue in
                                    viewModel.toggleFreezable(
                                        category: category, isFreezable: newValue)
                                }
                            )
                        ) {
                            Text("Freezable")
                                .font(.subheadline)
                        }
                        .frame(width: 120)

                        Button(action: {
                            viewModel.categoryToEdit = category
                            viewModel.newCategoryName = category.name
                            viewModel.showingEditAlert = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 6)
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Edit Category",
                isPresented: $viewModel.showingEditAlert
            ) {
                TextField(
                    "Category name",
                    text: $viewModel.newCategoryName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if !viewModel.newCategoryName.isEmpty,
                        let category = viewModel.categoryToEdit
                    {
                        viewModel.editCategory(category, newName: viewModel.newCategoryName)
                    }
                }
            }
            .alert(
                "Delete Category",
                isPresented: $viewModel.showingDeleteAlert
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Handle deletion from the current selection
                    if let category = viewModel.categoryToDelete {
                        viewModel.deleteCategory(category)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this category?")
            }
            .alert(
                "Cannot Delete Category",
                isPresented: $viewModel.showingCannotDeleteAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This category contains todo items and cannot be deleted.")
            }
        }
        .onAppear {
            viewModel.configureContext(modelContext)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { categories[$0] }

        // Check if any category has todo items (can't be deleted)
        for category in categoriesToDelete {
            if !viewModel.canDeleteCategory(category) {
                viewModel.showCannotDeleteAlert(category: category)
                return
            }
        }

        // If we can delete multiple categories at once, do it
        if categoriesToDelete.count > 1 {
            viewModel.deleteCategories(categories: categories, at: offsets)
        } else if let category = categoriesToDelete.first {
            // For a single category, show confirmation dialog
            viewModel.categoryToDelete = category
            viewModel.showingDeleteAlert = true
        }
    }
}

struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TodoItemCategory.self, configurations: config)

        // Add some sample categories
        let categories: [(String, Bool)] = [
            ("Work", false),
            ("Personal", false),
            ("Shopping", true),
            ("Groceries", true),
        ]
        for (categoryName, isFreezable) in categories {
            let category = TodoItemCategory(
                name: categoryName, isFreezable: isFreezable)
            container.mainContext.insert(category)
        }

        return CategoryManagementView()
            .modelContainer(container)
    }
}
