//
//  CustomMenuButton.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

struct CustomMenuButton: View {
    let schedule: DaySchedule
    let slot: TimeSlot
    @ObservedObject var viewModel: BookingViewModel
    @Binding var showingDetailView: Bool
    var showDeleteAlert: () -> Void = {}
    
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    @State private var showSwipeHint = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Background blur when expanded
            if isExpanded {
                Color.black.opacity(0.001)
                    .frame(maxWidth: .infinity, maxHeight: 250)
                    .offset(x: -150)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }
            }
            
            // Expanded actions with staggered animation
            if isExpanded {
                HStack(spacing: 12) {
                    // Call button
                    ActionCircleButton(
                        icon: "phone.fill",
                        color: ColorTheme.success,
                        label: "Call",
                        action: {
                            if let phone = slot.customerPhone,
                               let url = URL(string: "tel://\(phone)") {
                                UIApplication.shared.open(url)
                            }
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.1)),
                        removal: .scale.combined(with: .opacity)
                    ))
                    
                    // Edit button
                    ActionCircleButton(
                        icon: "pencil",
                        color: ColorTheme.primary,
                        label: "Edit",
                        action: {
                            showingDetailView = true
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.05)),
                        removal: .scale.combined(with: .opacity)
                    ))
                    
                    // Delete button
                    ActionCircleButton(
                        icon: "trash.fill",
                        color: ColorTheme.error,
                        label: "Delete",
                        action: {
                            showDeleteAlert()
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.7)),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
                .padding(.trailing, 45)
                .allowsHitTesting(isExpanded)
            }
            
            // Menu button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    // Swipe hint indicator
                    if !isExpanded && dragOffset.width < 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { _ in
                                Circle()
                                    .fill(ColorTheme.primary.opacity(0.3))
                                    .frame(width: 3, height: 3)
                            }
                        }
                        .offset(x: -40)
                        .opacity(Double(-dragOffset.width / 50))
                    }
                    
                    // Background circles for visual effect
                    Circle()
                        .fill(ColorTheme.accent.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isExpanded ? 1.2 : 0)
                        .opacity(isExpanded ? 1 : 0)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isExpanded ? 
                                    [ColorTheme.accent, ColorTheme.gradientEnd] : 
                                    [ColorTheme.primary.opacity(0.8), ColorTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: isExpanded ? "xmark" : "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .scaleEffect(isExpanded ? 0.8 : 1.0)
                }
            }
            .zIndex(1000)
            .shadow(color: isExpanded ? ColorTheme.accent.opacity(0.4) : ColorTheme.primary.opacity(0.2),
                    radius: isExpanded ? 8 : 4, 
                    x: 0, 
                    y: 2)
            .scaleEffect(1.0 + (dragOffset.width > 0 ? dragOffset.width / 1000 : 0))
            .offset(dragOffset)
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 && !isExpanded {
                            dragOffset = CGSize(width: value.translation.width / 3, height: 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -50 && !isExpanded {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                isExpanded = true
                            }
                            dragOffset = .zero
                        }
                    }
            )
        }
    }
}

struct ActionCircleButton: View {
    let icon: String
    let color: Color
    var label: String = ""
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
            
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .blur(radius: isPressed ? 8 : 4)
                        .scaleEffect(isPressed ? 1.3 : 1.0)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .shadow(color: color.opacity(0.4), radius: isPressed ? 8 : 4, x: 0, y: isPressed ? 4 : 2)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ColorTheme.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CustomMenuButton(schedule: DaySchedule(date: Date()), slot: TimeSlot(startTime: Date()), viewModel: BookingViewModel(), showingDetailView: .constant(false))
}
