import SwiftUI
import CloudKit

struct HabitRowView: View {
    let habit: PositiveHabit
    @ObservedObject var tracker: HabitTracker

    private var completions: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        return tracker.records
            .filter { $0.habitID == habit.id && $0.completed && $0.date >= start && $0.date <= today }
            .map { Calendar.current.startOfDay(for: $0.date) }
    }

    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
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

            HStack(spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let done = completions.contains { Calendar.current.isDate($0, inSameDayAs: day) }
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(done ? .green : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HabitRowView(habit: PositiveHabit(id: CKRecord.ID(recordName: "1"), name: "Test"), tracker: HabitTracker())
}
