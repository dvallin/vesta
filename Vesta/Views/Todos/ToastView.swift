import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(radius: 10)
            .transition(.opacity)
            .animation(.easeInOut, value: message)
    }
}
