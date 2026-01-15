import SwiftUI

struct SearchableNavigationBar: View {
    let title: String
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    @FocusState.Binding var isSearchFocused: Bool
    let searchPlaceholder: String
    init(
        title: String,
        searchText: Binding<String>,
        isSearchActive: Binding<Bool>,
        isSearchFocused: FocusState<Bool>.Binding,
        searchPlaceholder: String = "Search..."
    ) {
        self.title = title
        self._searchText = searchText
        self._isSearchActive = isSearchActive
        self._isSearchFocused = isSearchFocused
        self.searchPlaceholder = searchPlaceholder
    }

    var body: some View {
        HStack {
            if isSearchActive {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField(searchPlaceholder, text: $searchText)
                        .focused($isSearchFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.headline)

                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearchActive = false
                            searchText = ""
                            isSearchFocused = false
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack {
                    Text(NSLocalizedString(title, comment: "Navigation title"))
                        .font(.headline)
                        .fontWeight(.semibold)

                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isSearchActive = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isSearchFocused = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Basic Usage") {
    NavigationView {
        VStack {
            Text("Basic search bar without trailing items")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchableNavigationBarBasicPreview()
            }
        }
    }
}

#Preview("With Trailing Items") {
    NavigationView {
        VStack {
            Text("Search bar with trailing toolbar items")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchableNavigationBarWithTrailingPreview()
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                SearchableNavigationBarWithTrailingPreview.TrailingItems()
            }
        }
    }
}

private struct SearchableNavigationBarBasicPreview: View {
    @State private var searchText = ""
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        SearchableNavigationBar(
            title: "Recipes",
            searchText: $searchText,
            isSearchActive: $isSearchActive,
            isSearchFocused: $isSearchFocused,
            searchPlaceholder: "Search recipes..."
        )
    }
}

private struct SearchableNavigationBarWithTrailingPreview: View {
    @State private var searchText = ""
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        SearchableNavigationBar(
            title: "Add Meal",
            searchText: $searchText,
            isSearchActive: $isSearchActive,
            isSearchFocused: $isSearchFocused,
            searchPlaceholder: "Search recipes..."
        )
    }

    struct TrailingItems: View {
        var body: some View {
            Menu {
                Button("Sort by Name") {}
                Button("Sort by Date") {}
                Button("Sort by Rating") {}
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down.circle")
            }
            .labelStyle(IconOnlyLabelStyle())
        }
    }
}
