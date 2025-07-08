//
//  ContentView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BookingViewModel()
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.theme.background, Color.theme.secondary.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 5) {
                        Text("✨ Nail Studio ✨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.accent)
                        
                        Text("Booking Management")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textPrimary.opacity(0.7))
                    }
                    .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.schedules.sorted(by: { $0.date < $1.date })) { schedule in
                                NavigationLink(destination: ScheduleDetailView(schedule: schedule, viewModel: viewModel)) {
                                    GlassCardView {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(formatDate(schedule.date))
                                                    .font(.headline)
                                                    .foregroundColor(Color.theme.textPrimary)
                                                
                                                let bookedCount = schedule.timeSlots.filter { $0.isBooked }.count
                                                HStack(spacing: 5) {
                                                    Image(systemName: "person.fill")
                                                        .font(.caption)
                                                    Text("\(bookedCount) bookings")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(Color.theme.accent)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(Color.theme.primary)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
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
            .alert("Notice", isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
