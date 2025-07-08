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
    let price: Double
    let emoji: String
    
    static let available = [
        Service(name: "Manicure", duration: 45, price: 35, emoji: "💅"),
        Service(name: "Pedicure", duration: 90, price: 45, emoji: "🦶"),
        Service(name: "Gel Nails Extension", duration: 120, price: 65, emoji: "✨"),
        Service(name: "Lash Lift", duration: 60, price: 55, emoji: "👁"),
        Service(name: "Eyebrows Lamination", duration: 45, price: 40, emoji: "🤩")
    ]
}
