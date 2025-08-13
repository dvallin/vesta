import SwiftUI
import os

/// A generic, reusable multi-selection component that displays items as removable chips.
///
/// This component uses `SelectorEntry` for consistency with `AutocompleteSelector` and provides:
/// - Multi-item selection with visual chips
/// - Add new items via text input
/// - Remove items with tap gestures
/// - Unified API with other selector components
/// - Adaptive grid layout
///
/// Usage:
/// ```swift
/// // With string arrays (common case)
/// MultiSelector(
///     title: "Tags",
///     placeholder: "Add tag",
///     items: Array<SelectorEntry>.from(stringTags),
///     onAdd: { newTag in /* handle adding */ },
///     onRemove: { tagEntry in /* handle removal */ }
/// )
///
/// // With domain models
/// MultiSelector(
///     title: "Categories",
///     placeholder: "Add category",
///     items: Array<SelectorEntry>.from(categories, keyPath: \.name),
///     onAdd: { newItem in /* handle adding */ },
///     onRemove: { entry in /* handle removal */ }
/// )
/// ```
struct MultiSelector: View {
    let title: String
    let placeholder: String
    let items: [SelectorEntry]
    let onAdd: (String) -> Void
    let onRemove: (SelectorEntry) -> Void

    @State private var newItemText: String = ""
    @FocusState private var isInputFocused: Bool

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MultiSelector", category: "MultiSelector")

    init(
        title: String,
        placeholder: String,
        items: [SelectorEntry],
        onAdd: @escaping (String) -> Void,
        onRemove: @escaping (SelectorEntry) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.items = items
        self.onAdd = onAdd
        self.onRemove = onRemove
    }

    var body: some View {
        Section(header: Text(title)) {
            if !items.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 4) {
                    ForEach(items) { item in
                        tagChip(for: item)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                TextField(placeholder, text: $newItemText)
                    .focused($isInputFocused)
                    .onSubmit {
                        addItem()
                    }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @ViewBuilder
    private func tagChip(for item: SelectorEntry) -> some View {
        HStack(spacing: 8) {
            Text(item.name)
                .font(.caption)
                .foregroundColor(.accentColor)

            Button(action: {
                withAnimation {
                    logger.info(
                        "Removing item: \(item.name)")
                    onRemove(item)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }

    private func addItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation {
            logger.info("Adding item: \(trimmedText)")
            onAdd(trimmedText)
            newItemText = ""
        }
    }
}

#Preview("Multiple Items") {
    struct MultipleItemsPreview: View {
        @State private var items: [SelectorEntry] = [
            SelectorEntry(name: "Work"),
            SelectorEntry(name: "Personal"),
            SelectorEntry(name: "Important"),
        ]

        var body: some View {
            Form {
                MultiSelector(
                    title: "Items",
                    placeholder: "Add item",
                    items: items,
                    onAdd: { newItem in
                        let entry = SelectorEntry(name: newItem)
                        if !items.contains(where: { $0.name == newItem }) {
                            items.append(entry)
                        }
                    },
                    onRemove: { item in
                        items.removeAll { $0.id == item.id }
                    }
                )
            }
        }
    }

    return MultipleItemsPreview()
}

#Preview("Empty State") {
    struct EmptyStatePreview: View {
        @State private var items: [SelectorEntry] = []

        var body: some View {
            Form {
                MultiSelector(
                    title: "Items",
                    placeholder: "Add item",
                    items: items,
                    onAdd: { newItem in
                        items.append(SelectorEntry(name: newItem))
                    },
                    onRemove: { item in
                        items.removeAll { $0.id == item.id }
                    }
                )
            }
        }
    }

    return EmptyStatePreview()
}
