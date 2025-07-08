//
//  MeTimeApp.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import SwiftUI

@main
struct MeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle deep links for customer booking
                    if url.scheme == "nailbooking",
                       url.host == "book",
                       let _ = url.pathComponents.last {
                        // In a real app, you'd navigate to CustomerBookingView
                        // For demo purposes, you can test CustomerBookingView directly
                    }
                }
        }
    }
}
