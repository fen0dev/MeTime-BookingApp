//
//  CustomAlert.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

struct CustomAlert: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    var secondaryButtonTitle: String? = nil
    let primaryAction: () -> Void
    var secondaryAction: (() -> Void)? = nil
    var icon: String = "exclamationmark.circle.fill"
    var iconColor: Color = ColorTheme.accent
    
    @Binding var isPresented: Bool
    @State private var animateIn = false
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(animateIn ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Optional: Allow dismissing by tapping background
                    // Comment out if you don't want this behavior
                    /*
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                    */
                }
            
            // Alert content
            VStack(spacing: 0) {
                // Icon section
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateIcon ? 1.2 : 0.8)
                        .opacity(animateIcon ? 1 : 0)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(animateIcon ? 0 : -30))
                                .scaleEffect(animateIcon ? 1 : 0.5)
                        )
                        .shadow(color: iconColor.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ColorTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // Message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                Divider()
                    .background(ColorTheme.secondary.opacity(0.3))
                
                // Buttons
                HStack(spacing: 0) {
                    if let secondaryTitle = secondaryButtonTitle {
                        // Secondary button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                animateIn = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                secondaryAction?()
                                isPresented = false
                            }
                        }) {
                            Text(secondaryTitle)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(ColorTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(AlertButtonStyle())
                        
                        Divider()
                            .background(ColorTheme.secondary.opacity(0.3))
                            .frame(width: 1, height: 50)
                    }
                    
                    // Primary button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            animateIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            primaryAction()
                            isPresented = false
                        }
                    }) {
                        Text(primaryButtonTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(iconColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(AlertButtonStyle())
                }
            }
            .background(ColorTheme.surface)
            .cornerRadius(20)
            .shadow(color: ColorTheme.primary.opacity(0.2), radius: 20, x: 0, y: 10)
            .frame(maxWidth: 320)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            .rotationEffect(.degrees(animateIn ? 0 : -5))
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                animateIcon = true
            }
        }
    }
}

struct AlertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// ViewModifier for easy use
struct CustomAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let primaryButtonTitle: String
    var secondaryButtonTitle: String? = nil
    let primaryAction: () -> Void
    var secondaryAction: (() -> Void)? = nil
    var icon: String = "exclamationmark.circle.fill"
    var iconColor: Color = ColorTheme.accent
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isPresented ? 2 : 0)
                .animation(.easeInOut(duration: 0.3), value: isPresented)
            
            if isPresented {
                CustomAlert(
                    title: title,
                    message: message,
                    primaryButtonTitle: primaryButtonTitle,
                    secondaryButtonTitle: secondaryButtonTitle,
                    primaryAction: primaryAction,
                    secondaryAction: secondaryAction,
                    icon: icon,
                    iconColor: iconColor,
                    isPresented: $isPresented
                )
                .zIndex(999)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }
}

extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        primaryButtonTitle: String,
        secondaryButtonTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil,
        icon: String = "exclamationmark.circle.fill",
        iconColor: Color = ColorTheme.accent
    ) -> some View {
        modifier(
            CustomAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                primaryButtonTitle: primaryButtonTitle,
                secondaryButtonTitle: secondaryButtonTitle,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
                icon: icon,
                iconColor: iconColor
            )
        )
    }
}

#Preview {
    VStack {
        Text("Preview")
    }
    .customAlert(
        isPresented: .constant(true),
        title: "Delete Booking?",
        message: "Are you sure you want to delete this booking? This action cannot be undone.",
        primaryButtonTitle: "Delete",
        secondaryButtonTitle: "Cancel",
        primaryAction: {},
        secondaryAction: {},
        icon: "trash.fill",
        iconColor: ColorTheme.error
    )
}