import Foundation

struct ToastMessage: Identifiable {
    let id: UUID
    let message: String
    let undoAction: (() -> Void)?
}
