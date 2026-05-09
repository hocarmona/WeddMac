
import SwiftUI

extension VendorCategory {
    var color: Color {
        switch self {
        case .venue: .blue
        case .photographer: .purple
        case .videographer: .indigo
        case .music: .pink
        case .decoration: .green
        case .catering: .orange
        case .cake: .brown
        case .attire: .mint
        case .transport: .teal
        case .planner: .red
        case .other: .gray
        }
    }
    
    var label: String {
        switch self {
        case .venue: "Salón"
        case .photographer: "Fotografía"
        case .videographer: "Video"
        case .music: "Música"
        case .decoration: "Decoración"
        case .catering: "Banquete"
        case .cake: "Pastel"
        case .attire: "Vestuario"
        case .transport: "Transporte"
        case .planner: "Planner"
        case .other: "Otro"
        }
    }
}
