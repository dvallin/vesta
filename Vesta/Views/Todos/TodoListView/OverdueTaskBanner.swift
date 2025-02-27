import SwiftUI

struct OverdueTasksBanner: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        if viewModel.hasOverdueTasks {
            if viewModel.filterMode != .overdue {
                Button(action: viewModel.showRescheduleOverdueTasks) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("There are overdue tasks")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                }
                .padding(.top, 8)
            } else {
                Button(action: viewModel.rescheduleOverdueTasks) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Reschedule all overdue tasks to today")
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
