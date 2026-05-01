import SwiftUI

struct StepListView<StepType: Identifiable>: View {
    var steps: [StepType]
    let onRemove: (StepType) -> Void
    let onMove: (IndexSet, Int) -> Void
    let typeText: (StepType) -> String
    let durationText: (StepType) -> String
    let instructionText: (StepType) -> String

    var body: some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top) {
                Text("\(index + 1).")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .frame(width: 24, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(instructionText(step))
                        .font(.subheadline)
                    HStack(spacing: 4) {
                        Text(typeText(step))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        let duration = durationText(step)
                        if !duration.isEmpty {
                            Text("·")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
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
