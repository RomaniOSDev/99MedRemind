//
//  MedColors.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

extension Color {
    /// #1A2C38 — main background
    static let medBackground = Color(red: 0.102, green: 0.173, blue: 0.220)
    /// #1475E1 — accent blue for upcoming
    static let medUpcoming = Color(red: 0.078, green: 0.459, blue: 0.882)
    /// #16FF16 — accent green for taken
    static let medTaken = Color(red: 0.086, green: 1.0, blue: 0.086)
}

extension LinearGradient {
    /// Deep, slightly vignetted background gradient.
    static let medBackground = LinearGradient(
        colors: [.medBackground, Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle glossy card gradient for surfaces.
    static let medCard = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient for primary buttons and highlights.
    static let medAccent = LinearGradient(
        colors: [.medUpcoming, .medTaken],
        startPoint: .leading,
        endPoint: .trailing
    )
}


