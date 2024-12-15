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
            Button("Got it!", role: .cancel) { }
        } message: {
            Text(message)
                .textCase(.none)
                .multilineTextAlignment(.center)
        }
    }
} 