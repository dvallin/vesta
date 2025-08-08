import SwiftUI
import os

struct TrashBinView: View {
    @EnvironmentObject var cleanupService: CleanupService
    @EnvironmentObject var auth: UserAuthService
    @State private var isLoading = false
    @State private var softDeletedItems: [SoftDeletedItem] = []
    @State private var lastCleanupResult: Int?
    @State private var showingCleanupAlert = false
    @State private var customThresholdDays = 90
    @State private var showingCustomThresholdSheet = false
    @State private var selectedItems: Set<String> = []
    @State private var showingBulkActions = false
    @State private var bulkOperationResult: (Int, String)?
    @State private var showingBulkResultAlert = false

    private let logger = Logger(subsystem: "com.app.Vesta", category: "TrashBinView")

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading trash bin...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    trashBinSection
                    informationSection
                }

                if let lastResult = lastCleanupResult {
                    Section("Last Cleanup Result") {
                        HStack {
                            Image(
                                systemName: lastResult > 0
                                    ? "checkmark.circle.fill" : "info.circle.fill"
                            )
                            .foregroundColor(lastResult > 0 ? .green : .blue)
                            Text("Deleted \(lastResult) items")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Trash Bin")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !softDeletedItems.isEmpty && !selectedItems.isEmpty {
                        Button("Actions") {
                            showingBulkActions = true
                        }
                    }
                }
            }
            .refreshable {
                await refreshTrashBin()
            }
            .onAppear {
                Task {
                    await refreshTrashBin()
                }
            }
            .alert("Cleanup Completed", isPresented: $showingCleanupAlert) {
                Button("OK") {}
            } message: {
                if let result = lastCleanupResult {
                    Text("Successfully cleaned up \(result) items.")
                }
            }
            .sheet(isPresented: $showingCustomThresholdSheet) {
                CustomCleanupSheet(
                    thresholdDays: $customThresholdDays,
                    isLoading: $isLoading,
                    onPerformCleanup: performCustomCleanup
                )
            }
            .actionSheet(isPresented: $showingBulkActions) {
                ActionSheet(
                    title: Text("Bulk Actions"),
                    message: Text("Selected \(selectedItems.count) items"),
                    buttons: [
                        .destructive(Text("Delete Selected")) {
                            performBulkDelete()
                        },
                        .default(Text("Restore Selected")) {
                            performBulkRestore()
                        },
                        .cancel(),
                    ]
                )
            }
            .alert("Bulk Operation Completed", isPresented: $showingBulkResultAlert) {
                Button("OK") {}
            } message: {
                if let (count, operation) = bulkOperationResult {
                    Text("Successfully \(operation) \(count) items.")
                }
            }
        }
    }

    private var trashBinSection: some View {
        Section {
            if softDeletedItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        Text("Trash bin is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Deleted items will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(groupedItems.keys.sorted(), id: \.self) { entityType in
                    if let items = groupedItems[entityType] {
                        trashGroupSection(entityType: entityType, items: items)
                    }
                }
            }
        } header: {
            if !softDeletedItems.isEmpty {
                HStack {
                    Text("Deleted Items (\(softDeletedItems.count))")
                    Spacer()
                    if !selectedItems.isEmpty {
                        Text("\(selectedItems.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func trashGroupSection(entityType: String, items: [SoftDeletedItem]) -> some View {
        Section(entityType) {
            ForEach(items) { item in
                TrashItemRow(
                    item: item,
                    isSelected: selectedItems.contains(item.uid),
                    onToggleSelection: { toggleSelection(for: item) }
                )
            }
        }
    }

    private var informationSection: some View {
        Section("Information") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Trash Bin")
                    .font(.headline)
                Text(
                    "When you delete items, they are moved to this trash bin. Items remain here for 90 days before being permanently deleted."
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Text("Automatic Cleanup")
                    .font(.headline)
                    .padding(.top, 8)
                Text(
                    "The app automatically cleans up items that have been in the trash for more than 90 days. This happens once daily in the background."
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var groupedItems: [String: [SoftDeletedItem]] {
        Dictionary(grouping: softDeletedItems) { item in
            switch item.entityType {
            case "Meal":
                return "Meals"
            case "Recipe":
                return "Recipes"
            case "TodoItem":
                return "Todo Items"
            case "ShoppingListItem":
                return "Shopping Items"
            case "User":
                return "Users"
            default:
                return item.entityType
            }
        }
    }

    private var eligibleItemsCount: Int {
        softDeletedItems.filter { $0.isEligibleForCleanup }.count
    }

    private func toggleSelection(for item: SoftDeletedItem) {
        if selectedItems.contains(item.uid) {
            selectedItems.remove(item.uid)
        } else {
            selectedItems.insert(item.uid)
        }
    }

    private func refreshTrashBin() async {
        isLoading = true
        defer { isLoading = false }

        do {
            softDeletedItems = await cleanupService.getAllSoftDeletedItems()
            logger.info("Refreshed trash bin: \(softDeletedItems.count) items")
        } catch {
            logger.error("Failed to refresh trash bin: \(error.localizedDescription)")
        }
    }

    private func refreshTrashBin() {
        Task {
            await refreshTrashBin()
        }
    }

    private func performCleanupEligibleItems() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let result = await cleanupService.performCleanup()
                lastCleanupResult = result
                showingCleanupAlert = true

                // Refresh the trash bin after cleanup
                await refreshTrashBin()

                logger.info("Manual cleanup completed, deleted \(result) items")
            } catch {
                logger.error("Failed to perform cleanup: \(error.localizedDescription)")
            }
        }
    }

    private func performCustomCleanup() {
        Task {
            isLoading = true
            defer {
                isLoading = false
                showingCustomThresholdSheet = false
            }

            do {
                let result = await cleanupService.performCleanup(afterDays: customThresholdDays)
                lastCleanupResult = result
                showingCleanupAlert = true

                // Refresh the trash bin after cleanup
                await refreshTrashBin()

                logger.info(
                    "Custom cleanup completed with \(customThresholdDays) day threshold, deleted \(result) items"
                )
            } catch {
                logger.error("Failed to perform custom cleanup: \(error.localizedDescription)")
            }
        }
    }
}

struct TrashItemRow: View {
    let item: SoftDeletedItem
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text("Deleted \(formatDeletedDate(item.deletedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if item.isEligibleForCleanup {
                        Text("Ready for cleanup")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("\(item.daysUntilCleanup) days left")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
    }

    private func formatDeletedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func performBulkDelete() {
        guard !selectedItems.isEmpty else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let deletedCount = await cleanupService.bulkDelete(
                    itemUIDs: Array(selectedItems))
                bulkOperationResult = (deletedCount, "permanently deleted")
                showingBulkResultAlert = true
                selectedItems.removeAll()

                // Refresh the trash bin after bulk delete
                await refreshTrashBin()

                logger.info("Bulk delete completed, deleted \(deletedCount) items")
            } catch {
                logger.error(
                    "Failed to perform bulk delete: \(error.localizedDescription)")
            }
        }
    }

    private func performBulkRestore() {
        guard !selectedItems.isEmpty, let currentUser = auth.currentUser else {
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let restoredCount = await cleanupService.bulkRestore(
                    itemUIDs: Array(selectedItems), currentUser: currentUser)
                bulkOperationResult = (restoredCount, "restored")
                showingBulkResultAlert = true
                selectedItems.removeAll()

                // Refresh the trash bin after bulk restore
                await refreshTrashBin()

                logger.info(
                    "Bulk restore completed, restored \(restoredCount) items")
            } catch {
                logger.error(
                    "Failed to perform bulk restore: \(error.localizedDescription)")
            }
        }
    }
}

