import SwiftUI

struct HealthScoreIndicator: View {
    let health: Int
    var isPersonalBest: Bool = false
    var isRebuilding: Bool = false
    var trend: HealthTrend = .stable

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: heartIconName)
                .font(.caption)
                .foregroundColor(healthColor)
            Text("\(health)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(healthColor)
            if isPersonalBest {
                Image(systemName: "trophy.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
            if isRebuilding {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2)
                    .foregroundColor(healthColor)
            }
            if !isRebuilding && trend != .stable {
                Image(systemName: trend.systemImage)
                    .font(.system(size: 8))
                    .foregroundColor(trendColor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(healthColor.opacity(0.15))
        .cornerRadius(8)
    }

    private var heartIconName: String {
        if isRebuilding {
            return "heart"
        }
        return "heart.fill"
    }

    private var healthColor: Color {
        if isRebuilding {
            return .gray
        }
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

    private var trendColor: Color {
        switch trend {
        case .improving:
            return .green
        case .stable:
            return .secondary
        case .declining:
            return .orange
        }
    }
}
