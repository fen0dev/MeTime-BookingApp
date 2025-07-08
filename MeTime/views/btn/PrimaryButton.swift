//
//  PrimaryButton.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.theme.accent, Color.theme.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: Color.theme.accent.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}


#Preview {
    PrimaryButton("Book", icon: "calendar.badge.plus", action: {})
}
