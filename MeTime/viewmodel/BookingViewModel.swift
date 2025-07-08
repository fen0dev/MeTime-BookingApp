//
//  BookingViewModel.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import UIKit
import SwiftUI
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
    @Published var errorOccurred = false
    @Published var currentToast: Toast?
    
    let services: [Service] = {
        // Using consistent UUIDs for services - Prices in DKK
        let serviceData: [(String, String, Int, Double, String)] = [
            ("1", "Quick Fix Polish", 15, 150, "💅"),
            ("2", "Gel Manicure", 45, 450, "✨"),
            ("3", "Spa Pedicure", 60, 550, "🦶"),
            ("4", "Nail Art", 30, 250, "🎨"),
            ("5", "Polish Change", 20, 200, "💖"),
            ("6", "Gel Removal", 15, 100, "🧼")
        ]
        
        return serviceData.map { data in
            var service = Service(name: data.1, duration: data.2, price: data.3, emoji: data.4)
            // Use consistent UUID based on service number
            service.id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(data.0)") ?? UUID()
            return service
        }
    }()
    
    private let eventStore = EKEventStore()
    private let db = Firestore.firestore()
    private let webDomain = "https://mybeautycrave-metime.web.app"
    
    static let shared = BookingViewModel()
    
    enum BookingError: LocalizedError {
        case invalidPhoneNumber
        case invalidName
        case slotAlreadyBooked
        case insufficientSlots
        case networkError
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidPhoneNumber:
                return "Please enter a valid Danish phone number (+45XXXXXXXX)"
            case .invalidName:
                return "Please enter a valid name (2-50 characters)"
            case .slotAlreadyBooked:
                return "This time slot is no longer available"
            case .insufficientSlots:
                return "Not enough consecutive time slots available for selected services"
            case .networkError:
                return "Network error. Please check your connection"
            case .unknownError:
                return "An unexpected error occurred. Please try again"
            }
        }
    }
    
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
        return "\(webDomain)/book/\(schedule.uniqueLink)"
    }
    
    func copyLinkToClipboard(for schedule: DaySchedule) {
        let link = generateLink(for: schedule)
        UIPasteboard.general.string = link
        showToast("Link copied! 💅✨", icon: "doc.on.doc.fill", type: .success)
    }
    
    func showToast(_ message: String, icon: String, type: ToastType) {
        let backgroundColor: Color
        switch type {
        case .success:
            backgroundColor = ColorTheme.accent
        case .error:
            backgroundColor = Color.red
        case .info:
            backgroundColor = ColorTheme.primary
        }
        
        currentToast = Toast(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor
        )
    }
    
    enum ToastType {
        case success, error, info
    }
    
    func validateDanishPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        let phoneRegex = "^\\+45[0-9]{8}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: cleanedNumber)
    }
    
    func isValidDanishPhone(_ phoneNumber: String) -> Bool {
        return validateDanishPhoneNumber(phoneNumber)
    }
    
    private func validateCustomerName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && trimmedName.count <= 50 && !trimmedName.isEmpty
    }
    
    func bookTimeSlot(scheduleId: String, slotId: UUID, customerName: String, customerPhone: String, services: [Service], completion: @escaping (Result<Void, BookingError>) -> Void) {
        // Validate inputs
        guard validateCustomerName(customerName) else {
            completion(.failure(.invalidName))
            return
        }
        
        guard validateDanishPhoneNumber(customerPhone) else {
            completion(.failure(.invalidPhoneNumber))
            return
        }
        
        guard let scheduleIndex = schedules.firstIndex(where: { $0.uniqueLink == scheduleId }),
              let slotIndex = schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == slotId }) else {
            completion(.failure(.unknownError))
            return
        }
        
        // Check if slot is already booked
        if schedules[scheduleIndex].timeSlots[slotIndex].isBooked {
            completion(.failure(.slotAlreadyBooked))
            return
        }
        
        // Calculate slots needed
        let totalDuration = services.reduce(0) { $0 + $1.duration }
        let slotsNeeded = Int(ceil(Double(totalDuration) / 15.0))
        
        // Check if enough consecutive slots are available
        for i in 0..<slotsNeeded {
            let checkIndex = slotIndex + i
            if checkIndex >= schedules[scheduleIndex].timeSlots.count ||
               schedules[scheduleIndex].timeSlots[checkIndex].isBooked {
                completion(.failure(.insufficientSlots))
                return
            }
        }
        
        // Use Firestore transaction to prevent race conditions
        let scheduleRef = db.collection("schedules").document(scheduleId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let scheduleDocument: DocumentSnapshot
            do {
                try scheduleDocument = transaction.getDocument(scheduleRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = scheduleDocument.data(),
                  let timeSlotsData = data["timeSlots"] as? [[String: Any]] else {
                return nil
            }
            
            // Verify slots are still available in the transaction
            for i in 0..<slotsNeeded {
                let checkIndex = slotIndex + i
                if checkIndex >= timeSlotsData.count {
                    return BookingError.insufficientSlots
                }
                if let isBooked = timeSlotsData[checkIndex]["isBooked"] as? Bool, isBooked {
                    return BookingError.slotAlreadyBooked
                }
            }
            
            // Update the slots
            var updatedSlots = timeSlotsData
            let formattedPhone = customerPhone.replacingOccurrences(of: " ", with: "")
            
            for i in 0..<slotsNeeded {
                let updateIndex = slotIndex + i
                updatedSlots[updateIndex]["isBooked"] = true
                if i == 0 {
                    updatedSlots[updateIndex]["customerName"] = customerName
                    updatedSlots[updateIndex]["customerPhone"] = formattedPhone
                    updatedSlots[updateIndex]["services"] = services.map { service in
                        [
                            "id": service.id.uuidString,
                            "name": service.name,
                            "duration": service.duration,
                            "price": service.price,
                            "emoji": service.emoji
                        ]
                    }
                }
            }
            
            transaction.updateData(["timeSlots": updatedSlots], forDocument: scheduleRef)
            return nil
        }) { [weak self] (result, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completion(.failure(.networkError))
            } else if let bookingError = result as? BookingError {
                completion(.failure(bookingError))
            } else {
                // Update local state
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let scheduleIndex = self.schedules.firstIndex(where: { $0.uniqueLink == scheduleId }),
                       let slotIndex = self.schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == slotId }) {
                        
                        let formattedPhone = customerPhone.replacingOccurrences(of: " ", with: "")
                        
                        for i in 0..<slotsNeeded {
                            let updateIndex = slotIndex + i
                            if updateIndex < self.schedules[scheduleIndex].timeSlots.count {
                                self.schedules[scheduleIndex].timeSlots[updateIndex].isBooked = true
                                if i == 0 {
                                    self.schedules[scheduleIndex].timeSlots[updateIndex].customerName = customerName
                                    self.schedules[scheduleIndex].timeSlots[updateIndex].customerPhone = formattedPhone
                                    self.schedules[scheduleIndex].timeSlots[updateIndex].services = services
                                }
                            }
                        }
                        
                        self.addToCalendar(schedule: self.schedules[scheduleIndex], slot: self.schedules[scheduleIndex].timeSlots[slotIndex])
                        
                        // Show success toast
                        self.showToast("Booking confirmed! 🎉", icon: "checkmark.circle.fill", type: .success)
                    }
                }
                completion(.success(()))
            }
        }
    }
    
    private func addToCalendar(schedule: DaySchedule, slot: TimeSlot) {
        let event = EKEvent(eventStore: eventStore)
        let serviceName = slot.services.map { $0.name }.joined(separator: ", ")
        event.title = "\(slot.customerName ?? "Customer") - \(serviceName)"
        event.notes = """
        Phone: \(slot.customerPhone ?? "N/A")
        Services: \(serviceName)
        Total: \(Int(slot.services.reduce(0) { $0 + $1.price })) kr
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
        
        showToast("Booking cancelled", icon: "trash.fill", type: .info)
    }
    
    func updateBooking(scheduleId: String, originalSlot: TimeSlot, newSlot: TimeSlot,
                      customerName: String, customerPhone: String, customerEmail: String,
                      services: [Service], notes: String) {
        
        guard let scheduleIndex = schedules.firstIndex(where: { $0.uniqueLink == scheduleId }) else {
            showToast("Schedule not found", icon: "exclamationmark.circle", type: .error)
            return
        }
        
        // First, clear the original slots
        let originalSlotsNeeded = Int(ceil(Double(originalSlot.services.reduce(0) { $0 + $1.duration }) / 15.0))
        if let originalStartIndex = schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == originalSlot.id }) {
            for i in 0..<originalSlotsNeeded {
                let clearIndex = originalStartIndex + i
                if clearIndex < schedules[scheduleIndex].timeSlots.count {
                    schedules[scheduleIndex].timeSlots[clearIndex].isBooked = false
                    schedules[scheduleIndex].timeSlots[clearIndex].customerName = nil
                    schedules[scheduleIndex].timeSlots[clearIndex].customerPhone = nil
                    schedules[scheduleIndex].timeSlots[clearIndex].customerEmail = nil
                    schedules[scheduleIndex].timeSlots[clearIndex].notes = nil
                    schedules[scheduleIndex].timeSlots[clearIndex].services = []
                }
            }
        }
        
        // Then, book the new slots
        let newSlotsNeeded = Int(ceil(Double(services.reduce(0) { $0 + $1.duration }) / 15.0))
        if let newStartIndex = schedules[scheduleIndex].timeSlots.firstIndex(where: { $0.id == newSlot.id }) {
            // Check if all needed slots are available
            for i in 0..<newSlotsNeeded {
                let checkIndex = newStartIndex + i
                if checkIndex >= schedules[scheduleIndex].timeSlots.count ||
                   (schedules[scheduleIndex].timeSlots[checkIndex].isBooked &&
                    schedules[scheduleIndex].timeSlots[checkIndex].id != originalSlot.id) {
                    showToast("Selected time slot is not available", icon: "clock.badge.xmark", type: .error)
                    return
                }
            }
            
            // Book the slots
            for i in 0..<newSlotsNeeded {
                let bookIndex = newStartIndex + i
                if bookIndex < schedules[scheduleIndex].timeSlots.count {
                    schedules[scheduleIndex].timeSlots[bookIndex].isBooked = true
                    if i == 0 {
                        schedules[scheduleIndex].timeSlots[bookIndex].customerName = customerName
                        schedules[scheduleIndex].timeSlots[bookIndex].customerPhone = customerPhone.replacingOccurrences(of: " ", with: "")
                        schedules[scheduleIndex].timeSlots[bookIndex].customerEmail = customerEmail
                        schedules[scheduleIndex].timeSlots[bookIndex].notes = notes
                        schedules[scheduleIndex].timeSlots[bookIndex].services = services
                    }
                }
            }
        }
        
        saveSchedules(schedule: schedules[scheduleIndex])
        
        showToast("Booking updated successfully! ✨", icon: "checkmark.circle.fill", type: .success)
    }
    
    func moveBookingBetweenSchedules(fromScheduleId: String, toScheduleId: String,
                                    originalSlot: TimeSlot, newSlot: TimeSlot,
                                    customerName: String, customerPhone: String, customerEmail: String,
                                    services: [Service], notes: String) {
        
        guard let fromIndex = schedules.firstIndex(where: { $0.uniqueLink == fromScheduleId }),
              let toIndex = schedules.firstIndex(where: { $0.uniqueLink == toScheduleId }) else {
            showToast("Schedule not found", icon: "exclamationmark.circle", type: .error)
            return
        }
        
        // First, cancel the original booking
        let originalSlotsNeeded = Int(ceil(Double(originalSlot.services.reduce(0) { $0 + $1.duration }) / 15.0))
        if let originalStartIndex = schedules[fromIndex].timeSlots.firstIndex(where: { $0.id == originalSlot.id }) {
            for i in 0..<originalSlotsNeeded {
                let clearIndex = originalStartIndex + i
                if clearIndex < schedules[fromIndex].timeSlots.count {
                    schedules[fromIndex].timeSlots[clearIndex].isBooked = false
                    schedules[fromIndex].timeSlots[clearIndex].customerName = nil
                    schedules[fromIndex].timeSlots[clearIndex].customerPhone = nil
                    schedules[fromIndex].timeSlots[clearIndex].customerEmail = nil
                    schedules[fromIndex].timeSlots[clearIndex].notes = nil
                    schedules[fromIndex].timeSlots[clearIndex].services = []
                }
            }
        }
        
        // Then, book the new slots on the target schedule
        let newSlotsNeeded = Int(ceil(Double(services.reduce(0) { $0 + $1.duration }) / 15.0))
        if let newStartIndex = schedules[toIndex].timeSlots.firstIndex(where: { $0.id == newSlot.id }) {
            // Check if all needed slots are available
            for i in 0..<newSlotsNeeded {
                let checkIndex = newStartIndex + i
                if checkIndex >= schedules[toIndex].timeSlots.count ||
                   schedules[toIndex].timeSlots[checkIndex].isBooked {
                    showToast("Selected time slot is not available", icon: "clock.badge.xmark", type: .error)
                    return
                }
            }
            
            // Book the slots
            for i in 0..<newSlotsNeeded {
                let bookIndex = newStartIndex + i
                if bookIndex < schedules[toIndex].timeSlots.count {
                    schedules[toIndex].timeSlots[bookIndex].isBooked = true
                    if i == 0 {
                        schedules[toIndex].timeSlots[bookIndex].customerName = customerName
                        schedules[toIndex].timeSlots[bookIndex].customerPhone = customerPhone.replacingOccurrences(of: " ", with: "")
                        schedules[toIndex].timeSlots[bookIndex].customerEmail = customerEmail
                        schedules[toIndex].timeSlots[bookIndex].notes = notes
                        schedules[toIndex].timeSlots[bookIndex].services = services
                    }
                }
            }
        }
        
        // Save both schedules
        saveSchedules(schedule: schedules[fromIndex])
        saveSchedules(schedule: schedules[toIndex])
        
        // Add to calendar for the new date
        if let newStartIndex = schedules[toIndex].timeSlots.firstIndex(where: { $0.id == newSlot.id }) {
            addToCalendar(schedule: schedules[toIndex], slot: schedules[toIndex].timeSlots[newStartIndex])
        }
        
        showToast("Booking moved successfully! 📅", icon: "calendar.badge.checkmark", type: .success)
    }
    
    // MARK: - Booking Helpers
    
    func getUniqueBookings(for schedule: DaySchedule) -> [(slot: TimeSlot, isPrimary: Bool)] {
        var bookings: [(slot: TimeSlot, isPrimary: Bool)] = []
        var processedIndices = Set<Int>()
        
        for (index, slot) in schedule.timeSlots.enumerated() {
            if slot.isBooked && !processedIndices.contains(index) {
                // This is a primary booking slot
                if slot.customerName != nil && !slot.services.isEmpty {
                    bookings.append((slot: slot, isPrimary: true))
                    processedIndices.insert(index)
                    
                    // Mark continuation slots
                    let slotsNeeded = Int(ceil(Double(slot.services.reduce(0) { $0 + $1.duration }) / 15.0))
                    for i in 1..<slotsNeeded {
                        let nextIndex = index + i
                        if nextIndex < schedule.timeSlots.count {
                            processedIndices.insert(nextIndex)
                        }
                    }
                }
            }
        }
        
        return bookings
    }
    
    func getUniqueBookingCount(for schedule: DaySchedule) -> Int {
        return getUniqueBookings(for: schedule).count
    }
    
    func getDailyRevenue(for schedule: DaySchedule) -> Double {
        let uniqueBookings = getUniqueBookings(for: schedule)
        return uniqueBookings.reduce(0) { total, booking in
            total + booking.slot.services.reduce(0) { $0 + $1.price }
        }
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
                    "customerEmail": slot.customerEmail ?? "",
                    "notes": slot.notes ?? "",
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
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                if let error = error {
                    print("Error loading schedules: \(error)")
                    DispatchQueue.main.async {
                        self.errorOccurred = true
                        self.alertMessage = "Failed to load schedules. Please check your connection."
                        self.showingAlert = true
                    }
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
                        slot.customerEmail = slotData["customerEmail"] as? String
                        slot.notes = slotData["notes"] as? String
                        
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
