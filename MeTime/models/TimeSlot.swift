//
//  TimeSlot.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import Foundation

struct TimeSlot: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    var isBooked: Bool = false
    var customerName: String?
    var customerPhone: String?
    var services: [Service] = []
    var endTime: Date {
        let totalDuration = services.reduce(0) { $0 + $1.duration }
        return startTime.addingTimeInterval(TimeInterval(totalDuration * 60))
    }
}
