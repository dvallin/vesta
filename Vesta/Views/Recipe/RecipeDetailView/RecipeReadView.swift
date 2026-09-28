import SwiftData
import SwiftUI

struct RecipeReadView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingEditView = false
    @State private var isPresentingGenerationView = false
    @State private var showingSafari = false

    let recipe: Recipe

    var body: some View {
        ScrollView {
            RecipeContentView(recipe: recipe)

            // Source URL
            if let sourceURL = recipe.sourceURL, let url = URL(string: sourceURL) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Source", comment: "Source section header"))
                        .font(.headline)
                        .padding(.horizontal)
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                            Text(url.host ?? sourceURL)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }

            // Notes
            if !recipe.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Notes", comment: "Notes section header"))
                        .font(.headline)
                        .padding(.horizontal)
                    Text(recipe.notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        guard let currentUser = auth.currentUser else { return }
                        withAnimation {
                            recipe.toggleFavorite(currentUser: currentUser)
                        }
                        HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
                    } label: {
                        Label(
                            NSLocalizedString("Favorite", comment: "Favorite button"),
                            systemImage: recipe.isFavorite ? "heart.fill" : "heart"
                        )
                        .foregroundColor(recipe.isFavorite ? .red : .secondary)
                    }
                    if APIKeyManager.hasAPIKey {
                        Button {
                            isPresentingGenerationView = true
                        } label: {
                            Label(
                                NSLocalizedString("AI Assist", comment: "AI assist button"),
                                systemImage: "sparkles"
                            )
                        }
                    }
                    Button {
                        isPresentingEditView = true
                    } label: {
                        Label(
                            NSLocalizedString("Edit", comment: "Edit button"),
                            systemImage: "pencil"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            NavigationStack {
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(isPresented: $isPresentingGenerationView) {
            RecipeGenerationView(recipe: recipe)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let recipe = Fixtures.bolognese()
        context.insert(recipe)
        return NavigationStack {
            RecipeReadView(recipe: recipe)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
