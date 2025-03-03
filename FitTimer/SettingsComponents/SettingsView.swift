import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query private var the_workouts: [WorkoutPlan]
    @Query private var the_activities: [Activity]

    @State private var showExport = false
    @State private var exportType: MainAppItems?
    @State private var showImport = false
    @State private var importType: MainAppItems?

    @State private var showError = false
    @State private var errorMessage = ""

    @State private var importObj: ImportObject? = nil // obj that has list of items to be imported from CSV file

    var body: some View {
        List {
            Section("Workouts") {
                Button("Import Workout Plans") {
                    showImport = true
                    importType = .workout_plans
                }
                Button("Export Workout Plans") {
                    exportType = .workout_plans
                    showExport = true
                }
            }

            Section("Activities") {
                Button("Import Activities") {
                    // showingActivityImporter = true
                    showImport = true
                    importType = .activities
                }
                Button("Export Activities") {
                    exportType = .activities
                    showExport = true
                }
            }
        }

        .navigationTitle("Settings")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $importObj) { obj in
            ImportPreviewView(importObject: Binding(
                get: { obj },
                set: { newValue in
                    importObj = newValue
                }
            ))
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [UTType.commaSeparatedText]) { result in
            switch result {
            case let .success(file):
                if importType == .workout_plans {
                    importWorkouts(from: file)
                } else if importType == .activities {
                    importActivities(from: file)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
        .fileExporter(isPresented: $showExport,
                      document: exportType == .workout_plans ?
                          CSVFile(initialText: exportWorkoutsCSV()) :
                          CSVFile(initialText: exportActivitiesCSV()),
                      contentType: .commaSeparatedText, defaultFilename: exportType == .workout_plans ? "workouts.csv" : "activities.csv")
        { result in
            if case .success = result {
                print("Saved successfully")
            }
        }
    }

    func dateToUnix(_ date: Date) -> String { return String(Int(date.timeIntervalSince1970)) }
    func unixToDate(_ unix: String) -> Date { return Date(timeIntervalSince1970: Double(unix) ?? 0) }
    func dateComponentsToString(_ components: DateComponents) -> String { return "\(components.hour ?? 0)#\(components.minute ?? 0)" }

    func stringToDateComponents(_ str: String) -> DateComponents {
        let parts = str.split(separator: "#")
        var components = DateComponents()
        components.hour = Int(parts[0]) ?? 0
        components.minute = Int(parts[1]) ?? 0
        return components
    }

    private func escapeCSVField(_ field: String) -> String {
        var escaped = field.replacingOccurrences(of: "\"", with: "\"\"") // Escape double quotes
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains(";") {
            escaped = "\"\(escaped)\"" // Wrap in quotes if it contains special characters
        }
        return escaped
    }

    private func exportWorkoutsCSV() -> String {
        var csv = "id,createdAt,completedHistory,name,notifications,exercises,notificationText"
        for workout in the_workouts {
            let notifications = workout.notifications.map { dateComponentsToString($0) }.joined(separator: ";")
            let completedHistory = workout.completedHistory.map { dateToUnix($0) }.sorted().map { String($0) }.joined(separator: ";")
            let exercises = workout.exercises.map { "\($0.name)#\($0.duration)#\($0.rest)" }.joined(separator: ";")

            let notificationText = escapeCSVField(workout.notificationText.title + ";" + workout.notificationText.body)

            csv += "\n\(workout.id.uuidString),\(dateToUnix(workout.createdAt)),\(completedHistory),\(workout.name),\(notifications),\(exercises),\(notificationText)"
        }
        return csv
    }

    private func importWorkouts(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            if rows.isEmpty {
                showError = true
                errorMessage = "No valid workouts found in CSV"
                return
            }

            importObj = ImportObject(type: "workouts", items: [])
            for (index, row) in rows.enumerated() {
                let cols = row.components(separatedBy: ",")
                if index == 0 {
                    if cols.count < 7 {
                        showError = true
                        errorMessage = "Invalid CSV. Expected at least 7 columns but got \(cols.count) cols in row \(index + 1).\n Got: \(row)"
                        importObj = nil
                        return
                    }
                    if cols[0] != "id" || cols[1] != "createdAt" || cols[2] != "completedHistory" || cols[3] != "name" || cols[4] != "notifications" || cols[5] != "exercises" || cols[6] != "notificationText" {
                        showError = true
                        errorMessage = "Wrong Header Row. Expected Name,CreatedAt,Notifications,CompletedHistory,Exercises"
                        importObj = nil
                        return
                    }
                    continue
                } else if cols.count == 1 { continue // empty newline row
                } else if cols.count < 6 {
                    showError = true
                    errorMessage = "Invalid CSV. Expected at least 6 columns but got \(cols.count) cols in row \(index + 1)"
                    importObj = nil
                    return
                }

                let exercises = cols[5].split(separator: ";").map { exerciseStr -> Exercise in
                    let parts = exerciseStr.split(separator: "#")
                    return Exercise(name: String(parts[0]), duration: Int(parts[1]) ?? 0, rest: Int(parts[2]) ?? 0)
                }
                let notificationTextLst = cols[6] == "" ? ["", ""] : cols[6].split(separator: ";")

                let workout = WorkoutPlan(
                    id: UUID(uuidString: cols[0]) ?? UUID(),
                    createdAt: unixToDate(cols[1]),
                    completedHistory: cols[2] == "" ? [] : cols[2].split(separator: ";").map { unixToDate(String($0)) },
                    name: cols[3],
                    notifications: cols[4] == "" ? [] : cols[4].split(separator: ";").map { stringToDateComponents(String($0)) },
                    exercises: exercises,
                    notificationText: NotificationTextData(title: String(notificationTextLst[0]), body: String(notificationTextLst[1]))
                )
                importObj?.items.append(.workoutPlan(workout))
            }

        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }

    private func exportActivitiesCSV() -> String {
        var csv = "id,name,count,notifications,resetDaily,createdAt,history,notificationText"
        for activity in the_activities {
            if activity.todayCount != 0 {
                activity.history.append(ActivityHistory(count: activity.todayCount, date: activity.lastCounted))
            }
            let notificationsStr = activity.notifications.map { dateComponentsToString($0) }.joined(separator: ";")
            let sortedHistoryStr = activity.history
                .map { (dateToUnix($0.date), $0.count) } // Map to tuple (UnixTime, count)
                .sorted { $0.0 < $1.0 } // Sort by Unix time (first element of tuple)
                .map { "\($0.0)#\($0.1)" } // Convert back to string format
                .joined(separator: ";") // Join with semicolon

            let notificationText = escapeCSVField(activity.notificationText.title + ";" + activity.notificationText.body)
            csv += "\n\(activity.id.uuidString),\(activity.name),\(activity.count),\(notificationsStr),\(activity.resetDaily),\(dateToUnix(activity.createdAt)),\(sortedHistoryStr),\(notificationText)"
            if activity.todayCount != 0 {
                activity.history.removeLast()
            }
        }
        return csv
    }

    private func importActivities(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        importObj = nil
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            if rows.isEmpty {
                showError = true
                errorMessage = "No Rows found in CSV"
                return
            }

            importObj = ImportObject(type: "activities", items: [])
            for (index, row) in rows.enumerated() {
                let cols = row.components(separatedBy: ",")
                if index == 0 {
                    if cols.count < 8 {
                        showError = true
                        errorMessage = "Invalid CSV. Expected at least 8 columns but got \(cols.count) cols in row \(index + 1).\n Got: \(rows)"
                        importObj = nil
                        return
                    }

                    if cols[0] != "id" || cols[1] != "name" || cols[2] != "count" || cols[3] != "notifications" || cols[4] != "resetDaily" || cols[5] != "createdAt" || cols[6] != "history" || cols[7] != "notificationText" {
                        showError = true
                        errorMessage = "Wrong Header Row. Expected id,name,count,notifications,resetDaily,createdAt,history,notificationText"
                        importObj = nil
                        return
                    }
                    continue
                } else if cols.count == 1 {
                    continue // empty newline row
                } else if cols.count < 8 {
                    showError = true
                    errorMessage = "Invalid CSV. Expected at least 8 columns but got \(cols.count) cols in row \(index + 1)"
                    importObj = nil
                    return
                }

                let history: [ActivityHistory] = cols[6].isEmpty ? [] : cols[6].split(separator: ";").map { historyStr -> ActivityHistory in
                    let parts = historyStr.split(separator: "#")
                    return ActivityHistory(
                        count: Int(parts[1]) ?? 0,
                        date: unixToDate(String(parts[0]))
                    )
                }
                let notificationTextLst = cols[7].isEmpty ? ["", ""] : cols[7].split(separator: ";")

                let activity = Activity(
                    id: UUID(uuidString: cols[0]) ?? UUID(),
                    name: cols[1] == "" ? "New Activity" : cols[1],
                    count: Int(cols[2]) ?? 0,
                    notifications: cols[3].isEmpty ? [] : cols[3].split(separator: ";").map { stringToDateComponents(String($0)) },
                    resetDaily: Bool(cols[4]) ?? true,
                    createdAt: unixToDate(cols[5]),
                    history: history,
                    notificationText: NotificationTextData(title: String(notificationTextLst[0]), body: String(notificationTextLst[1]))
                )
                importObj?.items.append(.activity(activity))
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct CSVFile: FileDocument {
    static var readableContentTypes = [UTType.commaSeparatedText]
    var text: String

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
