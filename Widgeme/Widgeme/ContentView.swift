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
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("\(Date().daysLeftInYear()) days left in the year")
                    .font(.title2.weight(.semibold))

                HStack {
                    TextField("New Habit", text: $newHabit)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        tracker.addHabit(name: newHabit)
                        newHabit = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newHabit.isEmpty)
                }

                List {
                    ForEach(tracker.habits, id: \.id) { habit in
                        HabitRowView(habit: habit, tracker: tracker)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("Positive Habits")
            .toolbar {
                EditButton()
            }
        }
    }
}

#Preview {
    ContentView()
}
