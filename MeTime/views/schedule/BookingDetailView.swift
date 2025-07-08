//
//  BookingDetailView.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

struct BookingDetailView: View {
    let schedule: DaySchedule
    let slot: TimeSlot
    @ObservedObject var viewModel: BookingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingCallAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Customer Info Card
                        GlassCardView {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Customer Information", systemImage: "person.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    InfoRow(icon: "person.fill", title: "Name", value: slot.customerName ?? "")
                                    InfoRow(icon: "phone.fill", title: "Phone", value: slot.customerPhone ?? "")
                                    if let email = slot.customerEmail, !email.isEmpty {
                                        InfoRow(icon: "envelope.fill", title: "Email", value: email)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Booking Details Card
                        GlassCardView {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Booking Details", systemImage: "calendar.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    InfoRow(icon: "calendar", title: "Date", value: formatDate(schedule.date))
                                    InfoRow(icon: "clock.fill", title: "Time", value: "\(formatTime(slot.startTime)) - \(formatTime(slot.endTime))")
                                    InfoRow(icon: "timer", title: "Duration", value: "\(totalDuration) minutes")
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Services Card
                        GlassCardView {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Services", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(slot.services) { service in
                                        HStack {
                                            Text("\(service.emoji) \(service.name)")
                                                .font(.subheadline)
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text("\(Int(service.price)) kr")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(ColorTheme.primary)
                                                Text("\(service.duration) min")
                                                    .font(.caption)
                                                    .foregroundColor(ColorTheme.secondary)
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Total")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(totalPrice) kr")
                                            .font(.headline)
                                            .foregroundColor(ColorTheme.accent)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Notes Card (if any)
                        if let notes = slot.notes, !notes.isEmpty {
                            GlassCardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Notes", systemImage: "note.text")
                                        .font(.headline)
                                        .foregroundColor(ColorTheme.accent)
                                    
                                    Text(notes)
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Call Button
                            GradientActionButton(
                                title: "Call Customer",
                                icon: "phone.fill",
                                gradient: [ColorTheme.success, ColorTheme.success.opacity(0.8)],
                                action: { showingCallAlert = true }
                            )
                            
                            // Edit Button
                            GradientActionButton(
                                title: "Edit Booking",
                                icon: "pencil",
                                gradient: [ColorTheme.primary, ColorTheme.primary.opacity(0.8)],
                                action: { showingEditView = true }
                            )
                            
                            // Delete Button
                            GradientActionButton(
                                title: "Delete Booking",
                                icon: "trash",
                                gradient: [ColorTheme.error, ColorTheme.error.opacity(0.8)],
                                action: { showingDeleteAlert = true }
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditBookingView(
                    schedule: schedule,
                    slot: slot,
                    viewModel: viewModel,
                    isPresented: $showingEditView
                )
            }
            .customAlert(
                isPresented: $showingCallAlert,
                title: "Call Customer",
                message: "Call \(slot.customerName ?? "customer") at \(slot.customerPhone ?? "")?",
                primaryButtonTitle: "Call",
                secondaryButtonTitle: "Cancel",
                primaryAction: {
                    if let phone = slot.customerPhone,
                       let url = URL(string: "tel://\(phone)") {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryAction: {},
                icon: "phone.fill",
                iconColor: ColorTheme.success
            )
            .customAlert(
                isPresented: $showingDeleteAlert,
                title: "Delete Booking?",
                message: "Are you sure you want to delete \(slot.customerName ?? "")'s booking? This action cannot be undone.",
                primaryButtonTitle: "Delete",
                secondaryButtonTitle: "Cancel",
                primaryAction: {
                    withAnimation {
                        viewModel.cancelBooking(scheduleId: schedule.uniqueLink, slotId: slot.id)
                        dismiss()
                    }
                },
                secondaryAction: {},
                icon: "trash.fill",
                iconColor: ColorTheme.error
            )
            .toast($viewModel.currentToast)
        }
    }
    
    var totalDuration: Int {
        slot.services.reduce(0) { $0 + $1.duration }
    }
    
    var totalPrice: Int {
        Int(slot.services.reduce(0) { $0 + $1.price })
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

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(ColorTheme.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textPrimary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    BookingDetailView(
        schedule: DaySchedule(date: Date()),
        slot: TimeSlot(startTime: Date(), services: []),
        viewModel: BookingViewModel()
    )
}
