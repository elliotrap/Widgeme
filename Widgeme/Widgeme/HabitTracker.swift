import CloudKit
import Foundation

/// Represents a user-defined habit stored in CloudKit.
///
/// - `id`: Unique identifier of the CloudKit record.
/// - `name`: The title of the habit, saved under the `"name"` key.
struct PositiveHabit: Identifiable {
    let id: CKRecord.ID
    let name: String
}

/// Represents a daily completion record for a `PositiveHabit` in CloudKit.
///
/// - `id`: Unique identifier of the CloudKit record.
/// - `habitID`: Reference to the parent `PositiveHabit` record.
/// - `date`: The date the habit was marked.
/// - `completed`: Whether the habit was completed on that date.
struct HabitRecord {
    let id: CKRecord.ID
    let habitID: CKRecord.ID
    let date: Date
    let completed: Bool
}

/// Manages CRUD operations for habits and their completion records using CloudKit.
class HabitTracker: ObservableObject {
    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }

    @Published var habits: [PositiveHabit] = []
    @Published var records: [HabitRecord] = []
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Initializes the tracker with a CloudKit container (default by default).
    init(container: CKContainer = .default()) {
        self.container = container
    }

    // MARK: - Account Status

    /// Checks the user's CloudKit account status and updates `accountStatus`.
    /// - Parameter completion: Callback with the current account status.
    func checkAccountStatus(completion: @escaping (CKAccountStatus) -> Void) {
        container.accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                self?.accountStatus = status
                completion(status)
            }
        }
    }

    // MARK: - Create Operations

    /// Adds a new `PositiveHabit` record to CloudKit.
    /// - Parameter name: The name of the habit to create.
    func addHabit(name: String) {
        let record = CKRecord(recordType: "PositiveHabit")
        record["name"] = name as NSString
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let habit = PositiveHabit(id: record.recordID, name: name)
            DispatchQueue.main.async { self?.habits.append(habit) }
        }
    }

    /// Creates a completion entry for a given habit on a specific date.
    /// - Parameters:
    ///   - habit: The habit being marked.
    ///   - date: The date of completion.
    ///   - completed: Flag indicating completion status.
    func mark(habit: PositiveHabit, date: Date, completed: Bool) {
        let record = CKRecord(recordType: "HabitRecord")
        record["habit"] = CKRecord.Reference(recordID: habit.id, action: .none)
        record["date"] = date as NSDate
        record["completed"] = completed as NSNumber
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let entry = HabitRecord(
                id: record.recordID,
                habitID: habit.id,
                date: date,
                completed: completed
            )
            DispatchQueue.main.async { self?.records.append(entry) }
        }
    }

    // MARK: - Read Operations

    /// Fetches all habits from CloudKit.
    /// - Parameter completion: Callback with the fetched habits.
    func fetchHabits(completion: @escaping ([PositiveHabit]) -> Void) {
        let query = CKQuery(recordType: "PositiveHabit", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            let list = results?.compactMap { record -> PositiveHabit? in
                guard let name = record["name"] as? String else { return nil }
                return PositiveHabit(id: record.recordID, name: name)
            } ?? []
            DispatchQueue.main.async {
                self?.habits = list
                completion(list)
            }
        }
    }

    /// Fetches all completion records for a specific habit.
    /// - Parameters:
    ///   - habit: The habit whose records to fetch.
    ///   - completion: Callback with the fetched records.
    func fetchRecords(for habit: PositiveHabit, completion: @escaping ([HabitRecord]) -> Void) {
        let predicate = NSPredicate(format: "habit == %@", habit.id)
        let query = CKQuery(recordType: "HabitRecord", predicate: predicate)
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            let entries = results?.compactMap { record -> HabitRecord? in
                guard
                    let date = record["date"] as? Date,
                    let completed = record["completed"] as? Bool
                else { return nil }
                return HabitRecord(
                    id: record.recordID,
                    habitID: habit.id,
                    date: date,
                    completed: completed
                )
            } ?? []
            DispatchQueue.main.async {
                self?.records = entries
                completion(entries)
            }
        }
    }

    /// Fetches every habit completion record regardless of habit.
    /// - Parameter completion: Callback with the fetched records.
    func fetchAllRecords(completion: @escaping ([HabitRecord]) -> Void) {
        let query = CKQuery(recordType: "HabitRecord", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            let entries = results?.compactMap { record -> HabitRecord? in
                guard
                    let date = record["date"] as? Date,
                    let completed = record["completed"] as? Bool,
                    let ref = record["habit"] as? CKRecord.Reference
                else { return nil }
                return HabitRecord(
                    id: record.recordID,
                    habitID: ref.recordID,
                    date: date,
                    completed: completed
                )
            } ?? []
            DispatchQueue.main.async {
                self?.records = entries
                completion(entries)
            }
        }
    }

    // MARK: - Utility Methods

    /// Returns the dates on which a habit was completed.
    func completionDates(for habit: PositiveHabit) -> [Date] {
        records
            .filter { $0.habitID == habit.id && $0.completed }
            .map { $0.date }
    }

    /// Calculates the current consecutive-day streak up to today.
    func currentStreak(for habit: PositiveHabit) -> Int {
        let days = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        for recordDay in days {
            if Calendar.current.isDate(recordDay, inSameDayAs: day) {
                streak += 1
                day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            } else if recordDay < day {
                break
            }
        }
        return streak
    }

    /// Calculates the longest consecutive-day streak ever achieved.
    func longestStreak(for habit: PositiveHabit) -> Int {
        let days = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
        var longest = 0, current = 0
        var previous: Date?
        for recordDay in days {
            if let prev = previous,
               Calendar.current.dateComponents([.day], from: prev, to: recordDay).day == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = recordDay
        }
        return longest
    }

    // MARK: - Update & Delete

    /// Updates the name of an existing habit in CloudKit.
    /// - Parameters:
    ///   - habit: The habit to rename.
    ///   - name: The new name to assign.
    func updateHabit(_ habit: PositiveHabit, name: String) {
        database.fetch(withRecordID: habit.id) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            record["name"] = name as NSString
            self?.database.save(record) { saved, err in
                guard saved != nil, err == nil else { return }
                DispatchQueue.main.async {
                    if let index = self?.habits.firstIndex(where: { $0.id == habit.id }) {
                        self?.habits[index] = PositiveHabit(id: habit.id, name: name)
                    }
                }
            }
        }
    }

    /// Deletes a habit and all its associated completion records from CloudKit.
    /// - Parameter habit: The habit to remove.
    func deleteHabit(_ habit: PositiveHabit) {
        // Remove the habit record
        database.delete(withRecordID: habit.id) { [weak self] _, error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                self?.habits.removeAll { $0.id == habit.id }
                self?.records.removeAll { $0.habitID == habit.id }
            }
        }

        // Remove dependent records
        let predicate = NSPredicate(format: "habit == %@", habit.id)
        let query = CKQuery(recordType: "HabitRecord", predicate: predicate)
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            results?.forEach { record in
                self?.database.delete(withRecordID: record.recordID) { _, _ in }
            }
        }
    }
}