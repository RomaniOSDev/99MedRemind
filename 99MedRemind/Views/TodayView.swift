//
//  TodayView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var selectedDose: Dose?
    @State private var showingAddMedication = false
    @State private var selectedFilter: TodayFilter = .all

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header

                statsScroll

                filterPicker

                dayProgress

                Text("Today's doses")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTodayDoses) { dose in
                            DoseCard(dose: dose)
                                .onTapGesture {
                                    selectedDose = dose
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if dose.status == .pending {
                                        Button {
                                            viewModel.takeDose(dose)
                                        } label: {
                                            Label("Take", systemImage: "checkmark")
                                        }
                                        .tint(.medTaken)

                                        Button(role: .destructive) {
                                            viewModel.skipDose(dose)
                                        } label: {
                                            Label("Skip", systemImage: "xmark")
                                        }
                                        .tint(.red)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.medUpcoming)
                            .shadow(radius: 8)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(viewModel: viewModel)
        }
    }

    private var filterPicker: some View {
        Picker("", selection: $selectedFilter) {
            ForEach(TodayFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var filteredTodayDoses: [Dose] {
        switch selectedFilter {
        case .all:
            return viewModel.todayDoses
        case .upcoming:
            return viewModel.todayDoses.filter { $0.status == .pending }
        case .missed:
            return viewModel.todayDoses.filter { $0.status == .missed }
        case .taken:
            return viewModel.todayDoses.filter { $0.status == .taken }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MedRemind")
                .foregroundColor(.medUpcoming)
                .font(.largeTitle)
                .bold()
            Text(headerDateString(Date()))
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var statsScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Scheduled today",
                    value: "\(viewModel.todayTotal)",
                    icon: "pill.fill",
                    color: .medUpcoming
                )

                StatCard(
                    title: "Taken",
                    value: "\(viewModel.todayTaken)",
                    icon: "checkmark.circle.fill",
                    color: .medTaken
                )

                StatCard(
                    title: "Remaining",
                    value: "\(viewModel.todayPending)",
                    icon: "clock",
                    color: .medUpcoming
                )

                StatCard(
                    title: "Missed",
                    value: "\(viewModel.todayMissed)",
                    icon: "exclamationmark.circle.fill",
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }

    private var dayProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Day progress")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                Text("\(viewModel.todayTaken)/\(viewModel.todayTotal)")
                    .foregroundColor(.medTaken)
                    .bold()
            }

            ProgressView(value: viewModel.todayProgress)
                .tint(.medTaken)
                .frame(height: 10)
                .scaleEffect(y: 1.8, anchor: .center)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                )
        }
        .padding()
        .background(LinearGradient.medCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.medUpcoming.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
        .padding(.horizontal)
    }
}

