//
//  EditBookingView.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

struct EditBookingView: View {
    let originalSchedule: DaySchedule
    let originalSlot: TimeSlot
    @ObservedObject var viewModel: BookingViewModel
    @Binding var isPresented: Bool
    
    @State private var currentStep = 1
    @State private var customerName: String = ""
    @State private var customerPhone: String = ""
    @State private var customerEmail: String = ""
    @State private var selectedServices: [Service] = []
    @State private var selectedDate: Date
    @State private var selectedSchedule: DaySchedule?
    @State private var selectedTimeSlot: TimeSlot?
    @State private var notes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDatePicker = false
    
    init(schedule: DaySchedule, slot: TimeSlot, viewModel: BookingViewModel, isPresented: Binding<Bool>) {
        self.originalSchedule = schedule
        self.originalSlot = slot
        self.viewModel = viewModel
        self._isPresented = isPresented
        
        // Initialize state with current booking data
        _customerName = State(initialValue: slot.customerName ?? "")
        _customerPhone = State(initialValue: slot.customerPhone ?? "")
        _customerEmail = State(initialValue: slot.customerEmail ?? "")
        _selectedServices = State(initialValue: slot.services)
        _selectedDate = State(initialValue: schedule.date)
        _selectedSchedule = State(initialValue: schedule)
        _selectedTimeSlot = State(initialValue: slot)
        _notes = State(initialValue: slot.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Indicator
                    ProgressIndicator(currentStep: currentStep)
                        .padding()
                    
                    // Content
                    TabView(selection: $currentStep) {
                        CustomerDetailsStep()
                            .tag(1)
                        
                        ServicesSelectionStep()
                            .tag(2)
                        
                        DateSelectionStep()
                            .tag(3)
                        
                        TimeSelectionStep()
                            .tag(4)
                        
                        ReviewStep()
                            .tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Navigation Buttons
                    HStack {
                        if currentStep > 1 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(ColorTheme.accent)
                        }
                        
                        Spacer()
                        
                        if currentStep < 5 {
                            Button("Next") {
                                if validateCurrentStep() {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                            }
                            .foregroundColor(ColorTheme.accent)
                            .fontWeight(.semibold)
                        } else {
                            Button("Save Changes") {
                                saveChanges()
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(ColorTheme.accent)
                            .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .toast($viewModel.currentToast)
        }
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    func CustomerDetailsStep() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Customer Information")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Name", systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondary)
                            
                            TextField("Customer name", text: $customerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Phone", systemImage: "phone.fill")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondary)
                            
                            TextField("Phone number", text: $customerPhone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email (Optional)", systemImage: "envelope.fill")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondary)
                            
                            TextField("Email address", text: $customerEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes (Optional)", systemImage: "note.text")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondary)
                            
                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .padding(8)
                                .background(ColorTheme.secondary.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    func ServicesSelectionStep() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Select Services")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        ForEach(viewModel.services) { service in
                            ServiceRow(
                                service: service,
                                isSelected: selectedServices.contains(where: { $0.id == service.id }),
                                action: {
                                    toggleService(service)
                                }
                            )
                        }
                    }
                }
                .padding()
                
                if !selectedServices.isEmpty {
                    GlassCardView {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Total Duration")
                                    .foregroundColor(ColorTheme.secondary)
                                Spacer()
                                Text("\(totalDuration) minutes")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Total Price")
                                    .foregroundColor(ColorTheme.secondary)
                                Spacer()
                                Text("$\(totalPrice)")
                                    .fontWeight(.bold)
                                    .foregroundColor(ColorTheme.accent)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    func DateSelectionStep() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Select Date")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        Text("Current: \(formatDate(originalSchedule.date))")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondary)
                        
                        // Quick Actions
                        VStack(spacing: 12) {
                            QuickDateButton(
                                title: "Keep Same Day",
                                subtitle: formatDate(originalSchedule.date),
                                isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date),
                                action: {
                                    selectedDate = originalSchedule.date
                                    if let schedule = viewModel.schedules.first(where: { 
                                        Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
                                    }) {
                                        selectedSchedule = schedule
                                    }
                                }
                            )
                            
                            QuickDateButton(
                                title: "Move to Tomorrow",
                                subtitle: formatDate(Date().addingTimeInterval(86400)),
                                isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: Date().addingTimeInterval(86400)),
                                action: {
                                    let tomorrow = Date().addingTimeInterval(86400)
                                    selectedDate = tomorrow
                                    if let schedule = viewModel.schedules.first(where: { 
                                        Calendar.current.isDate($0.date, inSameDayAs: tomorrow)
                                    }) {
                                        selectedSchedule = schedule
                                    } else {
                                        // Create new schedule for tomorrow if it doesn't exist
                                        viewModel.createScheduleForDate(tomorrow)
                                        selectedSchedule = viewModel.schedules.first(where: { 
                                            Calendar.current.isDate($0.date, inSameDayAs: tomorrow)
                                        })
                                    }
                                }
                            )
                            
                            // Find Next Available
                            if let nextAvailable = findNextAvailableDate() {
                                QuickDateButton(
                                    title: "Next Available",
                                    subtitle: formatDate(nextAvailable),
                                    isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: nextAvailable),
                                    action: {
                                        selectedDate = nextAvailable
                                        if let schedule = viewModel.schedules.first(where: { 
                                            Calendar.current.isDate($0.date, inSameDayAs: nextAvailable)
                                        }) {
                                            selectedSchedule = schedule
                                        }
                                    }
                                )
                            }
                            
                            Divider()
                            
                            Button(action: { showingDatePicker = true }) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Choose Another Date")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(ColorTheme.primary)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding()
                
                // Show existing schedules with availability
                if !viewModel.schedules.isEmpty {
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Upcoming Availability")
                                .font(.headline)
                                .foregroundColor(ColorTheme.accent)
                            
                            ForEach(viewModel.schedules.sorted(by: { $0.date < $1.date }).prefix(7)) { schedule in
                                ScheduleAvailabilityRow(
                                    schedule: schedule,
                                    requiredDuration: totalDuration,
                                    isSelected: selectedSchedule?.id == schedule.id,
                                    action: {
                                        selectedDate = schedule.date
                                        selectedSchedule = schedule
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate) { date in
                selectedDate = date
                if let schedule = viewModel.schedules.first(where: { 
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }) {
                    selectedSchedule = schedule
                } else {
                    // Create new schedule if it doesn't exist
                    viewModel.createScheduleForDate(date)
                    selectedSchedule = viewModel.schedules.first(where: { 
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    })
                }
                showingDatePicker = false
            }
        }
    }
    
    @ViewBuilder
    func TimeSelectionStep() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Select Time")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        HStack {
                            Text("Date: \(formatDate(selectedDate))")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textPrimary)
                            Spacer()
                            Text("Duration: \(totalDuration) min")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondary)
                        }
                        
                        if Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date) {
                            Text("Current: \(formatTime(originalSlot.startTime)) - \(formatTime(originalSlot.endTime))")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondary)
                        }
                        
                        if let schedule = selectedSchedule {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(getAvailableTimeSlots(for: schedule)) { timeSlot in
                                    TimeSlotButton(
                                        timeSlot: timeSlot,
                                        isSelected: selectedTimeSlot?.id == timeSlot.id,
                                        isOriginal: Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date) && 
                                                   timeSlot.id == originalSlot.id,
                                        action: {
                                            selectedTimeSlot = timeSlot
                                        }
                                    )
                                }
                            }
                            
