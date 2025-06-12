import WidgetKit
import SwiftUI
import CloudKit
import Widgeme

struct HabitStreakEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let streak: Int
}

struct HabitStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitStreakEntry {
        HabitStreakEntry(date: .now, habitName: "Meditation", streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitStreakEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitStreakEntry>) -> Void) {
        let tracker = HabitTracker()
        tracker.fetchHabits { habits in
            guard let habit = habits.first else {
                completion(Timeline(entries: [placeholder(in: context)], policy: .never))
                return
            }
            tracker.fetchRecords(for: habit) { _ in
                let streak = tracker.currentStreak(for: habit)
                let entry = HabitStreakEntry(date: .now, habitName: habit.name, streak: streak)
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            }
        }
    }
}

struct HabitStreakWidgetEntryView: View {
    var entry: HabitStreakProvider.Entry

    var body: some View {
        VStack {
            Text(entry.habitName)
                .font(.headline)
            Text("Streak: \(entry.streak)")
                .font(.title)
        }
        .padding()
    }
}

struct HabitStreakWidget: Widget {
    let kind = "HabitStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitStreakProvider()) { entry in
            HabitStreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Streak")
        .description("Shows your current streak for a habit.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
