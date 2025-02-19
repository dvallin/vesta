import SwiftData
import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItem

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField(
                    "Title",
                    text: Binding(
                        get: { item.title },
                        set: { newValue in
                            item.setTitle(modelContext: modelContext, title: newValue)
                        }
                    )
                )
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)

                TextEditor(
                    text: Binding(
                        get: { item.details },
                        set: { newValue in
                            item.setDetails(modelContext: modelContext, details: newValue)
                        }
                    )
                )
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8).stroke(.tertiary, lineWidth: 1)
                )
                .padding(.horizontal)

                Spacer()

                Toggle(
                    "Enable Due Date",
                    isOn: Binding(
                        get: { item.dueDate != nil },
                        set: { newValue in
                            item.setDueDate(
                                modelContext: modelContext, dueDate: newValue ? Date() : nil)
                        }
                    )
                )
                .padding(.horizontal)

                if let dueDate = item.dueDate {
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dueDate },
                                set: { newValue in
                                    item.setDueDate(modelContext: modelContext, dueDate: newValue)
                                }
                            ),
                            displayedComponents: .date
                        )
                        .padding(.horizontal)

                        Picker(
                            "Recurrence",
                            selection: Binding(
                                get: { item.recurrenceFrequency },
                                set: { newValue in
                                    item.setRecurrenceFrequency(
                                        modelContext: modelContext, recurrenceFrequency: newValue)
                                }
                            )
                        ) {
                            Text("None").tag(Optional<RecurrenceFrequency>.none)
                            Text("Daily").tag(RecurrenceFrequency?.some(.daily))
                            Text("Weekly").tag(RecurrenceFrequency?.some(.weekly))
                            Text("Monthly").tag(RecurrenceFrequency?.some(.monthly))
                            Text("Yearly").tag(RecurrenceFrequency?.some(.yearly))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        Toggle(
                            "Fixed Recurrence",
                            isOn: Binding(
                                get: { item.recurrenceType == .some(.fixed) },
                                set: { newValue in
                                    item.setRecurrenceType(
                                        modelContext: modelContext,
                                        recurrenceType: newValue ? .some(.fixed) : .some(.flexible))
                                }
                            )
                        )
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }

                Section(header: Text("Actions")) {
                    Button(action: markAsDone) {
                        Label("Mark as Done", systemImage: "checkmark.circle")
                    }
                    .disabled(item.isCompleted)

                    Toggle(
                        "Completed",
                        isOn: Binding(
                            get: { item.isCompleted },
                            set: { newValue in
                                item.setIsCompleted(
                                    modelContext: modelContext, isCompleted: newValue)
                            }
                        )
                    )
                }
                .padding(.horizontal)
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func markAsDone() {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
        }
    }
}
