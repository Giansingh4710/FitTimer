import SwiftUI

struct InfoButton: View {
    let title: String
    let message: String
    @State private var showingInfo = false

    var body: some View {
        Button(action: { showingInfo = true }) {
            Image(systemName: "info.circle")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .opacity(0.7)
        }
        .alert(title, isPresented: $showingInfo) {
            Button("Got it!", role: .cancel) {}
        } message: {
            Text(message)
                .textCase(.none)
                .multilineTextAlignment(.center)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
