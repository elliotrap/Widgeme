import WidgetKit
import SwiftUI
import CloudKit
import Widgeme

struct HabitCount: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct HabitCompletionCountEntry: TimelineEntry {
    let date: Date
    let counts: [HabitCount]
}

struct HabitCompletionCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitCompletionCountEntry {
        HabitCompletionCountEntry(date: .now, counts: [HabitCount(name: "Meditation", count: 10)])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitCompletionCountEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitCompletionCountEntry>) -> Void) {
        let tracker = HabitTracker()
        tracker.fetchHabits { habits in
            tracker.fetchAllRecords { records in
                let counts = habits.map { habit in
                    let total = records.filter { $0.habitID == habit.id && $0.completed }.count
                    return HabitCount(name: habit.name, count: total)
                }
                let entry = HabitCompletionCountEntry(date: .now, counts: counts)
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            }
        }
    }
}

struct HabitCompletionCountWidgetEntryView: View {
    var entry: HabitCompletionCountProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.counts.prefix(3)) { item in
                HStack {
                    Text(item.name)
                        .font(.headline)
                    Spacer()
                    Text("\(item.count)")
                        .bold()
                }
            }
        }
        .padding()
    }
}

struct HabitCompletionCountWidget: Widget {
    let kind = "HabitCompletionCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitCompletionCountProvider()) { entry in
            HabitCompletionCountWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Totals")
        .description("Shows how many days you've completed each habit.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
