import Foundation

/// Parses free-text ingredient strings like "200g flour" or "2 tbsp olive oil"
/// into structured (quantity, unit, name) components.
struct IngredientParser {
    struct Result {
        let name: String
        let quantity: Double?
        let unit: Unit?
    }

    // Mapping from common text representations to Unit enum values
    private static let unitMap: [(patterns: [String], unit: Unit)] = [
        (["tsp", "teaspoon", "teaspoons", "tl"], .teaspoon),
        (["tbsp", "tablespoon", "tablespoons", "el"], .tablespoon),
        (["cup", "cups", "tasse", "tassen"], .cup),
        (["ml", "milliliter", "milliliters", "millilitres"], .milliliter),
        (["l", "liter", "liters", "litres", "litre"], .liter),
        (["g", "gram", "grams", "gramm"], .gram),
        (["kg", "kilogram", "kilograms", "kilogramm"], .kilogram),
        (["oz", "ounce", "ounces"], .ounce),
        (["lb", "lbs", "pound", "pounds", "pfund"], .pound),
        (["pc", "pcs", "piece", "pieces", "stk", "stück"], .piece),
    ]

    /// Attempts to parse a free-text ingredient string into structured components.
    ///
    /// Supported formats:
    /// - "200g flour" → qty=200, unit=gram, name="flour"
    /// - "2 tbsp olive oil" → qty=2, unit=tablespoon, name="olive oil"
    /// - "100 ml milk" → qty=100, unit=milliliter, name="milk"
    /// - "3 eggs" → qty=3, unit=nil, name="eggs"
    /// - "1.5kg chicken" → qty=1.5, unit=kilogram, name="chicken"
    /// - "1/2 cup sugar" → qty=0.5, unit=cup, name="sugar"
    /// - "salt" → qty=nil, unit=nil, name="salt"
    ///
    /// - Parameter text: The raw ingredient text to parse
    /// - Returns: A parsed `Result` with name, optional quantity, and optional unit
    static func parse(_ text: String) -> Result {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return Result(name: "", quantity: nil, unit: nil)
        }

        // Try to match a leading number (integer, decimal, or fraction)
        guard let quantityMatch = matchLeadingQuantity(in: trimmed) else {
            // No leading number found — treat entire text as the name
            return Result(name: trimmed, quantity: nil, unit: nil)
        }

        let quantity = quantityMatch.value
        let afterQuantity = String(trimmed.dropFirst(quantityMatch.length))
            .trimmingCharacters(in: .whitespaces)

        guard !afterQuantity.isEmpty else {
            // Only a number with nothing after it — treat as name (e.g., someone typed "3")
            return Result(name: trimmed, quantity: nil, unit: nil)
        }

        // Try to match a unit at the start of the remaining text
        if let unitMatch = matchLeadingUnit(in: afterQuantity) {
            let afterUnit = String(afterQuantity.dropFirst(unitMatch.length))
                .trimmingCharacters(in: .whitespaces)
            let name = afterUnit.isEmpty ? trimmed : afterUnit
            if afterUnit.isEmpty {
                // Unit matched but nothing after — treat entire string as name
                return Result(name: trimmed, quantity: nil, unit: nil)
            }
            return Result(name: afterUnit, quantity: quantity, unit: unitMatch.unit)
        }

        // No unit found — quantity + rest is name (e.g., "3 eggs")
        return Result(name: afterQuantity, quantity: quantity, unit: nil)
    }

    // MARK: - Private Helpers

    private struct QuantityMatch {
        let value: Double
        let length: Int
    }

    private struct UnitMatch {
        let unit: Unit
        let length: Int
    }

    /// Matches a leading number which can be:
    /// - A decimal: "1.5", "200", "0.25"
    /// - A fraction: "1/2", "3/4"
    /// - A mixed number: "1 1/2" (not supported for simplicity — just decimal and fraction)
    private static func matchLeadingQuantity(in text: String) -> QuantityMatch? {
        // Try fraction pattern first: digits/digits
        let fractionPattern = #"^(\d+)\s*/\s*(\d+)"#
        if let fractionRegex = try? NSRegularExpression(pattern: fractionPattern),
            let match = fractionRegex.firstMatch(
                in: text, range: NSRange(text.startIndex..., in: text))
        {
            let numeratorRange = Range(match.range(at: 1), in: text)!
            let denominatorRange = Range(match.range(at: 2), in: text)!
            let numerator = Double(text[numeratorRange])!
            let denominator = Double(text[denominatorRange])!
            if denominator != 0 {
                return QuantityMatch(
                    value: numerator / denominator,
                    length: match.range.length
                )
            }
        }

        // Try decimal/integer pattern
        // Support both dot and comma as decimal separator
        let decimalPattern = #"^(\d+[.,]\d+|\d+)"#
        if let decimalRegex = try? NSRegularExpression(pattern: decimalPattern),
            let match = decimalRegex.firstMatch(
                in: text, range: NSRange(text.startIndex..., in: text))
        {
            let matchRange = Range(match.range, in: text)!
            let matchedText = String(text[matchRange]).replacingOccurrences(of: ",", with: ".")
            if let value = Double(matchedText) {
                return QuantityMatch(value: value, length: match.range.length)
            }
        }

        return nil
    }

    /// Matches a unit keyword at the start of the text.
    /// Handles both cases where the unit is glued to the number ("200g") and separated ("200 g").
    private static func matchLeadingUnit(in text: String) -> UnitMatch? {
        let lowered = text.lowercased()

        for (patterns, unit) in unitMap {
            for pattern in patterns {
                if lowered.hasPrefix(pattern) {
                    let afterUnit = lowered.index(lowered.startIndex, offsetBy: pattern.count)
                    // Make sure the unit isn't part of a longer word
                    // (e.g., "grapes" shouldn't match "g")
                    if afterUnit == lowered.endIndex
                        || lowered[afterUnit] == " "
                        || lowered[afterUnit] == "\t"
                    {
                        return UnitMatch(unit: unit, length: pattern.count)
                    }
                }
            }
        }

        return nil
    }
}
