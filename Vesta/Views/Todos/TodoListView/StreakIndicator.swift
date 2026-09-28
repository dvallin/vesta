import SwiftUI

struct StreakIndicator: View {
    let streak: Int
    var isPersonalBest: Bool = false

    var body: some View {
        if streak > 0 {
            HStack(spacing: 3) {
                Image(systemName: flameIcon)
                    .font(.caption)
                    .foregroundStyle(flameGradient)
                Text("\(streak)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(streakColor)
                if isPersonalBest && streak >= 3 {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(streakBackground)
            .cornerRadius(8)
        }
    }

    private var flameIcon: String {
        if streak >= 15 {
            return "flame.fill"
        } else if streak >= 3 {
            return "flame.fill"
        } else {
            return "flame"
        }
    }

    private var flameGradient: some ShapeStyle {
        switch streak {
        case 15...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        case 7...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        case 3...:
            return AnyShapeStyle(Color.orange)
        default:
            return AnyShapeStyle(Color.secondary)
        }
    }

    private var streakColor: Color {
        switch streak {
        case 15...:
            return .red
        case 7...:
            return .orange
        case 3...:
            return .orange
        default:
            return .secondary
        }
    }

    private var streakBackground: some View {
        Group {
            switch streak {
            case 15...:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.12))
            case 7...:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.12))
            case 3...:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.08))
            default:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            }
        }
    }
}

#Preview("Streak Levels") {
    VStack(spacing: 12) {
        StreakIndicator(streak: 1)
        StreakIndicator(streak: 2)
        StreakIndicator(streak: 3)
        StreakIndicator(streak: 5, isPersonalBest: true)
        StreakIndicator(streak: 7)
        StreakIndicator(streak: 10, isPersonalBest: true)
        StreakIndicator(streak: 15)
        StreakIndicator(streak: 21, isPersonalBest: true)
        StreakIndicator(streak: 50)
    }
    .padding()
}
