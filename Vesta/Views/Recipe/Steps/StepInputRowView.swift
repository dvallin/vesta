import SwiftUI

struct StepInputRowView: View {
    @Binding var instruction: String
    @Binding var type: StepType
    @Binding var duration: TimeInterval?

    let onAdd: () -> Void

    private enum FocusableField: Hashable {
        case instruction
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        VStack(spacing: 8) {
            // Primary row: Instruction + Add button
            HStack(alignment: .top) {
                TextEditor(text: $instruction)
                    .focused($focusedField, equals: .instruction)
                    .frame(minHeight: 60)
                    .submitLabel(.done)
                    .onSubmit {
                        addStep()
                    }

                Button(action: addStep) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .accessibilityIdentifier("AddStepButton")
            }

            // Secondary row: Type picker + Duration chips
            HStack(spacing: 8) {
                Picker("", selection: $type) {
                    ForEach(StepType.allCases, id: \.self) { stepType in
                        Text(stepType.displayName).tag(stepType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .fixedSize()

                DurationPickerView(duration: $duration)
            }
        }
        .onAppear {
            focusedField = .instruction
        }
    }

    private func addStep() {
        withAnimation {
            onAdd()
            duration = nil
            focusedField = .instruction
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var instruction = ""
        @State private var type: StepType = .cooking
        @State private var duration: TimeInterval? = nil

        var body: some View {
            Form {
                StepInputRowView(
                    instruction: $instruction,
                    type: $type,
                    duration: $duration,
                    onAdd: {
                        print(
                            "Added: \(instruction), \(type.displayName), \(String(describing: duration))"
                        )
                        instruction = ""
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}
