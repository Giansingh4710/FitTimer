import SwiftUI

struct AddNotificationView: View {
    @Binding var numberOfRandomTimes: String
    @Binding var notificationTimes: [DateComponents]

    @FocusState private var isNumberInputFocused: Bool
    @State private var showAlert: Bool = false

    var body: some View {
        Section(header:
            HStack {
                Text("Notification Times")
                InfoButton(
                    title: "🕒 Notification Times",
                    message: "Notifications will repeat daily at these times"
                )
            }
        ) {
            HStack {
                TextField("Enter number (max 100)", text: $numberOfRandomTimes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNumberInputFocused)
                    .submitLabel(.done)
                Button(action: {
                    generateRandomTimes()
                }) {
                    Label("Generate", systemImage: "dice.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 5)
            Text("Tap generate to create random times")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(notificationTimes.indices, id: \.self) { index in
                let date = Calendar.current.date(from: notificationTimes[index]) ?? Date()
                DatePicker("Time \(index + 1)", selection: Binding(
                    get: { date },
                    set: { newDate in
                        notificationTimes[index] = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                    }
                ), displayedComponents: .hourAndMinute)
            }
            .onDelete(perform: deleteNotificationTime)

            Button(action: {
                notificationTimes.append(Calendar.current.dateComponents([.hour, .minute], from: Date()))
            }) {
                Label("Add Notification Time", systemImage: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .alert("Invalid Input", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a number between 1 and 100")
        }
    }

    func generateRandomTimes() {
        guard let count = Int(numberOfRandomTimes), count > 0, count <= 100 else {
            showAlert = true
            return
        }

        isNumberInputFocused = false

        // Clear existing times
        notificationTimes.removeAll()

        // Generate random times between 8 AM and 10 PM
        let calendar = Calendar.current
        var date = Date()
        date = calendar.startOfDay(for: date)

        // Set base date to 8 AM
        date = calendar.date(byAdding: .hour, value: 8, to: date) ?? date

        // Calculate seconds between 8 AM and 10 PM (14 hours)
        let secondsInRange = 14 * 60 * 60

        // Generate unique random times
        var usedMinutes = Set<Int>()

        while notificationTimes.count < count {
            let randomSeconds = Int.random(in: 0 ..< secondsInRange)
            let totalMinutes = randomSeconds / 60

            if !usedMinutes.contains(totalMinutes) {
                usedMinutes.insert(totalMinutes)

                if let newTime = calendar.date(byAdding: .second, value: randomSeconds, to: date) {
                    let components = calendar.dateComponents([.hour, .minute], from: newTime)
                    notificationTimes.append(components)
                }
            }
        }

        // Sort times chronologically
        notificationTimes.sort { components1, components2 in
            let calendar = Calendar.current
            let date1 = calendar.date(from: components1) ?? Date()
            let date2 = calendar.date(from: components2) ?? Date()
            return date1 < date2
        }

        // Clear the input field
        // numberOfRandomTimes = ""
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }
}
