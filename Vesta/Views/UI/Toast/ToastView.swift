import SwiftUI

struct ToastView: View {
    let message: String
    let undoAction: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(action: undoAction) {
                Text(NSLocalizedString("Undo", comment: "Undo button"))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.75, alignment: .leading)
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
        .shadow(radius: 10)
        .transition(.opacity)
        .animation(.easeInOut, value: message)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview("Toast Views") {
    VStack(spacing: 20) {
        // Simple toast with short message
        ToastView(
            message: "Item deleted",
            undoAction: { print("Undo delete") }
        )

        // Toast with longer message
        ToastView(
            message: "Recipe 'Spaghetti Carbonara' has been moved to trash",
            undoAction: { print("Undo recipe deletion") }
        )

        // Toast with very long message (to test wrapping)
        ToastView(
            message:
                "Multiple items have been processed and moved to different locations. This is a very long message to test text wrapping.",
            undoAction: { print("Undo multiple actions") }
        )
    }
    .padding()
}

// Preview showing toast in context with background content
#Preview("Toast in Context") {
    ZStack {
        // Background content
        VStack {
            Text("Main Content")
                .font(.title)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))

        // Toast at bottom
        VStack {
            Spacer()
            ToastView(
                message: "Changes saved successfully",
                undoAction: { print("Undo changes") }
            )
            .padding(.bottom, 20)
        }
    }
}

// Preview demonstrating the toast modifier
#Preview("Toast Modifier") {
    let messages: [ToastMessage] = [
        ToastMessage(
            id: UUID(),
            message: "First toast message",
            undoAction: { print("Undo first action") }
        ),
        ToastMessage(
            id: UUID(),
            message: "Second toast message",
            undoAction: { print("Undo second action") }
        ),
    ]

    return Text("Content View")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .toast(messages: .constant(messages))
}
