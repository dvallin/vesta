import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItem

    @FocusState private var focusedField: String?

    var body: some View {
        NavigationView {
            Form {
                // Reusable Title & Details section
                TitleDetailsSection(
                    title: Binding(
                        get: { item.title },
                        set: { newValue in
                            item.setTitle(modelContext: modelContext, title: newValue)
                        }
                    ),
                    details: Binding(
                        get: { item.details },
                        set: { newValue in
                            item.setDetails(modelContext: modelContext, details: newValue)
                        }
                    ),
                    focusedField: $focusedField
                )

                // Reusable Due Date & Recurrence
                DueDateRecurrenceSection(
                    dueDate: Binding(
                        get: { item.dueDate },
                        set: { newValue in
                            item.setDueDate(modelContext: modelContext, dueDate: newValue)
                        }
                    ),
                    recurrenceFrequency: Binding(
                        get: { item.recurrenceFrequency },
                        set: { newValue in
                            item.setRecurrenceFrequency(
                                modelContext: modelContext,
                                recurrenceFrequency: newValue
                            )
                        }
                    ),
                    recurrenceType: Binding(
                        get: { item.recurrenceType },
                        set: { newValue in
                            item.setRecurrenceType(
                                modelContext: modelContext,
                                recurrenceType: newValue
                            )
                        }
                    )
                )

                Section("Actions") {
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
                                    modelContext: modelContext,
                                    isCompleted: newValue
                                )
                            }
                        )
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func markAsDone() {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
        }
    }
}
