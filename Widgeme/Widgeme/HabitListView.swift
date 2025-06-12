import SwiftUI

struct HabitListView: View {
    @ObservedObject var tracker: HabitTracker
    @State private var newHabit = ""
    @State private var editingHabit: PositiveHabit?
    @State private var editedName = ""

    var body: some View {
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
}

#Preview {
    HabitListView(tracker: HabitTracker())
}
