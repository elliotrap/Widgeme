import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var tracker: HabitTracker

    @State private var name = ""
    @State private var days = 28
    @State private var color = "green"

    private let colors = ["red", "orange", "yellow", "green", "blue", "purple"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Habit name", text: $name)
                }
                Section(header: Text("Days")) {
                    Stepper(value: $days, in: 1...90) {
                        Text("\(days) days")
                    }
                }
                Section(header: Text("Color")) {
                    Picker("Color", selection: $color) {
                        ForEach(colors, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                                .foregroundColor(Color.from(name: option))
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        tracker.addHabit(name: name, days: days, colorName: color)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    AddHabitView(tracker: HabitTracker())
}
