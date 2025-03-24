import SwiftUI

struct TodayView: View {
    var body: some View {
        TodoListView(
            filterMode: .today
        )
    }
}
