import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var messages: [ToastMessage]
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                Spacer()
                ForEach(messages) { toastMessage in
                    ToastView(message: toastMessage.message, undoAction: toastMessage.undoAction)
                        .padding(.bottom, 10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    messages.removeAll { $0.id == toastMessage.id }
                                }
                            }
                        }
                }
            }
        }
    }
}

extension View {
    func toast(messages: Binding<[ToastMessage]>, duration: TimeInterval = 10) -> some View {
        self.modifier(ToastModifier(messages: messages, duration: duration))
    }
}
