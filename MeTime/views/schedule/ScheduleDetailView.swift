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
            ColorTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Booking Link Section
                GlassCardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Booking Link", systemImage: "link.circle.fill")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        
                        Text(viewModel.generateLink(for: schedule))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.gray)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.secondary.opacity(0.9))
                            .cornerRadius(10)
                        
                        PrimaryButton("Copy Link", icon: "doc.on.doc.fill") {
                            viewModel.copyLinkToClipboard(for: schedule)
                        }
                    }
                }
                .padding()
                
                // Bookings Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appointments 💅")
                            .font(.headline)
                            .foregroundColor(ColorTheme.accent)
                        Text("Tap any booking to manage")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Bookings List
                let uniqueBookings = viewModel.getUniqueBookings(for: schedule).filter { $0.isPrimary }
                
                if uniqueBookings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(ColorTheme.secondary)
                        Text("No bookings yet")
                            .font(.headline)
                            .foregroundColor(ColorTheme.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 50)
                } else {
                    List {
                        ForEach(uniqueBookings.map { $0.slot }) { slot in
                            BookingRowView(schedule: schedule, slot: slot, viewModel: viewModel)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(formatDate(schedule.date))
        .navigationBarTitleDisplayMode(.inline)
        .toast($viewModel.currentToast)
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

// Booking Row Component
struct BookingRowView: View {
    let schedule: DaySchedule
    let slot: TimeSlot
    @ObservedObject var viewModel: BookingViewModel
    @State private var showingDetailView = false
    @State private var showingDeleteAlert = false
    @State private var slotToDelete: TimeSlot?
    
    var body: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(formatTime(slot.startTime))
                        .font(.headline)
                        .foregroundColor(ColorTheme.accent)
                    
                    Text("-")
                        .foregroundColor(ColorTheme.textPrimary.opacity(0.5))
                    
                    Text(formatTime(slot.endTime))
                        .font(.headline)
                        .foregroundColor(ColorTheme.accent)
                    
                    Spacer()
                    
                    Text("\(Int(slot.services.reduce(0) { $0 + $1.price })) kr")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primary)
                }
                
                Divider()
                    .background(ColorTheme.secondary)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(ColorTheme.accent)
                    Text(slot.customerName ?? "")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textPrimary)
                    
                    Spacer()
                    
                    // Custom Action Menu
                    CustomMenuButton(
                        schedule: schedule,
                        slot: slot,
                        viewModel: viewModel,
                        showingDetailView: $showingDetailView,
                        showDeleteAlert: {
                            slotToDelete = slot
                            showingDeleteAlert = true
                        }
                    )
                    .allowsTightening(false)
                    .background(Color.clear)
                    .onTapGesture {
                        // This prevents the parent tap gesture from firing
                    }
                }
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(ColorTheme.accent)
                    Text(slot.services.map { "\($0.emoji) \($0.name)" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(ColorTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetailView = true
            }
        }
        .sheet(isPresented: $showingDetailView) {
            BookingDetailView(
                schedule: schedule,
                slot: slot,
                viewModel: viewModel
            )
        }
        .customAlert(
            isPresented: $showingDeleteAlert,
            title: "Delete Booking?",
            message: "Are you sure you want to delete \(slotToDelete?.customerName ?? "")'s booking? This action cannot be undone.",
            primaryButtonTitle: "Delete",
            secondaryButtonTitle: "Cancel",
            primaryAction: {
                if let slotToDelete = slotToDelete {
                    withAnimation {
                        viewModel.cancelBooking(scheduleId: schedule.uniqueLink, slotId: slotToDelete.id)
                    }
                }
            },
            secondaryAction: {},
            icon: "trash.fill",
            iconColor: ColorTheme.error
        )
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
