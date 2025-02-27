import SwiftUI

struct OverdueTasksBanner: View {
    let hasOverdueTasks: Bool
    let filterMode: FilterMode
    var showRescheduleOverdueTasks: () -> Void
    var rescheduleOverdueTasks: () -> Void

    var body: some View {
        if hasOverdueTasks {
            if filterMode != .overdue {
                Button(action: showRescheduleOverdueTasks) {
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
                Button(action: rescheduleOverdueTasks) {
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
