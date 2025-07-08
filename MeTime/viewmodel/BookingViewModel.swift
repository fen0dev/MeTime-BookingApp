//
//  BookingViewModel.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import Foundation
import UIKit
import EventKit

class BookingViewModel: ObservableObject {
    @Published var schedules: [DaySchedule] = []
    @Published var showingDatePicker = false
    @Published var selectedDate = Date()
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private let eventStore = EKEventStore()
    
    init() {
        loadSchedules()
        requestCalendarAccess()
    }
    
    func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents() { [weak self] granted, error in
            guard let self = self else { return }
            if !granted {
                DispatchQueue.main.async {
                    self.alertMessage = "Calendar access is required to sync bookings"
                    self.showingAlert = true
                }
            }
        }
    }
    
    func createScheduleForDate(_ date: Date) {
        let schedule = DaySchedule(date: date)
        schedules.append(schedule)
        saveSchedules()
    }
    
    func generateLink(for schedule: DaySchedule) -> String {
        return "nailbooking://book/\(schedule.uniqueLink)"
    }
    
    func copyLinkToClipboard(for schedule: DaySchedule) {
        let link = generateLink(for: schedule)
        UIPasteboard.general.string = link
        alertMessage = "Link copied! 💅✨"
        showingAlert = true
    }
    
    func bookTimeSlot(scheduleId: String, slotId: UUID, customerName: String, customerPhone: String, services: [Service]) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.uniqueLink == scheduleId }),
              let slotIndex = schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == slotId }) else { return }
        
        schedules[scheduleIndex].timeSlots[slotIndex].isBooked = true
        schedules[scheduleIndex].timeSlots[slotIndex].customerName = customerName
        schedules[scheduleIndex].timeSlots[slotIndex].customerPhone = customerPhone
        schedules[scheduleIndex].timeSlots[slotIndex].services = services
        
        // mark subsequent slot as booked based on service duration
        let totalDuration = services.reduce(0) { $0 + $1.duration }
        let slotsNeeded = Int(ceil(Double(totalDuration) / 15.0)) - 1
        
        for i in 1...slotsNeeded {
            let nextIndex = slotIndex + i
            if nextIndex < schedules[scheduleIndex].timeSlots.count {
                schedules[scheduleIndex].timeSlots[nextIndex].isBooked = true
            }
        }
        
        addToCalendar(schedule: schedules[scheduleIndex], slot: schedules[scheduleIndex].timeSlots[slotIndex])
        saveSchedules()
    }
    
    private func addToCalendar(schedule: DaySchedule, slot: TimeSlot) {
        let event = EKEvent(eventStore: eventStore)
        let serviceName = slot.services.map { $0.name }.joined(separator: ", ")
        event.title = "\(slot.customerName ?? "Customer") - \(serviceName)"
        event.notes = """
        Phone: \(slot.customerPhone ?? "N/A")
        Services: \(serviceName)
        Total: $\(slot.services.reduce(0) { $0 + $1.price })
        """
        
        event.startDate = slot.startTime
        event.endDate = slot.endTime
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error saving to calendar: \(error)")
        }
    }
    
    // MARK: - Persistance
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "schedules")
        }
    }
    
    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: "schedules"),
           let decoded = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            schedules = decoded
        }
    }
}