enum TodayFilter: String, CaseIterable, Identifiable {
    case all
    case upcoming
    case missed
    case taken

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .upcoming: return "Upcoming"
        case .missed: return "Missed"
        case .taken: return "Taken"
        }
    }
}

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MedRemindViewModel

    @State private var medicationName: String = ""
    @State private var dosage: Double = 0
    @State private var unit: DosageUnit = .mg
    @State private var instructions: String = ""
    @State private var purpose: String = ""
    @State private var sideEffects: String = ""
    @State private var maxDailyDose: Double = 0
    @State private var frequency: FrequencyType = .daily
    @State private var selectedDays: [DayOfWeek] = []
    @State private var times: [Date] = []
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var refillQuantity: Int = 0
    @State private var refillReminder: Bool = false
    @State private var notes: String = ""

    @State private var showTimePicker: Bool = false
    @State private var timeToAdd: Date = Date()
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.medBackground
                    .ignoresSafeArea()

                Form {
                    Section(header: Text("Medication").foregroundColor(.medUpcoming)) {
                        TextField("Name", text: $medicationName)
                            .foregroundColor(.white)

                        HStack {
                            TextField("Dosage", value: $dosage, format: .number)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)

                            Picker("", selection: $unit) {
                                ForEach(DosageUnit.allCases) { unit in
                                    Text(unit.rawValue)
                                        .tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }

                        TextField("Instruction (e.g. after food)", text: $instructions)
                            .foregroundColor(.white)
                    }

                    Section(header: Text("Details").foregroundColor(.medUpcoming)) {
                        TextField("Purpose (e.g. for blood pressure)", text: $purpose)
                            .foregroundColor(.white)

                        TextField("Side effects / warnings", text: $sideEffects)
                            .foregroundColor(.white)

                        TextField("Max daily dose (optional)", value: $maxDailyDose, format: .number)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                    }

                    Section(header: Text("Schedule").foregroundColor(.medUpcoming)) {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(FrequencyType.allCases) { freq in
                                Text(freq.rawValue)
                                    .tag(freq)
                            }
                        }

                        if frequency == .weekly {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(DayOfWeek.allCases) { day in
                                        DayChip(
                                            day: day,
                                            isSelected: selectedDays.contains(where: { $0 == day })
                                        )
                                        .onTapGesture {
                                            toggleDay(day)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        HStack {
                            Text("Intake time")
                            Spacer()
                            Button("Add time") {
                                timeToAdd = Date()
                                showTimePicker = true
                            }
                            .foregroundColor(.medUpcoming)
                        }

                        ForEach(times.indices, id: \.self) { index in
                            HStack {
                                Text(formattedTime(times[index]))
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    times.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        DatePicker("Start date", selection: $startDate, displayedComponents: .date)

                        Toggle("End date", isOn: $hasEndDate)
                            .tint(.medUpcoming)

                        if hasEndDate {
                            DatePicker("Finish", selection: $endDate, displayedComponents: .date)
                        }
                    }

                    Section(header: Text("Stock").foregroundColor(.medUpcoming)) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Stepper("\(refillQuantity)", value: $refillQuantity, in: 0...999)
                        }

                        Toggle("Remind about refill", isOn: $refillReminder)
                            .tint(.medUpcoming)
                    }

                    Section(header: Text("Notes").foregroundColor(.medUpcoming)) {
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .foregroundColor(.white)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.medTaken)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedication()
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.medUpcoming)
                    .cornerRadius(8)
                }
            }
        }
        .tint(.medUpcoming)
        .alert("Cannot save", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .sheet(isPresented: $showTimePicker) {
            VStack(spacing: 16) {
                Text("Select time")
                    .foregroundColor(.white)
                    .font(.headline)

                DatePicker(
                    "",
                    selection: $timeToAdd,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(.medUpcoming)

                HStack {
                    Button("Cancel") {
                        showTimePicker = false
                    }
                    .foregroundColor(.medTaken)

                    Spacer()

                    Button("Add") {
                        times.append(timeToAdd)
                        times.sort()
                        showTimePicker = false
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.medUpcoming)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.medBackground.ignoresSafeArea())
        }
    }

    private func toggleDay(_ day: DayOfWeek) {
        if let index = selectedDays.firstIndex(of: day) {
            selectedDays.remove(at: index)
        } else {
            selectedDays.append(day)
        }
    }

    private func saveMedication() {
        let trimmedName = medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter medication name."
            showValidationAlert = true
            return
        }
        guard !times.isEmpty else {
            validationMessage = "Please add at least one intake time."
            showValidationAlert = true
            return
        }

        let end = hasEndDate ? endDate : nil

        viewModel.addMedication(
            name: trimmedName,
            dosage: dosage,
            unit: unit,
            instructions: instructions.isEmpty ? nil : instructions,
            purpose: purpose.isEmpty ? nil : purpose,
            sideEffects: sideEffects.isEmpty ? nil : sideEffects,
            maxDailyDose: maxDailyDose > 0 ? maxDailyDose : nil,
            times: times,
            frequency: frequency,
            daysOfWeek: frequency == .weekly ? selectedDays : nil,
            startDate: startDate,
            endDate: end,
            refillQuantity: refillQuantity,
            refillReminder: refillReminder,
            notes: notes.isEmpty ? nil : notes
        )

        dismiss()
    }
}

