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
    @State private var editingHabit: PositiveHabit?
    @State private var editedName = ""

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
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                tracker.deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingHabit = habit
                                editedName = habit.name
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Positive Habits")
            .onAppear {
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
            .task {
                tracker.fetchHabits { _ in
                    tracker.fetchAllRecords { _ in }
                }
            }
            .sheet(item: $editingHabit) { habit in
                NavigationView {
                    VStack(spacing: 16) {
                        TextField("Habit Name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Edit Habit")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { editingHabit = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if let habit = editingHabit {
                                    tracker.updateHabit(habit, name: editedName)
                                }
                                editingHabit = nil
                            }
                            .disabled(editedName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }

        }


#Preview {
    ContentView()
}
