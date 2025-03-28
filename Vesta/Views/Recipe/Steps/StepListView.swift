import SwiftUI

struct StepListView<StepType: Identifiable>: View {
    var steps: [StepType]
    let onRemove: (StepType) -> Void
    let onMove: (IndexSet, Int) -> Void
    let typeText: (StepType) -> String
    let durationText: (StepType) -> String
    let instructionText: (StepType) -> String

    var body: some View {
        ForEach(steps) { step in
            VStack(alignment: .leading) {
                HStack {
                    Text(typeText(step))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(durationText(step))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(instructionText(step))
            }
        }
        .onDelete { indexSet in
            indexSet.forEach { index in
                let step = steps[index]
                onRemove(step)
            }
        }
        .onMove(perform: onMove)
    }
}
