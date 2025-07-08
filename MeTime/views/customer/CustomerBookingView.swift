//
//  CustomerBookingView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct CustomerBookingView: View {
    let scheduleId: String
    @StateObject private var viewModel = BookingViewModel()
    @State private var customerName = ""
    @State private var customerPhone = ""
    @State private var selectedServices: Set<Service> = []
    @State private var selectedSlot: TimeSlot?
    @State private var showingConfirmation = false
    @State private var currentStep = 1
    
    var schedule: DaySchedule? {
        viewModel.schedules.first { $0.uniqueLink == scheduleId }
    }
    
    var totalDuration: Int {
        selectedServices.reduce(0) { $0 + $1.duration }
    }
    
    var totalPrice: Double {
        selectedServices.reduce(0) { $0 + $1.price }
    }
    
    var availableSlots: [TimeSlot] {
        guard let schedule = schedule else { return [] }
        return schedule.getAvailableSlots(for: Array(selectedServices))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.theme.secondary.opacity(0.3), Color.theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if let schedule = schedule {
                    VStack {
                        // Progress Indicator
                        HStack(spacing: 30) {
                            ForEach(1...3, id: \.self) { step in
                                VStack(spacing: 5) {
                                    Circle()
                                        .fill(currentStep >= step ? Color.theme.accent : Color.theme.secondary)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text("\(step)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(step == 1 ? "Services" : step == 2 ? "Time" : "Details")
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.textPrimary)
                                }
                            }
                        }
                        .padding()
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                // Header
                                VStack(spacing: 10) {
                                    Text("Book Your Appointment")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.theme.accent)
                                    
                                    Text(formatDate(schedule.date))
                                        .font(.headline)
                                        .foregroundColor(Color.theme.textPrimary)
                                }
                                
                                if currentStep == 1 {
                                    // Step 1: Service Selection
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Select Your Services")
                                            .font(.headline)
                                            .foregroundColor(Color.theme.accent)
                                            .padding(.horizontal)
                                        
                                        ForEach(Service.available) { service in
                                            GlassCardView {
                                                HStack {
                                                    Text(service.emoji)
                                                        .font(.title)
                                                    
                                                    VStack(alignment: .leading, spacing: 5) {
                                                        Text(service.name)
                                                            .font(.headline)
                                                            .foregroundColor(Color.theme.textPrimary)
                                                        
                                                        HStack {
                                                            Label("\(service.duration) min", systemImage: "clock")
                                                                .font(.caption)
                                                            
                                                            Label("$\(Int(service.price))", systemImage: "dollarsign.circle")
                                                                .font(.caption)
                                                        }
                                                        .foregroundColor(Color.theme.textPrimary.opacity(0.7))
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: selectedServices.contains(service) ? "checkmark.circle.fill" : "circle")
                                                        .font(.title2)
                                                        .foregroundColor(selectedServices.contains(service) ? Color.theme.accent : Color.theme.secondary)
                                                }
                                            }
                                            .onTapGesture {
                                                if selectedServices.contains(service) {
                                                    selectedServices.remove(service)
                                                } else {
                                                    selectedServices.insert(service)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                        
                                        if !selectedServices.isEmpty {
                                            GlassCardView {
                                                VStack(spacing: 10) {
                                                    HStack {
                                                        Text("Total Duration:")
                                                        Spacer()
                                                        Text("\(totalDuration) minutes")
                                                            .fontWeight(.semibold)
                                                    }
                                                    
                                                    HStack {
                                                        Text("Total Price:")
                                                        Spacer()
                                                        Text("$\(Int(totalPrice))")
                                                            .fontWeight(.bold)
                                                            .foregroundColor(Color.theme.accent)
                                                    }
                                                }
                                                .font(.subheadline)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                if currentStep == 2 {
                                    // Step 2: Time Selection
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Select Your Time")
                                            .font(.headline)
                                            .foregroundColor(Color.theme.accent)
                                            .padding(.horizontal)
                                        
                                        if availableSlots.isEmpty {
                                            GlassCardView {
                                                VStack(spacing: 10) {
                                                    Image(systemName: "calendar.badge.exclamationmark")
                                                        .font(.largeTitle)
                                                        .foregroundColor(Color.theme.accent)
                                                    
                                                    Text("No available slots for selected services")
                                                        .font(.subheadline)
                                                        .foregroundColor(Color.theme.textPrimary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                            }
                                            .padding(.horizontal)
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                                ForEach(availableSlots) { slot in
                                                    Button(action: {
                                                        selectedSlot = slot
                                                    }) {
                                                        Text(formatTime(slot.startTime))
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.vertical, 12)
                                                            .background(
                                                                selectedSlot?.id == slot.id ?
                                                                Color.theme.accent :
                                                                Color.theme.secondary.opacity(0.3)
                                                            )
                                                            .foregroundColor(
                                                                selectedSlot?.id == slot.id ?
                                                                .white :
                                                                Color.theme.textPrimary
                                                            )
                                                            .cornerRadius(10)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                if currentStep == 3 {
                                    // Step 3: Personal Details
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("Your Information")
                                            .font(.headline)
                                            .foregroundColor(Color.theme.accent)
                                            .padding(.horizontal)
                                        
                                        GlassCardView {
                                            VStack(spacing: 15) {
                                                TextField("Your Name", text: $customerName)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                                
                                                TextField("Phone Number", text: $customerPhone)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                                    .keyboardType(.phonePad)
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // Summary
                                        GlassCardView {
                                            VStack(alignment: .leading, spacing: 15) {
                                                Text("Booking Summary")
                                                    .font(.headline)
                                                    .foregroundColor(Color.theme.accent)
                                                
                                                Divider()
                                                
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Label("Services", systemImage: "sparkles")
                                                        .font(.caption)
                                                        .foregroundColor(Color.theme.textPrimary.opacity(0.7))
                                                    
                                                    ForEach(Array(selectedServices)) { service in
                                                        Text("\(service.emoji) \(service.name)")
                                                            .font(.subheadline)
                                                    }
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Label("Time", systemImage: "clock")
                                                        .font(.caption)
                                                        .foregroundColor(Color.theme.textPrimary.opacity(0.7))
                                                    
                                                    if let slot = selectedSlot {
                                                        Text("\(formatTime(slot.startTime)) - \(formatTime(slot.startTime.addingTimeInterval(TimeInterval(totalDuration * 60))))")
                                                            .font(.subheadline)
                                                    }
                                                }
                                                
                                                Divider()
                                                
                                                HStack {
                                                    Text("Total")
                                                        .font(.headline)
                                                    Spacer()
                                                    Text("$\(Int(totalPrice))")
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Color.theme.accent)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 15) {
                            if currentStep > 1 {
                                Button(action: {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.theme.secondary.opacity(0.3))
                                    .foregroundColor(Color.theme.textPrimary)
                                    .cornerRadius(15)
                                }
                            }
                            
                            if currentStep < 3 {
                                Button(action: {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }) {
                                    HStack {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        (currentStep == 1 && selectedServices.isEmpty) ||
                                        (currentStep == 2 && selectedSlot == nil) ?
                                        Color.gray :
                                        Color.theme.accent
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                                .disabled(
                                    (currentStep == 1 && selectedServices.isEmpty) ||
                                    (currentStep == 2 && selectedSlot == nil)
                                )
                            } else {
                                Button(action: bookAppointment) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Book Appointment")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        customerName.isEmpty || customerPhone.isEmpty ?
                                        Color.gray :
                                        Color.theme.accent
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                                .disabled(customerName.isEmpty || customerPhone.isEmpty)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.theme.accent)
                        
                        Text("Invalid booking link")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Booking Confirmed! 🎉", isPresented: $showingConfirmation) {
                Button("OK") { }
            } message: {
                Text("Your appointment has been booked! You'll receive a confirmation soon.")
            }
        }
    }
    
    func bookAppointment() {
        guard let slot = selectedSlot else { return }
        viewModel.bookTimeSlot(
            scheduleId: scheduleId,
            slotId: slot.id,
            customerName: customerName,
            customerPhone: customerPhone,
            services: Array(selectedServices)
        )
        showingConfirmation = true
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    CustomerBookingView(scheduleId: UUID().uuidString)
}
