import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        FloatingAddButton {
            print("Add button tapped")
        }
    }
}

#Preview("Button Only") {
    FloatingAddButton {
        print("Add button tapped")
    }
    .padding()
}

#Preview("Dark Mode") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        FloatingAddButton {
            print("Add button tapped")
        }
    }
    .preferredColorScheme(.dark)
}