                            if getAvailableTimeSlots(for: schedule).isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(ColorTheme.secondary)
                                    Text("No available time slots for the selected services")
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 30)
                            }
                        } else {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    func ReviewStep() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Review Changes")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            ReviewRow(title: "Customer", value: customerName, icon: "person.fill")
                            ReviewRow(title: "Phone", value: customerPhone, icon: "phone.fill")
                            if !customerEmail.isEmpty {
                                ReviewRow(title: "Email", value: customerEmail, icon: "envelope.fill")
                            }
                            if !notes.isEmpty {
                                ReviewRow(title: "Notes", value: notes, icon: "note.text")
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Services", systemImage: "sparkles")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondary)
                                
                                ForEach(selectedServices) { service in
                                    HStack {
                                        Text("\(service.emoji) \(service.name)")
                                        Spacer()
                                        Text("$\(service.price)")
                                            .foregroundColor(ColorTheme.accent)
                                    }
                                    .font(.footnote)
                                }
                            }
                            
                            Divider()
                            
                            ReviewRow(
                                title: "Date",
                                value: formatDate(selectedDate),
                                icon: "calendar"
                            )
                            
                            if !Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(ColorTheme.accent)
                                    Text("Moving from \(formatDate(originalSchedule.date))")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.accent)
                                }
                            }
                            
                            if let timeSlot = selectedTimeSlot {
                                ReviewRow(
                                    title: "Time",
                                    value: "\(formatTime(timeSlot.startTime)) - \(formatTime(timeSlot.endTime))",
                                    icon: "clock.fill"
                                )
                            }
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("$\(totalPrice)")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.accent)
                            }
                            .padding(.top)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    
    struct ServiceRow: View {
        let service: Service
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text("\(service.emoji) \(service.name)")
                        .foregroundColor(ColorTheme.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(service.price)")
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.accent)
                        Text("\(service.duration) min")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondary)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? ColorTheme.accent : ColorTheme.secondary)
                }
                .padding()
                .background(isSelected ? ColorTheme.accent.opacity(0.1) : Color.clear)
                .cornerRadius(10)
            }
        }
    }
    
    struct TimeSlotButton: View {
        let timeSlot: TimeSlot
        let isSelected: Bool
        var isOriginal: Bool = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Text(formatTime(timeSlot.startTime))
                        .font(.system(size: 14, weight: .medium))
                    Text(formatTime(timeSlot.endTime))
                        .font(.system(size: 12))
                        .foregroundColor(isOriginal ? ColorTheme.accent : ColorTheme.secondary)
                    
                    if isOriginal {
                        Text("Current")
                            .font(.system(size: 10))
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? ColorTheme.accent : ColorTheme.secondary.opacity(0.3)
                )
                .foregroundColor(
                    isSelected ? .white : ColorTheme.textPrimary
                )
                .cornerRadius(10)
                .overlay(
                    isOriginal ? 
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ColorTheme.accent, lineWidth: 2)
                    : nil
                )
            }
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    struct QuickDateButton: View {
        let title: String
        let subtitle: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.accent)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? ColorTheme.accent.opacity(0.1) : ColorTheme.secondary.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? ColorTheme.accent : Color.clear, lineWidth: 2)
                )
            }
            .foregroundColor(ColorTheme.textPrimary)
        }
    }
    
    struct ScheduleAvailabilityRow: View {
        let schedule: DaySchedule
        let requiredDuration: Int
        let isSelected: Bool
        let action: () -> Void
        
        var availableSlots: Int {
            let slotsNeeded = Int(ceil(Double(requiredDuration) / 15.0))
            var count = 0
            
            for i in 0..<schedule.timeSlots.count {
                var canBook = true
                for j in 0..<slotsNeeded {
                    if i + j >= schedule.timeSlots.count || schedule.timeSlots[i + j].isBooked {
                        canBook = false
                        break
                    }
                }
                if canBook {
                    count += 1
                }
            }
            
            return count
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDate(schedule.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(availableSlots) slots available")
                            .font(.caption)
                            .foregroundColor(availableSlots > 0 ? ColorTheme.secondary : Color.red)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.accent)
                    } else if availableSlots > 0 {
                        Image(systemName: "chevron.right")
                            .foregroundColor(ColorTheme.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .disabled(availableSlots == 0)
            .opacity(availableSlots == 0 ? 0.5 : 1.0)
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    struct DatePickerSheet: View {
        @Binding var selectedDate: Date
        let onSelect: (Date) -> Void
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .navigationTitle("Choose Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Select") {
                            onSelect(selectedDate)
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    struct ReviewRow: View {
        let title: String
        let value: String
        let icon: String
        
        var body: some View {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Text(value)
                    .foregroundColor(ColorTheme.textPrimary)
                
                Spacer()
            }
        }
    }
    
    struct ProgressIndicator: View {
        let currentStep: Int
        
        var body: some View {
            HStack(spacing: 20) {
                ForEach(1...5, id: \.self) { step in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(step <= currentStep ? ColorTheme.accent : ColorTheme.secondary)
                            .frame(width: 25, height: 25)
                            .overlay(
                                Text("\(step)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(step <= currentStep ? .white : ColorTheme.secondary)
                            )
                        
                        Text(stepTitle(for: step))
                            .font(.system(size: 10))
                            .foregroundColor(step <= currentStep ? ColorTheme.textPrimary : ColorTheme.secondary)
                    }
                    
                    if step < 5 {
                        Rectangle()
                            .fill(step < currentStep ? ColorTheme.accent : ColorTheme.secondary)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        
        func stepTitle(for step: Int) -> String {
            switch step {
            case 1: return "Details"
            case 2: return "Services"
            case 3: return "Date"
            case 4: return "Time"
            case 5: return "Review"
            default: return ""
            }
        }
    }
    
    // MARK: - Helper Functions
    
    var totalDuration: Int {
        selectedServices.reduce(0) { $0 + $1.duration }
    }
    
    var totalPrice: Int {
        Int(selectedServices.reduce(0) { $0 + $1.price })
    }
    
    func toggleService(_ service: Service) {
        if let index = selectedServices.firstIndex(where: { $0.id == service.id }) {
            selectedServices.remove(at: index)
        } else {
            selectedServices.append(service)
        }
    }
    
    func getAvailableTimeSlots(for schedule: DaySchedule) -> [TimeSlot] {
        let slotsNeeded = Int(ceil(Double(totalDuration) / 15.0))
        var availableSlots: [TimeSlot] = []
        
        for i in 0..<schedule.timeSlots.count {
            let slot = schedule.timeSlots[i]
            
            // Check if this is the original slot (when on same day)
            let isOriginalSlot = Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date) && 
                               slot.id == originalSlot.id
            
            // Check if we have enough consecutive slots
            var canBook = true
            for j in 0..<slotsNeeded {
                if i + j >= schedule.timeSlots.count {
                    canBook = false
                    break
                }
                let checkSlot = schedule.timeSlots[i + j]
                // Allow if it's not booked OR if it's part of the original booking
                if checkSlot.isBooked && !isOriginalSlot {
                    canBook = false
                    break
                }
            }
            
            if canBook {
                availableSlots.append(slot)
            }
        }
        
        return availableSlots
    }
    
    func findNextAvailableDate() -> Date? {
        let today = Date()
        let calendar = Calendar.current
        _ = Int(ceil(Double(totalDuration) / 15.0))
        
        // Check up to 30 days in the future
        for dayOffset in 1...30 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Check if schedule exists for this date
            if let schedule = viewModel.schedules.first(where: { 
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }) {
                // Check if there are available slots
                if getAvailableTimeSlots(for: schedule).count > 0 {
                    return checkDate
                }
            } else {
                // No schedule exists, so this date is fully available
                return checkDate
            }
        }
        
        return nil
    }
    
    func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            if customerName.isEmpty {
                alertMessage = "Please enter customer name"
                showingAlert = true
                return false
            }
            if customerPhone.isEmpty {
                alertMessage = "Please enter phone number"
                showingAlert = true
                return false
            }
            if !viewModel.isValidDanishPhone(customerPhone) {
                alertMessage = "Please enter a valid Danish phone number (+45XXXXXXXX)"
                showingAlert = true
                return false
            }
            return true
            
        case 2:
            if selectedServices.isEmpty {
                alertMessage = "Please select at least one service"
                showingAlert = true
                return false
            }
            return true
            
        case 3:
            if selectedSchedule == nil {
                alertMessage = "Please select a date"
                showingAlert = true
                return false
            }
            return true
            
        case 4:
            if selectedTimeSlot == nil {
                alertMessage = "Please select a time slot"
                showingAlert = true
                return false
            }
            return true
            
        default:
            return true
        }
    }
    
    func saveChanges() {
        guard let timeSlot = selectedTimeSlot,
              let targetSchedule = selectedSchedule else { return }
        
        // Check if we're moving to a different day
        if !Calendar.current.isDate(selectedDate, inSameDayAs: originalSchedule.date) {
            // Moving to a different day - need to handle cross-schedule booking
            viewModel.moveBookingBetweenSchedules(
                fromScheduleId: originalSchedule.uniqueLink,
                toScheduleId: targetSchedule.uniqueLink,
                originalSlot: originalSlot,
                newSlot: timeSlot,
                customerName: customerName,
                customerPhone: customerPhone,
                customerEmail: customerEmail,
                services: selectedServices,
                notes: notes
            )
        } else {
            // Same day - just update the booking
            viewModel.updateBooking(
                scheduleId: originalSchedule.uniqueLink,
                originalSlot: originalSlot,
                newSlot: timeSlot,
                customerName: customerName,
                customerPhone: customerPhone,
                customerEmail: customerEmail,
                services: selectedServices,
                notes: notes
            )
        }
        
        isPresented = false
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    EditBookingView(
        schedule: DaySchedule(date: Date()),
        slot: TimeSlot(startTime: Date(), services: []),
        viewModel: BookingViewModel(),
        isPresented: .constant(true)
    )
}
