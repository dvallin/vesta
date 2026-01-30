import SwiftUI

struct HealthScoreIndicator: View {
    let health: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundColor(healthColor)
            Text("\(health)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(healthColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(healthColor.opacity(0.15))
        .cornerRadius(8)
    }

    private var healthColor: Color {
        switch health {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}
