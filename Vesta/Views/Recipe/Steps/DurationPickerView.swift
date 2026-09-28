import SwiftUI

struct DurationPickerView: View {
    @Binding var duration: TimeInterval?

    private struct DurationOption: Identifiable {
        let id: TimeInterval
        let label: String

        var seconds: TimeInterval { id }
    }

    private let options: [DurationOption] = [
        DurationOption(
            id: 5 * 60, label: NSLocalizedString("5m", comment: "5 minutes duration chip")),
        DurationOption(
            id: 10 * 60, label: NSLocalizedString("10m", comment: "10 minutes duration chip")),
        DurationOption(
            id: 15 * 60, label: NSLocalizedString("15m", comment: "15 minutes duration chip")),
        DurationOption(
            id: 20 * 60, label: NSLocalizedString("20m", comment: "20 minutes duration chip")),
        DurationOption(
            id: 30 * 60, label: NSLocalizedString("30m", comment: "30 minutes duration chip")),
        DurationOption(
            id: 45 * 60, label: NSLocalizedString("45m", comment: "45 minutes duration chip")),
        DurationOption(
            id: 60 * 60, label: NSLocalizedString("1h", comment: "1 hour duration chip")),
        DurationOption(
            id: 90 * 60, label: NSLocalizedString("1.5h", comment: "1.5 hours duration chip")),
        DurationOption(
            id: 120 * 60, label: NSLocalizedString("2h", comment: "2 hours duration chip")),
    ]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(options) { option in
                    let isSelected = duration == option.seconds
                    Button {
                        if isSelected {
                            duration = nil
                        } else {
                            duration = option.seconds
                        }
                    } label: {
                        Text(option.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(Color.accentColor)
                                    : AnyShapeStyle(Color.secondary.opacity(0.2))
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.label)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("No selection") {
    DurationPickerView(duration: .constant(nil))
        .padding()
}

#Preview("30 min selected") {
    DurationPickerView(duration: .constant(30 * 60))
        .padding()
}
