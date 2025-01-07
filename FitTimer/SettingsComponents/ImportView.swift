import SwiftData
import SwiftUI

struct ImportObject: Identifiable {
    let id = UUID()
    let type: String
    var items: [ImportItem]
}

struct ImportItem {
    let name: String
    let details: String
    let createItem: (ModelContext) -> Void
}

struct ImportPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    let importObject: ImportObject

    @State private var currentIndex = 0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("\(currentIndex + 1)/\(importObject.items.count) \(importObject.type)")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name: \(importObject.items[currentIndex].name)")
                        .font(.title3)
                    Text("Details:")
                        .font(.subheadline)
                    Text(importObject.items[currentIndex].details)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                HStack(spacing: 20) {
                    Button("Skip") {
                        moveToNext()
                    }
                    .buttonStyle(.bordered)

                    Button("Import") {
                        importObject.items[currentIndex].createItem(modelContext)
                        moveToNext()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Import Preview")
            .toolbar {
                ToolbarItem {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func moveToNext() {
        if currentIndex < importObject.items.count - 1 {
            currentIndex += 1
        } else {
            dismiss()
        }
    }
}
