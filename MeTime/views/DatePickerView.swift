//
//  DatePickerView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct DatePickerView: View {
    @ObservedObject var viewModel: BookingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack {
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .accentColor(Color.theme.accent)
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(20)
                        .shadow(color: Color.theme.accent.opacity(0.1), radius: 10)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Date 📅")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color.theme.accent),
                trailing: Button("Create") {
                    viewModel.createScheduleForDate(viewModel.selectedDate)
                    dismiss()
                }
                .foregroundColor(Color.theme.accent)
                .fontWeight(.semibold)
            )
        }
    }
}

#Preview {
    DatePickerView(viewModel: BookingViewModel())
        .environmentObject(BookingViewModel())
}
