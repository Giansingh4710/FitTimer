import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [WorkoutPlan]
    @Query private var activities: [Activity]

    @State private var showExport = false
    @State private var exportType: ImportExportType?
    @State private var showImporter = false
    @State private var importType: ImportExportType?

    @State private var showError = false
    @State private var errorMessage = ""

    @State private var importObj: ImportObject? = nil // obj that has list of items to be imported from CSV file

    enum ImportExportType { case workouts, activities }

    var body: some View {
        List {
            Section("Workouts") {
                Button("Import Workout Plans") {
                    showImporter = true
                    importType = .workouts
                }
                Button("Export Workout Plans") {
                    exportType = .workouts
                    showExport = true
                }
            }

            Section("Activities") {
                Button("Import Activities") {
                    // showingActivityImporter = true
                    showImporter = true
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
            ImportPreviewView(importObject: obj)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.commaSeparatedText]) { result in
            switch result {
            case let .success(file):
                if importType == .workouts {
                    importWorkouts(from: file)
                } else if importType == .activities {
                    importActivities(from: file)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
        .fileExporter(isPresented: $showExport,
                      document: exportType == .workouts ?
                          CSVFile(initialText: exportWorkoutsCSV()) :
                          CSVFile(initialText: exportActivitiesCSV()),
                      contentType: .commaSeparatedText, defaultFilename: exportType == .workouts ? "workouts.csv" : "activities.csv")
        { result in
            if case .success = result {
                print("Saved successfully")
            }
        }
    }

    func dateToUnix(_ date: Date) -> String {
        return String(Int(date.timeIntervalSince1970))
    }

    func unixToDate(_ unix: String) -> Date {
        return Date(timeIntervalSince1970: Double(unix) ?? 0)
    }

    func dateComponentsToString(_ components: DateComponents) -> String {
        return "\(components.hour ?? 0)#\(components.minute ?? 0)"
    }

    func stringToDateComponents(_ str: String) -> DateComponents {
        let parts = str.split(separator: "#")
        var components = DateComponents()
        components.hour = Int(parts[0]) ?? 0
        components.minute = Int(parts[1]) ?? 0
        return components
    }

    private func exportWorkoutsCSV() -> String {
        var csv = "Name,CreatedAt,Notifications,CompletedHistory,Exercises\n"
        for workout in workouts {
            let notificationsStr = workout.notifications.map { dateComponentsToString($0) }.joined(separator: ";")
            let historyStr = workout.completedHistory.map { dateToUnix($0) }.joined(separator: ";")
            let exercisesStr = workout.exercises.map { "\($0.name)#\($0.duration)#\($0.rest)" }.joined(separator: ";")

            csv += "\(workout.name),\(dateToUnix(workout.createdAt)),\(notificationsStr),\(historyStr),\(exercisesStr)\n"
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

            importObj = ImportObject(type: "Workouts", items: [])
            for (index, row) in rows.enumerated() {
                let cols = row.components(separatedBy: ",")
                if index == 0 {
                    if cols[0] != "Name" || cols[1] != "CreatedAt" || cols[2] != "Notifications" || cols[3] != "CompletedHistory" || cols[4] != "Exercises" {
                        showError = true
                        errorMessage = "Wrong Header Row. Expected Name,CreatedAt,Notifications,CompletedHistory,Exercises"
                        importObj = nil
                        return
                    }
                    continue
                } else if cols.count == 1 {
                    continue // empty newline row
                } else if cols.count < 5 {
                    showError = true
                    errorMessage = "Invalid CSV. Expected at least 5 columns but got \(cols.count) cols in row \(index + 1)"
                    importObj = nil
                    return
                }
                let name = cols[0]
                let exercises = cols[4].split(separator: ";").map { "\($0.split(separator: "#")[0])" }.joined(separator: ", ")
                let details = """
                Created: \(unixToDate(cols[1]).formatted())
                Exercises: \(exercises)
                Notifications: \(cols[2])
                Completed History: \(cols[3])
                """
                importObj?.items.append(
                    ImportItem(name: name, details: details, createItem: { context in
                        let notifications = cols[2].split(separator: ";")
                            .map { stringToDateComponents(String($0)) }
                        let completedHistory = cols[3].split(separator: ";")
                            .map { unixToDate(String($0)) }
                        let exercises = cols[4].split(separator: ";").map { exerciseStr -> Exercise in
                            let parts = exerciseStr.split(separator: "#")
                            return Exercise(name: String(parts[0]),
                                            duration: Int(parts[1]) ?? 0,
                                            rest: Int(parts[2]) ?? 0)
                        }

                        let workout = WorkoutPlan(name: name,
                                                  exercises: exercises,
                                                  notifications: notifications)
                        workout.createdAt = unixToDate(cols[1])
                        workout.completedHistory = completedHistory
                        context.insert(workout)
                    })
                )
            }

        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }

    private func exportActivitiesCSV() -> String {
        var csv = "Name,CreatedAt,Count,Notifications,ResetDaily,LastCounted,TodayCount,History\n"
        for activity in activities {
            let notificationsStr = activity.notifications.map { dateComponentsToString($0) }.joined(separator: ";")
            let historyStr = activity.history.map { "\(dateToUnix($0.date))#\($0.count)" }.joined(separator: ";")

            csv += "\(activity.name),\(dateToUnix(activity.createdAt)),\(activity.count),\(notificationsStr),\(activity.resetDaily),\(dateToUnix(activity.lastCounted)),\(activity.todayCount),\(historyStr)\n"
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

            importObj = ImportObject(type: "Activity", items: [])
            for (index, row) in rows.enumerated() {
                let cols = row.components(separatedBy: ",")
                if index == 0 {
                    if cols[0] != "Name" || cols[1] != "CreatedAt" || cols[2] != "Count" || cols[3] != "Notifications" || cols[4] != "ResetDaily" || cols[5] != "LastCounted" || cols[6] != "TodayCount" || cols[7] != "History" {
                        showError = true
                        errorMessage = "Wrong Header Row. Expected Name,CreatedAt,Count,Notifications,ResetDaily,LastCounted,TodayCount,History"
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

                let name = cols[0]
                let details = """
                Created: \(unixToDate(cols[1]).formatted())
                Count: \(cols[2])
                Reset Daily: \(cols[4])
                Today's Count: \(cols[6])
                """

                importObj?.items.append(
                    ImportItem(name: name, details: details, createItem: { context in
                        let notifications = cols[3].split(separator: ";").map { stringToDateComponents(String($0)) }
                        let history = cols[7].split(separator: ";").map { historyStr -> ActivityHistory in
                            let parts = historyStr.split(separator: "#")
                            return ActivityHistory(count: Int(parts[1]) ?? 0, date: unixToDate(String(parts[0])))
                        }

                        let activity = Activity(name: name,
                                                count: Int(cols[2]) ?? 0,
                                                notifications: notifications,
                                                resetDaily: Bool(cols[4]) ?? true)
                        activity.createdAt = unixToDate(cols[1])
                        activity.lastCounted = unixToDate(cols[5])
                        activity.todayCount = Int(cols[6]) ?? 0
                        activity.history = history
                        context.insert(activity)
                    })
                )
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
