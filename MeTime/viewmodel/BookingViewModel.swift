//
//  BookingViewModel.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import UIKit
import Foundation
import EventKit
import FirebaseAuth
import FirebaseFirestore

class BookingViewModel: ObservableObject {
    @Published var schedules: [DaySchedule] = []
    @Published var showingDatePicker = false
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private let eventStore = EKEventStore()
    private let db = Firestore.firestore()
    
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
        var schedule = DaySchedule(date: date)
        schedule.timeSlots = DaySchedule.generateTimeSlots(for: date)
        schedules.append(schedule)
        saveSchedules(schedule: schedule)
    }
    
    func generateLink(for schedule: DaySchedule) -> String {
        return "https://mybeautycrave.com/book/\(schedule.uniqueLink)"
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
        
        // mark subsequent slots as booked based on service duration
        let totalDuration = services.reduce(0) { $0 + $1.duration }
        let slotsNeeded = Int(ceil(Double(totalDuration) / 15.0)) - 1
        
        for i in 1...slotsNeeded {
            let nextIndex = slotIndex + i
            if nextIndex < schedules[scheduleIndex].timeSlots.count {
                schedules[scheduleIndex].timeSlots[nextIndex].isBooked = true
            }
        }
        
        addToCalendar(schedule: schedules[scheduleIndex], slot: schedules[scheduleIndex].timeSlots[slotIndex])
        saveSchedules(schedule: schedules[scheduleIndex])
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
    
    func cancelBooking(scheduleId: String, slotId: UUID) {
        guard let scheduleIndex = schedules.firstIndex(where: { $0.uniqueLink == scheduleId }),
              let slotIndex = schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == slotId }) else { return }
        
        let slot = schedules[scheduleIndex].timeSlots[slotIndex]
        let totalDuration = slot.services.reduce(0) { $0 + $1.duration }
        let slotsToFree = Int(ceil(Double(totalDuration) / 15.0))
        
        // free this slot and subsequent slots
        for i in 0..<slotsToFree {
            let index = slotIndex + i
            if index < schedules[scheduleIndex].timeSlots.count {
                schedules[scheduleIndex].timeSlots[index].isBooked = false
                schedules[scheduleIndex].timeSlots[index].customerName = nil
                schedules[scheduleIndex].timeSlots[index].customerPhone = nil
                schedules[scheduleIndex].timeSlots[index].services = []
            }
        }
        
        saveSchedules(schedule: schedules[scheduleIndex])
        
        alertMessage = "Booking cancelled successfully"
        showingAlert = true
    }
    
    // MARK: - Persistance
    private func saveSchedules(schedule: DaySchedule) {
        let data: [String: Any] = [
            "date": Timestamp(date: schedule.date),
            "uniqueLink": schedule.uniqueLink,
            "timeSlots": schedule.timeSlots.map { slot in
                [
                    "id": slot.id.uuidString,
                    "startTime": Timestamp(date: slot.startTime),
                    "isBooked": slot.isBooked,
                    "customerName": slot.customerName ?? "",
                    "customerPhone": slot.customerPhone ?? "",
                    "services": slot.services.map { service in
                        [
                            "id": service.id.uuidString,
                            "name": service.name,
                            "duration": service.duration,
                            "price": service.price,
                            "emoji": service.emoji
                        ]
                    }
                ]
            }
        ]
        
        db.collection("schedules").document(schedule.uniqueLink).setData(data) { error in
            if let error = error {
                print("Error saving schedule: \(error)")
            }
        }
    }
    
    private func loadSchedules() {
        isLoading = true
        
        db.collection("schedules")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error loading schedules: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.schedules = documents.compactMap { doc in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let uniqueLink = data["uniqueLink"] as? String,
                          let timeSlotsData = data["timeSlots"] as? [[String: Any]] else {
                        return nil
                    }
                    
                    var schedule = DaySchedule(date: date)
                    schedule.uniqueLink = uniqueLink
                    schedule.timeSlots = timeSlotsData.compactMap { slotData in
                        guard let startTime = (slotData["startTime"] as? Timestamp)?.dateValue(),
                              let idString = slotData["id"] as? String,
                              let id = UUID(uuidString: idString) else {
                            return nil
                        }
                        
                        var slot = TimeSlot(id: id, startTime: startTime)
                        slot.isBooked = slotData["isBooked"] as? Bool ?? false
                        slot.customerName = slotData["customerName"] as? String
                        slot.customerPhone = slotData["customerPhone"] as? String
                        
                        if let servicesData = slotData["services"] as? [[String: Any]] {
                            slot.services = servicesData.compactMap { serviceData in
                                guard let name = serviceData["name"] as? String,
                                      let duration = serviceData["duration"] as? Int,
                                      let price = serviceData["price"] as? Double,
                                      let emoji = serviceData["emoji"] as? String else {
                                    return nil
                                }
                                return Service(name: name, duration: duration, price: price, emoji: emoji)
                            }
                        }
                        
                        return slot
                    }
                    
                    return schedule
                }
            }
    }
}
