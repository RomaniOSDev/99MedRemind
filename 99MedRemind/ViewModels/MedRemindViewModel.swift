//
//  MedRemindViewModel.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import Foundation
import Combine
import UserNotifications

final class MedRemindViewModel: ObservableObject {
    // Published properties
    @Published var medications: [Medication] = []
    @Published var schedules: [Schedule] = []
    @Published var doses: [Dose] = []
    @Published var refills: [Refill] = []

    @Published var selectedDate = Date()

    // MARK: - Today's doses

    var todayDoses: [Dose] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return doses.filter { dose in
            dose.scheduledTime >= today && dose.scheduledTime < tomorrow
        }
        .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var todayTotal: Int {
        todayDoses.count
    }

    var todayTaken: Int {
        todayDoses.filter { $0.status == .taken }.count
    }

    var todayPending: Int {
        todayDoses.filter { $0.status == .pending }.count
    }

    var todayMissed: Int {
        todayDoses.filter { $0.status == .missed }.count
    }

    var todayProgress: Double {
        guard todayTotal > 0 else { return 0 }
        return Double(todayTaken) / Double(todayTotal)
    }

    // MARK: - Statistics

    var totalDoses: Int {
        doses.count
    }

    var totalTaken: Int {
        doses.filter { $0.status == .taken }.count
    }

    var totalMissed: Int {
        doses.filter { $0.status == .missed }.count
    }

    var totalSkipped: Int {
        doses.filter { $0.isSkipped }.count
    }

    var adherenceRate: Double {
        let taken = Double(totalTaken)
        let total = Double(totalDoses - totalSkipped)
        guard total > 0 else { return 0 }
        return (taken / total) * 100
    }

    var monthlyAdherence: [(month: String, adherence: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: doses) { dose in
            let components = calendar.dateComponents([.year, .month], from: dose.scheduledTime)
            return calendar.date(from: components) ?? Date()
        }

        return grouped.map { date, doses in
            let total = doses.filter { !$0.isSkipped }.count
            let taken = doses.filter { $0.status == .taken }.count
            let adherence = total > 0 ? Double(taken) / Double(total) * 100 : 0

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return (month: formatter.string(from: date), adherence: adherence)
        }
        .sorted { $0.month < $1.month }
    }

    // MARK: - Medication stats

    struct MedicationStat: Identifiable {
        let id: UUID
        let name: String
        let purpose: String?
        let totalCount: Int
        let takenCount: Int
        var adherence: Double {
            totalCount > 0 ? Double(takenCount) / Double(totalCount) * 100 : 0
        }
    }

    var medicationStats: [MedicationStat] {
        medications.map { med in
            let medDoses = doses.filter { $0.medicationId == med.id && !$0.isSkipped }
            let total = medDoses.count
            let taken = medDoses.filter { $0.status == .taken }.count
            return MedicationStat(
                id: med.id,
                name: med.name,
                purpose: med.purpose,
                totalCount: total,
                takenCount: taken
            )
        }
        .filter { $0.totalCount > 0 }
    }

    /// Nearest upcoming dose across all medications.
    var nextUpcomingDose: Dose? {
        doses
            .filter { $0.status == .pending && $0.scheduledTime > Date() }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first
    }

    // MARK: - CRUD

    func addMedication(
        name: String,
        dosage: Double,
        unit: DosageUnit,
        instructions: String?,
        purpose: String?,
        sideEffects: String?,
        maxDailyDose: Double?,
        times: [Date],
        frequency: FrequencyType,
        daysOfWeek: [DayOfWeek]?,
        startDate: Date,
        endDate: Date?,
        refillQuantity: Int,
        refillReminder: Bool,
        notes: String?
    ) {
        let medication = Medication(
            id: UUID(),
            name: name,
            dosage: dosage,
            unit: unit,
            instructions: instructions,
            notes: notes,
            purpose: purpose,
            sideEffects: sideEffects,
            maxDailyDose: maxDailyDose,
            remainingQuantity: refillQuantity > 0 ? refillQuantity : nil,
            lowStockThreshold: refillQuantity > 0 ? max(1, min(refillQuantity, 5)) : nil,
            lastRefillDate: refillQuantity > 0 ? Date() : nil,
            isActive: true,
            refillDate: nil,
            refillReminder: refillReminder,
            createdAt: Date()
        )

        medications.append(medication)

        let schedule = Schedule(
            id: UUID(),
            medicationId: medication.id,
            medicationName: medication.name,
            times: times,
            frequency: frequency,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )

        schedules.append(schedule)

        if refillQuantity > 0 {
            let refill = Refill(
                id: UUID(),
                medicationId: medication.id,
                medicationName: medication.name,
                date: Date(),
                quantity: refillQuantity,
                notes: nil
            )
            refills.append(refill)
        }

        generateDoses(for: schedule)
        scheduleNotifications(for: schedule)
        saveToUserDefaults()
    }

