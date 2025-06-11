import Foundation

extension Date {
    func daysLeftInYear() -> Int {
        let calendar = Calendar.current
        let current = calendar.startOfDay(for: self)
        guard let startOfNextYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: current) + 1)) else {
            return 0
        }
        return calendar.dateComponents([.day], from: current, to: startOfNextYear).day ?? 0
    }
}
