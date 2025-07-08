//
//  CustomButtons.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

// Gradient Action Button with subtle animation
struct GradientActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: gradient[0].opacity(0.3), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Neumorphic Button for secondary actions
struct NeumorphicButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(ColorTheme.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.surface)
                        .shadow(color: Color.black.opacity(0.3), radius: isPressed ? 2 : 5, x: isPressed ? 0 : 3, y: isPressed ? 0 : 3)
                        .shadow(color: Color.white.opacity(0.05), radius: isPressed ? 2 : 5, x: isPressed ? 0 : -3, y: isPressed ? 0 : -3)
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Floating Action Button with pulse animation
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTheme.gradientStart, ColorTheme.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: ColorTheme.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPulsing ? 1.1 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// Custom Menu Button with glassmorphism
struct GlassMenuButton: View {
    @Binding var isExpanded: Bool
    let actions: [(title: String, icon: String, color: Color, action: () -> Void)]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Action buttons
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                            action.action()
                        }) {
                            HStack {
                                Text(action.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorTheme.textPrimary)
                                
                                Image(systemName: action.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(action.color)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(action.color.opacity(0.2))
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(ColorTheme.surface.opacity(0.9))
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05), value: isExpanded)
                    }
                }
                .padding(.bottom, 70)
            }
            
            // Main menu button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ColorTheme.primary, ColorTheme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: ColorTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
    }
}

// Pill Selection Button
struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : ColorTheme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? 
                              LinearGradient(
                                colors: [ColorTheme.gradientStart, ColorTheme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                              ) : 
                              LinearGradient(
                                colors: [ColorTheme.surface, ColorTheme.surface],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : ColorTheme.secondary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: isSelected ? ColorTheme.accent.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
