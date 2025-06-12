import CloudKit
import Foundation

/// Local representation of a `PositiveHabit` record in CloudKit.
/// - Fields:
///   - `name`: stored as a `String` in the CloudKit record.
struct PositiveHabit {
    /// Identifier of the CloudKit record.
    let id: CKRecord.ID
    /// Name of the habit. Saved in the record under the `"name"` key.
    let name: String
}

/// Local representation of a `HabitRecord` record in CloudKit.
/// - Fields:
///   - `habit`: reference to the associated `PositiveHabit` record.
///   - `date`: the day the habit was marked.
///   - `completed`: whether the habit was done on that date.
struct HabitRecord {
    /// Identifier of the CloudKit record.
    let id: CKRecord.ID
    /// Record ID of the parent `PositiveHabit`, stored under the `"habit"` key.
    let habitID: CKRecord.ID
    /// Day this record represents. Saved under the `"date"` key.
    let date: Date
    /// Completion flag saved under the `"completed"` key.
    let completed: Bool
}

class HabitTracker: ObservableObject {
    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }

    @Published var habits: [PositiveHabit] = []
    @Published var records: [HabitRecord] = []

    init(container: CKContainer = .default()) {
        self.container = container
    }

    func addHabit(name: String) {
        // Creates a `PositiveHabit` record with the single `name` field.
        let record = CKRecord(recordType: "PositiveHabit")
        // CloudKit field "name"
        record["name"] = name as NSString
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let habit = PositiveHabit(id: record.recordID, name: name)
            DispatchQueue.main.async {
                self?.habits.append(habit)
            }
        }
    }

    func mark(habit: PositiveHabit, date: Date, completed: Bool) {
        // Creates a `HabitRecord` with references to a habit and completion info.
        let record = CKRecord(recordType: "HabitRecord")
        // Reference to the parent habit saved under "habit"
        record["habit"] = CKRecord.Reference(recordID: habit.id, action: .none)
        // Day being tracked stored under "date"
        record["date"] = date as NSDate
        // Whether the habit was completed stored under "completed"
        record["completed"] = completed as NSNumber
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let item = HabitRecord(id: record.recordID, habitID: habit.id, date: date, completed: completed)
            DispatchQueue.main.async {
                self?.records.append(item)
            }
        }
    }

    func fetchHabits(completion: @escaping ([PositiveHabit]) -> Void) {
        // Retrieve all `PositiveHabit` records and populate `habits`.
        let query = CKQuery(recordType: "PositiveHabit", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] results, error in
            let habits = results?.compactMap { record -> PositiveHabit? in
                guard let name = record["name"] as? String else { return nil }
                return PositiveHabit(id: record.recordID, name: name)
            } ?? []
            DispatchQueue.main.async {
                self?.habits = habits
                completion(habits)
            }
        }
    }

    func fetchRecords(for habit: PositiveHabit, completion: @escaping ([HabitRecord]) -> Void) {
        // Fetch `HabitRecord` items associated with the given habit.
        let predicate = NSPredicate(format: "habit == %@", habit.id)
        let query = CKQuery(recordType: "HabitRecord", predicate: predicate)
        database.perform(query, inZoneWith: nil) { [weak self] results, error in
            let items = results?.compactMap { record -> HabitRecord? in
                guard
                    let date = record["date"] as? Date,
                    let completed = record["completed"] as? Bool
                else { return nil }
                return HabitRecord(id: record.recordID, habitID: habit.id, date: date, completed: completed)
            } ?? []
            DispatchQueue.main.async {
                self?.records = items
                completion(items)
            }
        }
    }

    /// Fetches all HabitRecord items for every habit and stores them in ``records``.
    func fetchAllRecords(completion: @escaping ([HabitRecord]) -> Void) {
        // Convenience helper to fetch every `HabitRecord` for all habits.
        let query = CKQuery(recordType: "HabitRecord", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] results, error in
            let items = results?.compactMap { record -> HabitRecord? in
                guard
                    let date = record["date"] as? Date,
                    let completed = record["completed"] as? Bool,
                    let ref = record["habit"] as? CKRecord.Reference
                else { return nil }
                return HabitRecord(id: record.recordID, habitID: ref.recordID, date: date, completed: completed)
            } ?? []
            DispatchQueue.main.async {
                self?.records = items
                completion(items)
            }
        }
    }

    /// Returns the completion dates for the specified habit from ``records``.
    func completionDates(for habit: PositiveHabit) -> [Date] {
        records.filter { $0.habitID == habit.id && $0.completed }.map { $0.date }
    }

    /// Returns the current consecutive-day streak for the habit up to today.
    func currentStreak(for habit: PositiveHabit) -> Int {
        let completions = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        for date in completions {
            if Calendar.current.isDate(date, inSameDayAs: day) {
                streak += 1
                day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            } else if date < day {
                break
            }
        }
        return streak
    }

    /// Returns the longest streak of consecutive completions for the habit.
    func longestStreak(for habit: PositiveHabit) -> Int {
        let dates = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
        var longest = 0
        var current = 0
        var previous: Date?
        for date in dates {
            if let prev = previous,
               Calendar.current.dateComponents([.day], from: prev, to: date).day == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = date
        }
        return longest
    }
}
