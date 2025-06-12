//
//  ContentView.swift
//  Widgeme
//
//  Created by Elliot Rapp on 6/11/25.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @StateObject private var tracker = HabitTracker()
    @State private var newHabit = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("\(Date().daysLeftInYear()) days left in the year")
                    .font(.headline)

                HStack {
                    TextField("New Habit", text: $newHabit)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        tracker.addHabit(name: newHabit)
                        newHabit = ""
                    }
                    .disabled(newHabit.isEmpty)
                }

                List {
                    ForEach(tracker.habits, id: \.id) { habit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(habit.name)
                                Spacer()
                                Button("Mark Today") {
                                    tracker.mark(habit: habit, date: Date(), completed: true)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            HabitCalendarView(completionDates: tracker.completionDates(for: habit))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Positive Habits")
            .onAppear {
                tracker.fetchHabits { _ in
                    tracker.fetchAllRecords { _ in }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
