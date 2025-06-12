import WidgetKit
import SwiftUI
import CloudKit
import Widgeme

struct HabitProgressEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let completions: [Date]
}

struct HabitProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitProgressEntry {
        HabitProgressEntry(date: .now, habitName: "Meditation", completions: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitProgressEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitProgressEntry>) -> Void) {
        let tracker = HabitTracker()
        tracker.fetchHabits { habits in
            guard let habit = habits.first else {
                completion(Timeline(entries: [placeholder(in: context)], policy: .never))
                return
            }
            tracker.fetchRecords(for: habit) { records in
                let end = Calendar.current.startOfDay(for: Date())
                let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
                let completions = records.filter { $0.completed && $0.date >= start && $0.date <= end }
                    .map { Calendar.current.startOfDay(for: $0.date) }
                let entry = HabitProgressEntry(date: .now, habitName: habit.name, completions: completions)
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            }
        }
    }
}

struct HabitProgressWidgetEntryView: View {
    var entry: HabitProgressProvider.Entry
    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: entry.date)
        let start = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.habitName)
                .font(.headline)
            HStack(spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let done = entry.completions.contains { Calendar.current.isDate($0, inSameDayAs: day) }
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(done ? .green : .gray)
                }
            }
        }
        .padding()
    }
}

struct HabitProgressWidget: Widget {
    let kind = "HabitProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProgressProvider()) { entry in
            HabitProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Progress")
        .description("Shows your habit completions for the week.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