    func generateDoses(for schedule: Schedule) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = schedule.endDate ?? calendar.date(byAdding: .month, value: 1, to: now)!

        var currentDate = max(schedule.startDate, now)

        while currentDate <= endDate {
            if shouldTakeOnDate(currentDate, schedule: schedule) {
                for time in schedule.times {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute

                    if let scheduledTime = calendar.date(from: dateComponents) {
                        if !doses.contains(where: { dose in
                            dose.medicationId == schedule.medicationId &&
                            abs(dose.scheduledTime.timeIntervalSince(scheduledTime)) < 60
                        }) {
                            var dose = Dose(
                                id: UUID(),
                                medicationId: schedule.medicationId,
                                medicationName: schedule.medicationName,
                                scheduledTime: scheduledTime,
                                takenTime: nil,
                                dosage: 0,
                                unit: .mg,
                                notes: nil,
                                isSkipped: false
                            )
                            if let med = medications.first(where: { $0.id == dose.medicationId }) {
                                dose.dosage = med.dosage
                                dose.unit = med.unit
                            }
                            doses.append(dose)
                        }
                    }
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }

    private func shouldTakeOnDate(_ date: Date, schedule: Schedule) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        switch schedule.frequency {
        case .daily:
            return true
        case .weekly:
            guard let days = schedule.daysOfWeek else { return false }
            return days.contains { $0.rawValue == weekday }
        case .once:
            return calendar.isDate(date, inSameDayAs: schedule.startDate)
        case .custom:
            return true
        }
    }

    func takeDose(_ dose: Dose) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].takenTime = Date()

            if let medIndex = medications.firstIndex(where: { $0.id == dose.medicationId }),
               let current = medications[medIndex].remainingQuantity {
                let newValue = max(0, current - 1)
                medications[medIndex].remainingQuantity = newValue

                if newValue == 0 {
                    medications[medIndex].refillDate = Date()
                } else if let threshold = medications[medIndex].lowStockThreshold,
                          newValue <= threshold {
                    medications[medIndex].refillDate = Date()
                }
            }

