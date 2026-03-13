//
//  HistoryView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date?
    @State private var selectedMedicationId: UUID? = nil

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: currentMonth).capitalized
    }

    private var daysInMonth: [Date?] {
        var result: [Date?] = []
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let firstOfMonth = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: firstOfMonth)

        let firstWeekdayIndex = (weekday + 5) % 7

        result.append(contentsOf: Array(repeating: nil, count: firstWeekdayIndex))

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                result.append(date)
            }
        }

        while result.count % 7 != 0 {
            result.append(nil)
        }

        return result
    }

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("History")
                    .foregroundColor(.medUpcoming)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 16)

                if !viewModel.medications.isEmpty {
                    Picker("Medication", selection: $selectedMedicationId) {
                        Text("All medications").tag(UUID?.none)
                        ForEach(viewModel.medications) { med in
                            Text(med.name).tag(Optional(med.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.medUpcoming)
                    .padding(.horizontal)
                }

                calendarView

                if let selectedDate = selectedDate {
                    VStack(alignment: .leading) {
                        Text(formattedDate(selectedDate))
                            .foregroundColor(.medUpcoming)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.dosesOnDate(selectedDate, medicationId: selectedMedicationId)) { dose in
                            HistoryDoseCard(dose: dose)
                        }
                    }
                    .padding(.bottom)
                } else {
                    Spacer()
                }
            }
        }
        .onAppear {
            if selectedDate == nil {
                selectedDate = calendar.startOfDay(for: Date())
            }
        }
    }

    private var calendarView: some View {
        VStack {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.medUpcoming)
                }

                Spacer()

                Text(monthYearString)
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.medUpcoming)
                }
            }
            .padding(.horizontal)

            HStack {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        let takenCount = viewModel.takenOnDate(date, medicationId: selectedMedicationId)
                        let totalCount = viewModel.totalOnDate(date, medicationId: selectedMedicationId)
                        DayCell(
                            date: date,
                            takenCount: takenCount,
                            totalCount: totalCount,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date())
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
        .padding()
        .background(LinearGradient.medCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
        .padding(.horizontal)
    }

    private func previousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prev
        }
    }

    private func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
        }
    }
}

