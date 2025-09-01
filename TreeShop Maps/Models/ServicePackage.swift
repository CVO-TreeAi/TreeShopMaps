import UIKit

enum ServicePackage: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case xLarge = "XLarge"
    case max = "Max"
    
    var description: String {
        switch self {
        case .small: return "Understory Mulching"
        case .medium: return "Standard Mulching"
        case .large: return "Heavy Mulching"
        case .xLarge: return "Thick Brush"
        case .max: return "Land Clearing"
        }
    }
    
    var color: UIColor {
        switch self {
        case .small: return TreeShopTheme.packageSmall
        case .medium: return TreeShopTheme.packageMedium
        case .large: return TreeShopTheme.packageLarge
        case .xLarge: return TreeShopTheme.packageXLarge
        case .max: return TreeShopTheme.packageMax
        }
    }
    
    var pricePerAcre: Double {
        switch self {
        case .small: return 800
        case .medium: return 1200
        case .large: return 1600
        case .xLarge: return 2200
        case .max: return 3500
        }
    }
    
    var estimatedHoursPerAcre: Double {
        switch self {
        case .small: return 0.5
        case .medium: return 0.75
        case .large: return 1.0
        case .xLarge: return 1.5
        case .max: return 2.5
        }
    }
}