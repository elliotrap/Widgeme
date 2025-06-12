import CloudKit
import Foundation

struct PositiveHabit: Identifiable {
    let id: CKRecord.ID
    let name: String
}

struct HabitRecord {
    let id: CKRecord.ID
    let habitID: CKRecord.ID
    let date: Date
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
        let record = CKRecord(recordType: "PositiveHabit")
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
        let record = CKRecord(recordType: "HabitRecord")
        record["habit"] = CKRecord.Reference(recordID: habit.id, action: .none)
        record["date"] = date as NSDate
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

    /// Deletes the given habit record and removes any associated records.
    func deleteHabit(_ habit: PositiveHabit) {
        database.delete(withRecordID: habit.id) { [weak self] recordID, error in
            guard recordID != nil, error == nil else { return }
            DispatchQueue.main.async {
                self?.habits.removeAll { $0.id == habit.id }
                self?.records.removeAll { $0.habitID == habit.id }
            }
        }
    }

    /// Updates the name of the given habit.
    func updateHabit(_ habit: PositiveHabit, name: String) {
        database.fetch(withRecordID: habit.id) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            record["name"] = name as NSString
            self?.database.save(record) { record, error in
                guard record != nil, error == nil else { return }
                DispatchQueue.main.async {
                    if let index = self?.habits.firstIndex(where: { $0.id == habit.id }) {
                        self?.habits[index] = PositiveHabit(id: habit.id, name: name)
                    }
                }
            }
        }
    }
}
