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

    // MARK: – Create
    func addHabit(name: String) {
        let record = CKRecord(recordType: "PositiveHabit")
        record["name"] = name as NSString
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let habit = PositiveHabit(id: record.recordID, name: name)
            DispatchQueue.main.async { self?.habits.append(habit) }
        }
    }

    func mark(habit: PositiveHabit, date: Date, completed: Bool) {
        let record = CKRecord(recordType: "HabitRecord")
        record["habit"] = CKRecord.Reference(recordID: habit.id, action: .none)
        record["date"] = date as NSDate
        record["completed"] = completed as NSNumber
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let item = HabitRecord(
                id: record.recordID,
                habitID: habit.id,
                date: date,
                completed: completed
            )
            DispatchQueue.main.async { self?.records.append(item) }
        }
    }

    // MARK: – Read
    func fetchHabits(completion: @escaping ([PositiveHabit]) -> Void) {
        let query = CKQuery(recordType: "PositiveHabit", predicate: .init(value: true))
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

    func fetchRecords(for habit: PositiveHabit,
                      completion: @escaping ([HabitRecord]) -> Void) {
        let pred = NSPredicate(format: "habit == %@", habit.id)
        let query = CKQuery(recordType: "HabitRecord", predicate: pred)
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            let items = results?.compactMap { record -> HabitRecord? in
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
                self?.records = items
                completion(items)
            }
        }
    }

    func fetchAllRecords(completion: @escaping ([HabitRecord]) -> Void) {
        let query = CKQuery(recordType: "HabitRecord", predicate: .init(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            let items = results?.compactMap { record -> HabitRecord? in
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
                self?.records = items
                completion(items)
            }
        }
    }

    // MARK: – Utilities
    func completionDates(for habit: PositiveHabit) -> [Date] {
        records
            .filter { $0.habitID == habit.id && $0.completed }
            .map { $0.date }
    }

    func currentStreak(for habit: PositiveHabit) -> Int {
        let days = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        for date in days {
            if Calendar.current.isDate(date, inSameDayAs: day) {
                streak += 1
                day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            } else if date < day {
                break
            }
        }
        return streak
    }

    func longestStreak(for habit: PositiveHabit) -> Int {
        let days = completionDates(for: habit)
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
        var longest = 0, current = 0
        var previous: Date?
        for date in days {
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

    // MARK: – Update & Delete
    func updateHabit(_ habit: PositiveHabit, name: String) {
        database.fetch(withRecordID: habit.id) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            record["name"] = name as NSString
            self?.database.save(record) { saved, err in
                guard saved != nil, err == nil else { return }
                DispatchQueue.main.async {
                    if let idx = self?.habits.firstIndex(where: { $0.id == habit.id }) {
                        self?.habits[idx] = PositiveHabit(id: habit.id, name: name)
                    }
                }
            }
        }
    }

    func deleteHabit(_ habit: PositiveHabit) {
        // Delete the habit record
        database.delete(withRecordID: habit.id) { [weak self] _, error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                self?.habits.removeAll { $0.id == habit.id }
                self?.records.removeAll { $0.habitID == habit.id }
            }
        }

        // Also remove any associated HabitRecord entries
        let pred = NSPredicate(format: "habit == %@", habit.id)
        let query = CKQuery(recordType: "HabitRecord", predicate: pred)
        database.perform(query, inZoneWith: nil) { [weak self] results, _ in
            results?.forEach { record in
                self?.database.delete(withRecordID: record.recordID) { _, _ in }
            }
        }
    }
}
