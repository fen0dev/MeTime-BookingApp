//
//  Service.swift
//  MeTime
//
//  Created by Giuseppe De Masi on 07/07/2025.
//

import Foundation

struct Service: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let duration: Int
    let price: Double  // Price in DKK (Danish Kroner)
    let emoji: String
    
    static let available = [
        Service(name: "Manicure", duration: 45, price: 350, emoji: "💅"),
        Service(name: "Pedicure", duration: 90, price: 450, emoji: "🦶"),
        Service(name: "Gel Nails Extension", duration: 120, price: 650, emoji: "✨"),
        Service(name: "Lash Lift", duration: 60, price: 550, emoji: "👁"),
        Service(name: "Eyebrows Lamination", duration: 45, price: 399, emoji: "🤩")
    ]
}
