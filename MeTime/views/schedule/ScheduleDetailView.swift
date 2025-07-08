//
//  ScheduleDetailView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct ScheduleDetailView: View {
    let schedule: DaySchedule
    @ObservedObject var viewModel: BookingViewModel
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Booking Link Section
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Booking Link", systemImage: "link.circle.fill")
                                .font(.headline)
                                .foregroundColor(Color.theme.accent)
                            
                            Text(viewModel.generateLink(for: schedule))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.gray)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.theme.secondary.opacity(0.9))
                                .cornerRadius(10)
                            
                            PrimaryButton("Copy Link", icon: "doc.on.doc.fill") {
                                viewModel.copyLinkToClipboard(for: schedule)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bookings Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Appointments 💅")
                            .font(.headline)
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal)
                        
                        ForEach(schedule.timeSlots.filter { $0.isBooked && $0.customerName != nil }) { slot in
                            GlassCardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(formatTime(slot.startTime))
                                            .font(.headline)
                                            .foregroundColor(Color.theme.accent)
                                        
                                        Text("-")
                                            .foregroundColor(Color.theme.textPrimary.opacity(0.5))
                                        
                                        Text(formatTime(slot.endTime))
                                            .font(.headline)
                                            .foregroundColor(Color.theme.accent)
                                        
                                        Spacer()
                                        
                                        Text("$\(Int(slot.services.reduce(0) { $0 + $1.price }))")
                                            .font(.headline)
                                            .foregroundColor(Color.theme.primary)
                                    }
                                    
                                    Divider()
                                        .background(Color.theme.secondary)
                                    
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Color.theme.accent)
                                        Text(slot.customerName ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.textPrimary)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(Color.theme.accent)
                                        Text(slot.customerPhone ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.textPrimary)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(Color.theme.accent)
                                        Text(slot.services.map { "\($0.emoji) \($0.name)" }.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.textPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(formatDate(schedule.date))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ScheduleDetailView(schedule: DaySchedule(date: Date()), viewModel: BookingViewModel())
        .environmentObject(BookingViewModel())
}
