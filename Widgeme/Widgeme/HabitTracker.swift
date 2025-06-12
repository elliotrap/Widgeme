import CloudKit
import Foundation

struct PositiveHabit {
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
}
