import SwiftUI

struct StatsView: View {
    @ObservedObject var tracker: HabitTracker

    var body: some View {
        List {
            Section(header: Text("Habits")) {
                ForEach(tracker.habits, id: \.id) { habit in
                    let streak = tracker.currentStreak(for: habit)
                    let longest = tracker.longestStreak(for: habit)
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.headline)
                        HStack {
                            Text("Current Streak: \(streak)")
                            Spacer()
                            Text("Longest: \(longest)")
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Statistics")
        .onAppear {
            tracker.fetchHabits { _ in
                tracker.fetchAllRecords { _ in }
            }
        }
    }
}

#Preview {
    StatsView(tracker: HabitTracker())
}
