//
//  DaySchedule.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import Foundation

struct DaySchedule: Identifiable, Codable {
    var id = UUID()
    let date: Date
    var timeSlots: [TimeSlot]
    var uniqueLink: String
    
    init(date: Date) {
        self.date = date
        self.uniqueLink = UUID().uuidString
        self.timeSlots = []
    }
    
    static func generateTimeSlots(for date: Date) -> [TimeSlot] {
        var slots: [TimeSlot] = []
        let calendar = Calendar.current
        
        // generate slots from 9 am to 10 pm with 15-minute intervals
        for hour in 9...22 {
            for minute in stride(from: 0, to: 60, by: 15) { // Changed from 0 to 15
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                
                if let slotTime = calendar.date(from: components) {
                    // don't create slots after 10pm
                    if hour == 22 && minute > 0 { break }
                    slots.append(TimeSlot(startTime: slotTime))
                }
            }
        }
        
        return slots
    }
    
    func getAvailableSlots(for service: [Service]) -> [TimeSlot] {
        let totalDuration = service.reduce(0) { $0 + $1.duration }
        let closingTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: date)!
        
        return timeSlots.filter { slot in
            // check if slot is booked
            if slot.isBooked { return false }
            
            // check if service would end before clsoing time
            let serviceEndTime = slot.startTime.addingTimeInterval(TimeInterval(totalDuration * 60))
            if serviceEndTime > closingTime { return false }
            
            // check if there's no overlap with other bookings
            let slotIndex = timeSlots.firstIndex(where: { $0.id == slot.id })!
            for i in slotIndex..<timeSlots.count {
                let checkSlot = timeSlots[i]
                if checkSlot.isBooked && checkSlot.startTime < serviceEndTime {
                    return false
                }
                if checkSlot.startTime >= serviceEndTime {
                    break
                }
            }
            
            return true
        }
    }
}
