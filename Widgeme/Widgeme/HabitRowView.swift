import SwiftUI
import CloudKit

struct HabitRowView: View {
    let habit: PositiveHabit
    @ObservedObject var tracker: HabitTracker

    private var completions: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -(habit.days - 1), to: today) ?? today
        return tracker.records
            .filter { $0.habitID == habit.id && $0.completed && $0.date >= start && $0.date <= today }
            .map { Calendar.current.startOfDay(for: $0.date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.name)
                    .font(.headline)
                Spacer()
                Button {
                    tracker.mark(habit: habit, date: Date(), completed: true)
                } label: {
                    Label("Mark Today", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }

            HabitCalendarView(
                completionDates: completions,
                totalDays: habit.days,
                color: Color.from(name: habit.colorName)
            )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HabitRowView(
        habit: PositiveHabit(id: CKRecord.ID(recordName: "1"), name: "Test", days: 28, colorName: "green"),
        tracker: HabitTracker()
    )
}
