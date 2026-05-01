import SwiftUI

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingTodoItemUID: String? = nil

    private init() {}
}
