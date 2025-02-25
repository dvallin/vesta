import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItem

    @State private var isEditingTitle = false
    @State private var isEditingDetails = false

    var body: some View {
        Form {
            Text(item.title)
                .font(.title)
                .bold()
                .onTapGesture {
                    isEditingTitle = true
                }

            Section(header: Text("Description")) {
                Text(item.details)
                    .onTapGesture {
                        isEditingDetails = true
                    }
            }

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
        .sheet(isPresented: $isEditingTitle) {
            EditTitleView(
                navigationBarTitle: "Edit Title",
                title: Binding(
                    get: { item.title },
                    set: { newValue in
                        item.setTitle(modelContext: modelContext, title: newValue)
                    }
                ))
        }
        .sheet(isPresented: $isEditingDetails) {
            EditDetailsView(
                navigationBarTitle: "Edit Description",
                details: Binding(
                    get: { item.details },
                    set: { newValue in
                        item.setDetails(
                            modelContext: modelContext, details: newValue)
                    }
                ))
        }
    }

    private func markAsDone() {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
        }
    }
}
