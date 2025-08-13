import Foundation

/// A generic entry type for selector components that need to display selectable items
///
/// This type allows selector components to work with any domain type by mapping them
/// to a common interface. It provides a clean separation between UI components and
/// domain models.
///
/// Used by:
/// - `AutocompleteSelector`: Single selection with dropdown suggestions
/// - `MultiSelector`: Multiple selection with chip-based display
///
/// Both components now use `SelectorEntry` for a unified, consistent API.
///
/// Example usage with different domain types:
/// ```swift
/// // With AutocompleteSelector for categories
/// let todoCategories: [TodoItemCategory] = [...]
/// let categoryEntries = Array<SelectorEntry>.from(todoCategories, keyPath: \.name)
/// AutocompleteSelector(suggestions: categoryEntries, ...)
///
/// // With MultiSelector for tags (string arrays)
/// let tags: [String] = [...]
/// let tagEntries = Array<SelectorEntry>.from(tags)
/// MultiSelector(items: tagEntries, ...)
///
/// // With custom domain types (works for both components)
/// struct Department { let name: String, let code: String }
/// let departments: [Department] = [...]
/// let departmentEntries = Array<SelectorEntry>.from(departments, keyPath: \.name)
///
/// // Convert back to domain models
/// let selectedNames = selectedEntries.names // Returns [String]
/// ```
struct SelectorEntry: Identifiable, Hashable {
    let id: UUID
    let name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension SelectorEntry {
    /// Creates a SelectorEntry from any object that has a name property
    static func from<T>(_ item: T, keyPath: KeyPath<T, String>) -> SelectorEntry {
        SelectorEntry(name: item[keyPath: keyPath])
    }

    /// Creates a SelectorEntry from any object that has a name property and an id
    static func from<T>(_ item: T, nameKeyPath: KeyPath<T, String>, idKeyPath: KeyPath<T, UUID>)
        -> SelectorEntry
    {
        SelectorEntry(id: item[keyPath: idKeyPath], name: item[keyPath: nameKeyPath])
    }
}

// MARK: - Collection Extensions
extension Array where Element == SelectorEntry {
    /// Creates an array of SelectorEntry from any collection with a name property
    static func from<T>(_ items: [T], keyPath: KeyPath<T, String>) -> [SelectorEntry] {
        items.map { SelectorEntry.from($0, keyPath: keyPath) }
    }

    /// Creates an array of SelectorEntry from any collection with name and id properties
    static func from<T>(_ items: [T], nameKeyPath: KeyPath<T, String>, idKeyPath: KeyPath<T, UUID>)
        -> [SelectorEntry]
    {
        items.map { SelectorEntry.from($0, nameKeyPath: nameKeyPath, idKeyPath: idKeyPath) }
    }

    /// Creates an array of SelectorEntry from an array of strings
    /// Convenient for simple use cases like tags, categories, etc.
    static func from(_ strings: [String]) -> [SelectorEntry] {
        strings.map { SelectorEntry(name: $0) }
    }

    /// Extracts the names from an array of SelectorEntry back to strings
    /// Useful for converting back to domain models
    var names: [String] {
        map { $0.name }
    }
}
