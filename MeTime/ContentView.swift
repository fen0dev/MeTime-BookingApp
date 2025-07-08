//
//  ContentView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = BookingViewModel.shared
    @State private var searchText = ""
    @State private var showingSearch = false
    
    var todaysSchedule: DaySchedule? {
        let calendar = Calendar.current
        return viewModel.schedules.first { schedule in
            calendar.isDateInToday(schedule.date)
        }
    }
    
    var upcomingBookings: [(schedule: DaySchedule, slot: TimeSlot)] {
        let now = Date()
        var bookings: [(DaySchedule, TimeSlot)] = []
        
        for schedule in viewModel.schedules {
            let uniqueBookings = viewModel.getUniqueBookings(for: schedule)
            for (slot, isPrimary) in uniqueBookings where isPrimary {
                let slotDateTime = combineDateAndTime(date: schedule.date, time: slot.startTime)
                if slotDateTime > now {
                    bookings.append((schedule, slot))
                }
            }
        }
        
        return bookings.sorted { combineDateAndTime(date: $0.0.date, time: $0.1.startTime) < combineDateAndTime(date: $1.0.date, time: $1.1.startTime) }
    }
    
    var todaysRevenue: Int {
        guard let today = todaysSchedule else { return 0 }
        return Int(viewModel.getDailyRevenue(for: today))
    }
    
    var filteredSchedules: [DaySchedule] {
        if searchText.isEmpty {
            return viewModel.schedules.sorted(by: { $0.date < $1.date })
        } else {
            return viewModel.schedules.filter { schedule in
                schedule.timeSlots.contains { slot in
                    slot.customerName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                    slot.customerPhone?.contains(searchText) ?? false
                }
            }.sorted(by: { $0.date < $1.date })
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [ColorTheme.background, ColorTheme.secondary.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 5) {
                        Text("✨ MyBeautyCrave ✨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.accent)
                        
                        Text("Mariam - Booking Management")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.textPrimary.opacity(0.7))
                    }
                    .padding(.top)
                    .padding(.bottom, 6)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(ColorTheme.accent)
                            .scaleEffect(1.5)
                            .padding()
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Today's Overview
                            if let today = todaysSchedule {
                                GlassCardView {
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            Label("Today's Overview", systemImage: "star.fill")
                                                .font(.headline)
                                                .foregroundColor(ColorTheme.accent)
                                            Spacer()
                                            NavigationLink(destination: ScheduleDetailView(schedule: today, viewModel: viewModel)) {
                                                Text("View Details")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(ColorTheme.accent)
                                            }
                                        }
                                        
                                        HStack(spacing: 30) {
                                            VStack {
                                                Text("\(viewModel.getUniqueBookingCount(for: today))")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(ColorTheme.textPrimary)
                                                Text("Bookings")
                                                    .font(.caption)
                                                    .foregroundColor(ColorTheme.secondary)
                                            }
                                            
                                            VStack {
                                                Text("\(todaysRevenue) kr")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(ColorTheme.accent)
                                                Text("Revenue")
                                                    .font(.caption)
                                                    .foregroundColor(ColorTheme.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        // Next appointment
                                        if let nextBooking = upcomingBookings.first {
                                            Divider()
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Next Appointment")
                                                    .font(.caption)
                                                    .foregroundColor(ColorTheme.secondary)
                                                HStack {
                                                    Text(nextBooking.slot.customerName ?? "")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                    Spacer()
                                                    Text(formatTime(nextBooking.slot.startTime))
                                                        .font(.subheadline)
                                                        .foregroundColor(ColorTheme.accent)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Schedule List
                            VStack(alignment: .leading, spacing: 10) {
                                Text("All Schedules")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(filteredSchedules) { schedule in
                                    NavigationLink(destination: ScheduleDetailView(schedule: schedule, viewModel: viewModel)) {
                                        GlassCardView {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Text(formatDate(schedule.date))
                                                            .font(.headline)
                                                            .foregroundColor(ColorTheme.textPrimary)
                                                        
                                                        if Calendar.current.isDateInToday(schedule.date) {
                                                            Text("TODAY")
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 2)
                                                                .background(ColorTheme.accent)
                                                                .cornerRadius(5)
                                                        }
                                                    }
                                                    
                                                    let bookedCount = viewModel.getUniqueBookingCount(for: schedule)
                                                    let revenue = Int(viewModel.getDailyRevenue(for: schedule))
                                                    
                                                    HStack(spacing: 20) {
                                                        HStack(spacing: 5) {
                                                            Image(systemName: "person.fill")
                                                                .font(.caption)
                                                            Text("\(bookedCount) \(bookedCount == 1 ? "booking" : "bookings")")
                                                                .font(.caption)
                                                        }
                                                        .foregroundColor(ColorTheme.accent)
                                                        
                                                        HStack(spacing: 5) {
                                                            Image(systemName: "banknote")
                                                                .font(.caption)
                                                            Text("\(revenue) kr")
                                                                .font(.caption)
                                                        }
                                                        .foregroundColor(ColorTheme.primary)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(ColorTheme.primary)
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    PrimaryButton("Add New Date", icon: "calendar.badge.plus") {
                        viewModel.showingDatePicker = true
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingDatePicker) {
                DatePickerView(viewModel: viewModel)
            }
            .customAlert(
                isPresented: $viewModel.showingAlert,
                title: "Notice",
                message: viewModel.alertMessage,
                primaryButtonTitle: "OK",
                primaryAction: {},
                icon: "info.circle.fill",
                iconColor: ColorTheme.primary
            )
            .toast($viewModel.currentToast)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ContentView()
}
