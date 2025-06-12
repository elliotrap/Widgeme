import WidgetKit
import SwiftUI

struct DaysLeftEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int
}

struct DaysLeftProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaysLeftEntry {
        DaysLeftEntry(date: .now, daysLeft: Date().daysLeftInYear())
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysLeftEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysLeftEntry>) -> Void) {
        let entry = DaysLeftEntry(date: .now, daysLeft: Date().daysLeftInYear())
        // Refresh at midnight
        let nextUpdate = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct DaysLeftWidgetEntryView: View {
    var entry: DaysLeftProvider.Entry

    var body: some View {
        VStack {
            Text("\(entry.daysLeft)")
                .font(.largeTitle)
            Text("days left in the year")
                .font(.caption)
        }
    }
}

struct DaysLeftWidget: Widget {
    let kind = "DaysLeftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaysLeftProvider()) { entry in
            DaysLeftWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Days Left")
        .description("Shows how many days are left in the year.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct WidgemeWidgetBundle: WidgetBundle {
    var body: some Widget {
        DaysLeftWidget()
        HabitProgressWidget()
    }
}
