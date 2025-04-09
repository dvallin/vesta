import Combine
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userService: UserService

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Login Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)

                    if isSignUp {
                        TextField("Display Name", text: $displayName)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(isSignUp ? "Sign Up" : "Sign In") {
                        if isSignUp {
                            signUp()
                        } else {
                            signIn()
                        }
                    }
                    .disabled(userService.isAuthenticating)

                    if userService.isAuthenticating {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }

                Section {
                    Button(
                        isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up"
                    ) {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
        }
    }

    private func signIn() {
        errorMessage = nil

        userService.signIn(email: email, password: password)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func signUp() {
        errorMessage = nil

        userService.signUp(email: email, password: password, displayName: displayName)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
