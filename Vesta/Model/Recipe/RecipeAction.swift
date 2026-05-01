import Foundation

enum RecipeAction: Hashable, Identifiable {
    case complete
    case makeVegan
    case makeVegetarian
    case makeKidFriendly
    case makeFaster
    case simplify
    case makeMoreDetailed
    case rewrite
    case custom(prompt: String)

    var displayName: String {
        switch self {
        case .complete:
            return NSLocalizedString("Complete Recipe", comment: "Fill in missing recipe data")
        case .makeVegan:
            return NSLocalizedString("Make Vegan", comment: "Transform recipe to vegan")
        case .makeVegetarian:
            return NSLocalizedString("Make Vegetarian", comment: "Transform recipe to vegetarian")
        case .makeKidFriendly:
            return NSLocalizedString("Make Kid-Friendly", comment: "Make recipe kid-friendly")
        case .makeFaster:
            return NSLocalizedString(
                "Make Faster", comment: "Reduce cooking time and simplify steps")
        case .simplify:
            return NSLocalizedString("Simplify", comment: "Use fewer and simpler ingredients")
        case .makeMoreDetailed:
            return NSLocalizedString("More Detail", comment: "Add more detail to instructions")
        case .rewrite:
            return NSLocalizedString("Rewrite", comment: "Rewrite and translate recipe")
        case .custom(let prompt):
            if prompt.isEmpty {
                return NSLocalizedString("Custom", comment: "Custom recipe transformation")
            }
            let maxLength = 30
            if prompt.count > maxLength {
                return String(prompt.prefix(maxLength)) + "…"
            }
            return prompt
        }
    }

    var systemImage: String {
        switch self {
        case .complete:
            return "sparkles"
        case .makeVegan:
            return "leaf.fill"
        case .makeVegetarian:
            return "leaf"
        case .makeKidFriendly:
            return "figure.and.child.holdinghands"
        case .makeFaster:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .simplify:
            return "square.stack.3d.up.slash.fill"
        case .makeMoreDetailed:
            return "text.justify.leading"
        case .rewrite:
            return "character.book.closed.fill"
        case .custom:
            return "pencil"
        }
    }

    var id: String {
        switch self {
        case .complete:
            return "complete"
        case .makeVegan:
            return "makeVegan"
        case .makeVegetarian:
            return "makeVegetarian"
        case .makeKidFriendly:
            return "makeKidFriendly"
        case .makeFaster:
            return "makeFaster"
        case .simplify:
            return "simplify"
        case .makeMoreDetailed:
            return "makeMoreDetailed"
        case .rewrite:
            return "rewrite"
        case .custom(let prompt):
            let hash = prompt.hashValue
            return "custom-\(hash)"
        }
    }

    static var presets: [RecipeAction] {
        [
            .complete, .makeVegan, .makeVegetarian, .makeKidFriendly, .makeFaster, .simplify,
            .makeMoreDetailed, .rewrite,
        ]
    }
}

// MARK: - Codable

extension RecipeAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case prompt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .complete:
            try container.encode("complete", forKey: .kind)
        case .makeVegan:
            try container.encode("makeVegan", forKey: .kind)
        case .makeVegetarian:
            try container.encode("makeVegetarian", forKey: .kind)
        case .makeKidFriendly:
            try container.encode("makeKidFriendly", forKey: .kind)
        case .makeFaster:
            try container.encode("makeFaster", forKey: .kind)
        case .simplify:
            try container.encode("simplify", forKey: .kind)
        case .makeMoreDetailed:
            try container.encode("makeMoreDetailed", forKey: .kind)
        case .rewrite:
            try container.encode("rewrite", forKey: .kind)
        case .custom(let prompt):
            try container.encode("custom", forKey: .kind)
            try container.encode(prompt, forKey: .prompt)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "complete":
            self = .complete
        case "makeVegan":
            self = .makeVegan
        case "makeVegetarian":
            self = .makeVegetarian
        case "makeKidFriendly":
            self = .makeKidFriendly
        case "makeFaster":
            self = .makeFaster
        case "simplify":
            self = .simplify
        case "makeMoreDetailed":
            self = .makeMoreDetailed
        case "rewrite":
            self = .rewrite
        case "custom":
            let prompt = try container.decode(String.self, forKey: .prompt)
            self = .custom(prompt: prompt)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown RecipeAction kind: \(kind)"
            )
        }
    }
}