            saveToUserDefaults()
        }
    }

    func skipDose(_ dose: Dose) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].isSkipped = true
            saveToUserDefaults()
        }
    }

    func deleteMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        schedules.removeAll { $0.medicationId == medication.id }
        doses.removeAll { $0.medicationId == medication.id }

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["med-\(medication.id.uuidString)"]
        )

        saveToUserDefaults()
    }

    func toggleActive(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index].isActive.toggle()

            if medications[index].isActive {
                if let schedule = schedules.first(where: { $0.medicationId == medication.id }) {
                    scheduleNotifications(for: schedule)
                }
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["med-\(medication.id.uuidString)"]
                )
            }

            saveToUserDefaults()
        }
    }

    // MARK: - Notifications

    func scheduleNotifications(for schedule: Schedule) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    self.createNotifications(for: schedule)
                }
            }
        }
    }

    private func createNotifications(for schedule: Schedule) {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(
            withIdentifiers: ["med-\(schedule.medicationId.uuidString)"]
        )

        let calendar = Calendar.current
        let now = Date()
        let endDate = schedule.endDate ?? calendar.date(byAdding: .month, value: 1, to: now)!

        var currentDate = max(schedule.startDate, now)

        while currentDate <= endDate {
            if shouldTakeOnDate(currentDate, schedule: schedule) {
                for time in schedule.times {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute

                    if let scheduledTime = calendar.date(from: dateComponents),
                       scheduledTime > now {
                        let content = UNMutableNotificationContent()
                        content.title = "MedRemind"
                        content.body = "Time to take \(schedule.medicationName)"
                        content.sound = .default
                        content.categoryIdentifier = "MEDICATION"

                        let triggerDate = calendar.dateComponents(
                            [.year, .month, .day, .hour, .minute],
                            from: scheduledTime
                        )
                        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

                        let identifier = "med-\(schedule.medicationId.uuidString)"
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                        center.add(request)
                    }
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }

    // MARK: - Queries

    func takenToday(for medicationId: UUID) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return doses.filter { dose in
            dose.medicationId == medicationId &&
            dose.takenTime != nil &&
            dose.takenTime! >= today &&
            dose.takenTime! < tomorrow
        }.count
    }

    func nextDose(for medicationId: UUID) -> Date? {
        doses
            .filter { dose in
                dose.medicationId == medicationId &&
                dose.status == .pending &&
                dose.scheduledTime > Date()
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first?
            .scheduledTime
    }

    func takenOnDate(_ date: Date, medicationId: UUID? = nil) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return doses.filter { dose in
            if let medicationId = medicationId, dose.medicationId != medicationId {
                return false
            }
            if let taken = dose.takenTime {
                return taken >= dayStart && taken < dayEnd
            }
            return false
        }.count
    }

    func totalOnDate(_ date: Date, medicationId: UUID? = nil) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return doses.filter { dose in
            if let medicationId = medicationId, dose.medicationId != medicationId {
                return false
            }
            return dose.scheduledTime >= dayStart && dose.scheduledTime < dayEnd
        }.count
    }

    func dosesOnDate(_ date: Date, medicationId: UUID? = nil) -> [Dose] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return doses
            .filter { dose in
                if let medicationId = medicationId, dose.medicationId != medicationId {
                    return false
                }
                return dose.scheduledTime >= dayStart && dose.scheduledTime < dayEnd
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    // MARK: - Time range statistics

    func stats(forLastDays days: Int) -> (total: Int, taken: Int, missed: Int, adherence: Double) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let fromDate = calendar.date(byAdding: .day, value: -days + 1, to: todayStart) else {
            return (0, 0, 0, 0)
        }

        let relevant = doses.filter { dose in
            dose.scheduledTime >= fromDate && dose.scheduledTime <= Date() && !dose.isSkipped
        }

        let total = relevant.count
        let taken = relevant.filter { $0.status == .taken }.count
        let missed = relevant.filter { $0.status == .missed }.count
        let adherence = total > 0 ? Double(taken) / Double(total) * 100 : 0

        return (total, taken, missed, adherence)
    }

    // MARK: - Persistence

    private let medicationsKey = "medremind_medications"
    private let schedulesKey = "medremind_schedules"
    private let dosesKey = "medremind_doses"
    private let refillsKey = "medremind_refills"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: medicationsKey)
        }
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: schedulesKey)
        }
        if let encoded = try? JSONEncoder().encode(doses) {
            UserDefaults.standard.set(encoded, forKey: dosesKey)
        }
        if let encoded = try? JSONEncoder().encode(refills) {
            UserDefaults.standard.set(encoded, forKey: refillsKey)
        }
    }

    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: medicationsKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }

        if let data = UserDefaults.standard.data(forKey: schedulesKey),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        }

        if let data = UserDefaults.standard.data(forKey: dosesKey),
           let decoded = try? JSONDecoder().decode([Dose].self, from: data) {
            doses = decoded
        }

        if let data = UserDefaults.standard.data(forKey: refillsKey),
           let decoded = try? JSONDecoder().decode([Refill].self, from: data) {
            refills = decoded
        }

        if medications.isEmpty {
            loadDemoData()
        }
    }

    private func loadDemoData() {
        let med1 = Medication(
            id: UUID(),
            name: "Vitamin D3",
            dosage: 2000,
            unit: .mcg,
            instructions: "After breakfast",
            notes: "Immune support",
            isActive: true,
            refillDate: Date().addingTimeInterval(86400 * 30),
            refillReminder: true,
            createdAt: Date()
        )

        let med2 = Medication(
            id: UUID(),
            name: "Magnesium",
            dosage: 400,
            unit: .mg,
            instructions: "Before sleep",
            notes: "For better sleep",
            isActive: true,
            refillDate: Date().addingTimeInterval(86400 * 15),
            refillReminder: true,
            createdAt: Date()
        )

        medications = [med1, med2]

        let calendar = Calendar.current
        let now = Date()

        let time1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let time2 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!

        let schedule1 = Schedule(
            id: UUID(),
            medicationId: med1.id,
            medicationName: med1.name,
            times: [time1],
            frequency: .daily,
            daysOfWeek: nil,
            startDate: now,
            endDate: nil,
            isActive: true
        )

        let schedule2 = Schedule(
            id: UUID(),
            medicationId: med2.id,
            medicationName: med2.name,
            times: [time2],
            frequency: .daily,
            daysOfWeek: nil,
            startDate: now,
            endDate: nil,
            isActive: true
        )

        schedules = [schedule1, schedule2]

        let today = calendar.startOfDay(for: now)

        let dose1 = Dose(
            id: UUID(),
            medicationId: med1.id,
            medicationName: med1.name,
            scheduledTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
            takenTime: calendar.date(bySettingHour: 9, minute: 15, second: 0, of: today)!,
            dosage: med1.dosage,
            unit: med1.unit,
            notes: nil,
            isSkipped: false
        )

        let dose2 = Dose(
            id: UUID(),
            medicationId: med2.id,
            medicationName: med2.name,
            scheduledTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!,
            takenTime: nil,
            dosage: med2.dosage,
            unit: med2.unit,
            notes: nil,
            isSkipped: false
        )

        doses = [dose1, dose2]
    }
}

