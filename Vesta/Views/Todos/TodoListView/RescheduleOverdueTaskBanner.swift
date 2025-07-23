import SwiftUI

struct RescheduleOverdueTaskBanner: View {
    @ObservedObject var viewModel: TodoListViewModel

    let todoItems: [TodoItem]

    var body: some View {
        if viewModel.hasRescheduleOverdueTasks(todoItems: todoItems) {
            if viewModel.filterMode != .overdue {
                Button(action: viewModel.showRescheduleOverdueTasks) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(
                            NSLocalizedString(
                                "There are overdue tasks", comment: "Warning about overdue tasks"))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                }
                .padding(.top, 8)
            } else {
                Button(action: {
                    viewModel.rescheduleOverdueTasks(todoItems: todoItems)
                    HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text(
                            NSLocalizedString(
                                "Reschedule all overdue tasks to today",
                                comment: "Button to reschedule overdue tasks"))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    VStack {
        // Warning banner
        let warningViewModel = TodoListViewModel()
        RescheduleOverdueTaskBanner(
            viewModel: warningViewModel,
            todoItems: [
                TodoItem(
                    title: "Overdue Task 1",
                    details: "This task is overdue",
                    dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    owner: Fixtures.createUser()
                ),
                TodoItem(
                    title: "Future Task",
                    details: "This task is not overdue",
                    dueDate: Date().addingTimeInterval(86400),
                    owner: Fixtures.createUser()
                ),
            ]
        )

        Divider()
            .padding(.vertical)

        // Reschedule banner
        let rescheduleViewModel = TodoListViewModel()
        RescheduleOverdueTaskBanner(
            viewModel: rescheduleViewModel,
            todoItems: [
                TodoItem(
                    title: "Overdue Task 1",
                    details: "This task is overdue",
                    dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    owner: Fixtures.createUser()
                ),
                TodoItem(
                    title: "Overdue Task 2",
                    details: "This task is also overdue",
                    dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    owner: Fixtures.createUser()
                ),
            ]
        )
    }
    .padding()
}