struct CustomCleanupSheet: View {
    @Binding var thresholdDays: Int
    @Binding var isLoading: Bool
    let onPerformCleanup: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cleanupService: CleanupService
    @State private var previewItems: [SoftDeletedItem] = []
    @State private var isLoadingPreview = false

    var body: some View {
        NavigationView {
            List {
                Section("Threshold") {
                    HStack {
                        Text("Days:")
                        Spacer()
                        TextField("Days", value: $thresholdDays, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onChange(of: thresholdDays) { _, _ in
                                updatePreview()
                            }
                    }

                    Text(
                        "Items deleted more than \(thresholdDays) days ago will be permanently removed."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Section("Preview") {
                    if isLoadingPreview {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Calculating...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        let eligibleItems = previewItems.filter { $0.isEligibleForCleanup }
                        let remainingItems = previewItems.filter { !$0.isEligibleForCleanup }

                        if eligibleItems.isEmpty && remainingItems.isEmpty {
                            Text("No deleted items found")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Will be deleted: \(eligibleItems.count) items")
                                    .foregroundColor(.red)
                                Text("Will remain: \(remainingItems.count) items")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Custom Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cleanup") {
                        onPerformCleanup()
                    }
                    .disabled(isLoading || previewItems.filter { $0.isEligibleForCleanup }.isEmpty)
                }
            }
            .onAppear {
                updatePreview()
            }
        }
    }

    private func updatePreview() {
        Task {
            isLoadingPreview = true
            defer { isLoadingPreview = false }

            previewItems = await cleanupService.getAllSoftDeletedItems(afterDays: thresholdDays)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let auth = UserAuthService(modelContext: context)
        return TrashBinView()
            .environmentObject(CleanupService(modelContext: context))
            .environmentObject(auth)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
