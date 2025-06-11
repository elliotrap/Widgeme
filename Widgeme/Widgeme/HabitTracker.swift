import CloudKit
import Foundation

struct HabitRecord {
    let id: CKRecord.ID
    let date: Date
    let completed: Bool
}

class HabitTracker: ObservableObject {
    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }

    @Published var records: [HabitRecord] = []

    init(container: CKContainer = .default()) {
        self.container = container
    }

    func mark(date: Date, completed: Bool) {
        let record = CKRecord(recordType: "Habit")
        record["date"] = date as NSDate
        record["completed"] = completed as NSNumber
        database.save(record) { [weak self] record, error in
            guard let record = record, error == nil else { return }
            let item = HabitRecord(id: record.recordID, date: date, completed: completed)
            DispatchQueue.main.async {
                self?.records.append(item)
            }
        }
    }
}
