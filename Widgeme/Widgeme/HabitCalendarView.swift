import SwiftUI

/// A small calendar-like grid showing the last four weeks of completions.
struct HabitCalendarView: View {
    /// Dates the habit was completed.
    let completionDates: [Date]
    /// Number of days to display.
    let totalDays: Int
    /// Color of the grid cells.
    let color: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    /// The range of days displayed by the grid.
    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -(totalDays - 1), to: today) ?? today
        return (0..<totalDays).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                let done = completionDates.contains { Calendar.current.isDate($0, inSameDayAs: day) }
                Circle()
                    .foregroundColor(done ? color : color.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

#Preview {
    HabitCalendarView(completionDates: [], totalDays: 28, color: .green)
}

