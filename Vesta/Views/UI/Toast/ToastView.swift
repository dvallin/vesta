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
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
        .shadow(radius: 10)
        .transition(.opacity)
        .animation(.easeInOut, value: message)
    }
}
