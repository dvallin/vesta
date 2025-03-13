import SwiftUI

struct OverdueTasksBanner: View {
    @ObservedObject var viewModel: TodoListViewModel

    let todoItems: [TodoItem]

    var body: some View {
        if viewModel.hasOverdueTasks(todoItems: todoItems) {
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
                    .background(Color.accentColor)
                }
                .padding(.top, 4)
            }
        }
    }
}
