import SwiftUI

/// A generic, reusable autocomplete selector component that displays a text field with dropdown suggestions.
///
/// This component is designed to be used with any type that can be represented as a selectable entry.
/// It provides:
/// - Inline title and text field layout
/// - Dropdown suggestions with search filtering
/// - Keyboard navigation and focus management
/// - Clear button functionality
/// - Customizable appearance
///
/// Usage:
/// ```swift
/// AutocompleteSelector(
///     title: "Select Item",
///     placeholder: "Enter or select...",
///     selectedItem: $selectedValue,
///     suggestions: items.map { SelectorEntry(name: $0.displayName) },
///     onTextChange: { text in /* handle text changes */ },
///     onItemSelected: { selection in /* handle selection */ }
/// )
/// ```
struct AutocompleteSelector: View {
    let title: String
    let placeholder: String
    @Binding var selectedItem: String
    let suggestions: [SelectorEntry]
    let onTextChange: (String) -> Void
    let onItemSelected: (String) -> Void

    @State private var inputText: String = ""
    @State private var showingSuggestions: Bool = false
    @FocusState private var isInputFocused: Bool

    init(
        title: String,
        placeholder: String,
        selectedItem: Binding<String>,
        suggestions: [SelectorEntry],
        onTextChange: @escaping (String) -> Void,
        onItemSelected: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self._selectedItem = selectedItem
        self.suggestions = suggestions
        self.onTextChange = onTextChange
        self.onItemSelected = onItemSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and input field on the same line
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                    .font(.body)

                Spacer()

                // Input field with dropdown indicator
                HStack {
                    TextField(placeholder, text: $inputText)
                        .focused($isInputFocused)
                        .onChange(of: inputText) { _, newValue in
                            onTextChange(newValue)
                            showingSuggestions = !newValue.isEmpty && isInputFocused
                        }
                        .onChange(of: isInputFocused) { _, focused in
                            showingSuggestions =
                                focused && !inputText.isEmpty && !suggestions.isEmpty
                        }
                        .onSubmit {
                            selectItem(inputText)
                        }
                        .onAppear {
                            // Initialize input text with selected item when view appears
                            if inputText.isEmpty && !selectedItem.isEmpty {
                                inputText = selectedItem
                            }
                        }

                    // Dropdown arrow
                    Button(action: {
                        if isInputFocused {
                            isInputFocused = false
                            showingSuggestions = false
                        } else {
                            isInputFocused = true
                            if !inputText.isEmpty {
                                showingSuggestions = !suggestions.isEmpty
                            }
                        }
                    }) {
                        Image(systemName: showingSuggestions ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Clear button (only show if there's text)
                    if !inputText.isEmpty {
                        Button(action: {
                            clearSelection()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isInputFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .frame(minWidth: 150)
            }

            // Suggestions dropdown
            if showingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        Button(action: {
                            selectItem(suggestion.name)
                        }) {
                            HStack {
                                Text(suggestion.name)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()

                                // Show checkmark if this is the selected item
                                if suggestion.name == selectedItem {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            Color(.systemBackground)
                                .onTapGesture {
                                    selectItem(suggestion.name)
                                }
                        )

                        if suggestion != suggestions.last {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity
                    )
                )
                .zIndex(1)
            }
        }
    }

    private func selectItem(_ itemName: String) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)

        withAnimation(.easeInOut(duration: 0.2)) {
            inputText = trimmedName
            selectedItem = trimmedName
            showingSuggestions = false
            isInputFocused = false
            onItemSelected(trimmedName)
        }
    }

    private func clearSelection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            inputText = ""
            selectedItem = ""
            showingSuggestions = false
            onItemSelected("")
            onTextChange("")
        }
    }
}

#Preview("Empty Item") {
    struct EmptyItemPreview: View {
        @State private var selectedItem = ""
        @State private var suggestions: [SelectorEntry] = []
        @State private var allItems = [
            SelectorEntry(name: "Work"),
            SelectorEntry(name: "Personal"),
            SelectorEntry(name: "Shopping"),
            SelectorEntry(name: "Health"),
            SelectorEntry(name: "Travel"),
            SelectorEntry(name: "Finance"),
        ]

        var body: some View {
            Form {
                AutocompleteSelector(
                    title: "Item",
                    placeholder: "Enter or select item",
                    selectedItem: $selectedItem,
                    suggestions: suggestions,
                    onTextChange: { text in
                        if text.isEmpty {
                            suggestions = allItems
                        } else {
                            suggestions = allItems.filter {
                                $0.name.lowercased().contains(text.lowercased())
                            }
                        }
                    },
                    onItemSelected: { item in
                        print("Selected item: \(item)")
                    }
                )
            }
        }
    }

    return EmptyItemPreview()
}

#Preview("With Selected Item") {
    struct SelectedItemPreview: View {
        @State private var selectedItem = "Work"
        @State private var suggestions: [SelectorEntry] = []
        @State private var allItems = [
            SelectorEntry(name: "Work"),
            SelectorEntry(name: "Personal"),
            SelectorEntry(name: "Shopping"),
            SelectorEntry(name: "Health"),
            SelectorEntry(name: "Travel"),
            SelectorEntry(name: "Finance"),
        ]

        var body: some View {
            Form {
                AutocompleteSelector(
                    title: "Item",
                    placeholder: "Enter or select item",
                    selectedItem: $selectedItem,
                    suggestions: suggestions,
                    onTextChange: { text in
                        if text.isEmpty {
                            suggestions = allItems
                        } else {
                            suggestions = allItems.filter {
                                $0.name.lowercased().contains(text.lowercased())
                            }
                        }
                    },
                    onItemSelected: { item in
                        print("Selected item: \(item)")
                    }
                )
            }
        }
    }

    return SelectedItemPreview()
}

#Preview("With Suggestions") {
    struct SuggestionsPreview: View {
        @State private var selectedItem = ""
        @State private var suggestions: [SelectorEntry] = [
            SelectorEntry(name: "Work"),
            SelectorEntry(name: "Workshop"),
            SelectorEntry(name: "Workout"),
        ]
        @State private var allItems = [
            SelectorEntry(name: "Work"),
            SelectorEntry(name: "Workshop"),
            SelectorEntry(name: "Workout"),
            SelectorEntry(name: "Personal"),
            SelectorEntry(name: "Shopping"),
            SelectorEntry(name: "Health"),
        ]

        var body: some View {
            Form {
                AutocompleteSelector(
                    title: "Item",
                    placeholder: "Enter or select item",
                    selectedItem: $selectedItem,
                    suggestions: suggestions,
                    onTextChange: { text in
                        if text.isEmpty {
                            suggestions = allItems
                        } else {
                            suggestions = allItems.filter {
                                $0.name.lowercased().contains(text.lowercased())
                            }
                        }
                    },
                    onItemSelected: { item in
                        print("Selected item: \(item)")
                    }
                )
            }
        }
    }

    return SuggestionsPreview()
}
