import SwiftUI

struct StepInputRowView: View {
    @Binding var instruction: String
    @Binding var type: StepType
    @Binding var duration: TimeInterval?

    let onAdd: () -> Void

    @State private var durationString: String = ""

    enum FocusableField: Hashable {
        case duration
        case instruction
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        VStack {
            HStack {
                TextField(
                    NSLocalizedString("Duration (min)", comment: "Step duration field placeholder"),
                    text: $durationString
                )
                .focused($focusedField, equals: .duration)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .instruction
                }
                .onChange(of: durationString) {
                    if let minutes = Double(durationString) {
                        duration = minutes * 60
                    } else {
                        duration = nil
                    }
                }

                Picker("", selection: $type) {
                    ForEach(StepType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .fixedSize()
            }

            HStack {
                TextEditor(text: $instruction)
                    .focused($focusedField, equals: .instruction)
                    .submitLabel(.done)
                    .onSubmit { onAdd() }

                Button(action: {
                    withAnimation {
                        onAdd()
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }.accessibilityIdentifier("AddStepButton")
            }
        }
    }
}
