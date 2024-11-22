import SwiftUI

struct CalendarDetailView: View {
    @Binding var activityLogs: [ActivityLog]
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                if let log = activityLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                    List {
                        ForEach(log.activities) { activity in
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                Text("Count: \(activity.count)")
                                    .font(.subheadline)
                            }
                        }
                    }
                } else {
                    Text("No activities logged for this day.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: exportData) {
                    Text("Export Data")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Activity Calendar")
        }
    }

    private func exportData() {
        // Convert activity logs to a CSV or JSON format
        let exportString = activityLogs.map { log in
            let dateString = DateFormatter.localizedString(from: log.date, dateStyle: .short, timeStyle: .none)
            let activitiesString = log.activities.map { "\($0.name): \($0.count)" }.joined(separator: ", ")
            return "\(dateString): \(activitiesString)"
        }.joined(separator: "\n")

        // Share the export string
        let activityViewController = UIActivityViewController(activityItems: [exportString], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
} 