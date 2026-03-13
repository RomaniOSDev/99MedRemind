//
//  Components.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            Text(value)
                .foregroundColor(.white)
                .font(.title2)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.medCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
    }
}

struct DayChip: View {
    let day: DayOfWeek
    let isSelected: Bool

    var body: some View {
        Text(day.shortName)
            .frame(width: 32, height: 32)
            .background(
                isSelected
                ? AnyView(LinearGradient.medAccent)
                : AnyView(LinearGradient.medCard)
            )
            .foregroundColor(isSelected ? .medBackground : .medUpcoming)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.medUpcoming, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
    }
}

struct DoseCard: View {
    let dose: Dose

    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 4) {
                Text(formattedTime(dose.scheduledTime))
                    .foregroundColor(dose.status.color)
                    .font(.title3)
                    .bold()

                if let taken = dose.takenTime {
                    Text("taken at \(formattedTime(taken))")
                        .foregroundColor(.gray)
                        .font(.caption2)
                }
            }
            .frame(width: 80)

            Rectangle()
                .fill(dose.status.color)
                .frame(width: 2)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(dose.medicationName)
                    .foregroundColor(.white)
                    .font(.headline)

                HStack {
                    Text("\(dose.dosage, specifier: "%.1f") \(dose.unit.rawValue)")
                        .foregroundColor(.gray)
                        .font(.caption)

                    Spacer()

                    Image(systemName: dose.status.icon)
                        .foregroundColor(dose.status.color)
                        .font(.caption)

                    Text(statusText(dose.status))
                        .foregroundColor(dose.status.color)
                        .font(.caption)
                }
            }
            .padding(.leading, 8)

            Spacer()
        }
        .padding()
        .background(LinearGradient.medCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(dose.status.color.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

struct MedicationCard: View {
    let medication: Medication
    let viewModel: MedRemindViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: medication.isActive ? "heart.fill" : "heart.slash")
                    .foregroundColor(medication.isActive ? .medTaken : .gray)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .foregroundColor(.white)
                        .font(.headline)

                    Text("\(medication.dosage, specifier: "%.1f") \(medication.unit.rawValue)")
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                Spacer()

                let todayCount = viewModel.takenToday(for: medication.id)
                if todayCount > 0 {
                    Text("\(todayCount)")
                        .foregroundColor(.medTaken)
                        .font(.title3)
                        .bold()
                }
            }

            if let instructions = medication.instructions, !instructions.isEmpty {
                Text(instructions)
                    .foregroundColor(.medUpcoming)
                    .font(.caption)
            }

            if let purpose = medication.purpose, !purpose.isEmpty {
                Text(purpose)
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            if let nextDose = viewModel.nextDose(for: medication.id) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.medUpcoming)
                        .font(.caption)

                    Text("Next: \(formattedTime(nextDose))")
                        .foregroundColor(.medUpcoming)
                        .font(.caption)
                }
            }

            if let remaining = medication.remainingQuantity {
                HStack {
                    Image(systemName: "pills")
                        .foregroundColor(.medUpcoming)
                        .font(.caption)

                    Text("Remaining: \(remaining)")
                        .foregroundColor(remaining == 0 ? .red : .gray)
                        .font(.caption)
                }
            } else if let refillDate = medication.refillDate {
                HStack {
                    let isExpired = refillDate < Date()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(isExpired ? .red : .medUpcoming)
                        .font(.caption)

                    Text(isExpired ? "Out of stock!" : "Will run out \(formattedDate(refillDate))")
                        .foregroundColor(isExpired ? .red : .gray)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(LinearGradient.medCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(medication.isActive ? Color.medUpcoming : Color.gray, lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

struct HistoryDoseCard: View {
    let dose: Dose

    var body: some View {
        HStack {
            Image(systemName: dose.status.icon)
                .foregroundColor(dose.status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medicationName)
                    .foregroundColor(.white)
                    .font(.headline)

                Text("\(dose.dosage, specifier: "%.1f") \(dose.unit.rawValue)")
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            Spacer()

            Text(formattedTime(dose.scheduledTime))
                .foregroundColor(.gray)
                .font(.caption)

            if let taken = dose.takenTime {
                Text("✓ \(formattedTime(taken))")
                    .foregroundColor(.medTaken)
                    .font(.caption)
            }
        }
        .padding()
        .background(LinearGradient.medCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct DayCell: View {
    let date: Date
    let takenCount: Int
    let totalCount: Int
    let isSelected: Bool

    private var calendar: Calendar {
        Calendar.current
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .foregroundColor(.white)
                .font(.caption)

            if totalCount > 0 {
                let percentage = Double(takenCount) / Double(totalCount)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.medTaken)
                        .frame(width: max(4, CGFloat(percentage) * 20), height: 4)
                }
                .frame(width: 20)

                Text("\(takenCount)/\(totalCount)")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient.medCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.medUpcoming : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isSelected ? 0.35 : 0.2), radius: 6, x: 0, y: 3)
    }
}

