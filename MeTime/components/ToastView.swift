//
//  ToastView.swift
//  MeTime
//
//  Created by Assistant on 07/07/2025.
//

import SwiftUI

struct Toast: Equatable {
    var message: String
    var icon: String
    var backgroundColor: Color
    var duration: Double = 3.0
}

struct ToastView: View {
    let toast: Toast
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 20))
            
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(toast.backgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                if let toast = toast, isShowing {
                    ToastView(toast: toast, isShowing: $isShowing)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowing)
        }
        .onChange(of: toast) { _, newValue in
            if newValue != nil {
                withAnimation {
                    isShowing = true
                }
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    toast = nil
                }
            }
        }
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
