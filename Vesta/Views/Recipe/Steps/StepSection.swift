import SwiftUI

struct StepsSection<S: Identifiable>: View {
    let header: String

    var steps: [S]

    let moveHandler: (IndexSet, Int) -> Void
    let removeHandler: (S) -> Void
    let typeText: (S) -> String
    let durationText: (S) -> String
    let instructionText: (S) -> String

    @Binding var instruction: String
    @Binding var type: StepType
    @Binding var duration: TimeInterval?

    let onAdd: () -> Void

    var body: some View {
        Section(header: Text(header)) {
            StepListView(
                steps: steps,
                onRemove: removeHandler,
                onMove: moveHandler,
                typeText: typeText,
                durationText: durationText,
                instructionText: instructionText
            )
            StepInputRowView(
                instruction: $instruction,
                type: $type,
                duration: $duration,
                onAdd: onAdd
            )
        }
    }
}
