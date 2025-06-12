Widgeme

This project is a simple SwiftUI application showcasing multiple widgets. The first widget counts down the days left in the year. A second Habit Progress widget displays your positive habit completions for the current week. A third Habit Totals widget shows how many days you’ve completed each habit overall. A fourth Habit Streak widget displays your current streak. The app also includes a small HabitTracker class which can store daily check-ins using CloudKit.

App UI

The main app now uses a bottom tab bar with separate views for managing your habits and viewing summary statistics. Each tab is wrapped in a navigation view so the title is displayed at the top while the tab bar provides quick access to different sections.

Widget
	•	DaysLeftWidget: Displays the remaining days in the current year and refreshes automatically every day.
	•	HabitProgressWidget: Shows a single habit with checkmarks for the last seven days so you can glance at your recent streaks right from the home screen.
	•	HabitCompletionCountWidget: Lists your habits with the total number of days you’ve marked them complete.
	•	HabitStreakWidget: Shows your current streak for one habit.

Habit Tracking

HabitTracker provides a starting point for storing completed days in CloudKit. You can now add custom habits and mark each one complete for the current day. Each check-in is saved to CloudKit so your progress syncs across devices. It can calculate your current and longest streaks for each habit. You can edit, delete, or reorder habits directly in the list and the changes are synced to CloudKit. The app checks your iCloud account at launch and displays an alert if CloudKit is unavailable.

Entitlements

The app requires a Widgeme.entitlements file to enable CloudKit. The sample file in this repository uses a placeholder container identifier (iCloud.com.example.widgeme). Update it to match your own iCloud container before building.