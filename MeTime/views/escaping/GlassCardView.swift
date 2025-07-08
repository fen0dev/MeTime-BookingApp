//
//  GlassCardView.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

struct GlassCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.theme.primary.opacity(0.6), Color.theme.accent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: Color.theme.accent.opacity(0.1), radius: 10, x: 0, y: 5)
            }
    }
}

