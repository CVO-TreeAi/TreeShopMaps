import UIKit
import MapKit
import CoreLocation

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

// MARK: - TreeScore Integration for TreeShop Maps

/// TreeScore complexity levels
enum TreeComplexity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case extreme = "Extreme"
    
    var color: UIColor {
        switch self {
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        case .extreme: return .systemPurple
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "leaf.fill"
        case .medium: return "tree.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .extreme: return "flame.fill"
        }
    }
}

/// TreeScore calculation result
struct TreeScoreResult {
    let baseScore: Double
    let hazardImpact: Double
    let finalTreeScore: Double
    let formula: String
    let isValid: Bool
    let gpsAccuracy: CLLocationAccuracy?
    let calculationDate: Date
    
    init(baseScore: Double, hazardImpact: Double, finalTreeScore: Double, 
         formula: String, isValid: Bool, gpsAccuracy: CLLocationAccuracy? = nil) {
        self.baseScore = baseScore
        self.hazardImpact = hazardImpact
        self.finalTreeScore = finalTreeScore
        self.formula = formula
        self.isValid = isValid
        self.gpsAccuracy = gpsAccuracy
        self.calculationDate = Date()
    }
}

/// Custom map annotation for TreeScore items  
class TreeScoreAnnotation: MKPointAnnotation {
    var treeInventoryItem: TreeInventoryItem?
}

/// GPS-located tree with TreeScore calculation
class TreeInventoryItem: NSObject {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let gpsAccuracy: CLLocationAccuracy
    let height: Double
    let canopyRadius: Double
    let dbh: Double
    let afissPercentage: Double
    let treeScore: TreeScoreResult
    let species: String?
    let dateCreated: Date
    
    init(coordinate: CLLocationCoordinate2D, gpsAccuracy: CLLocationAccuracy, 
         height: Double, canopyRadius: Double, dbh: Double, afissPercentage: Double, species: String? = nil) {
        self.id = UUID()
        self.coordinate = coordinate
        self.gpsAccuracy = gpsAccuracy
        self.height = height
        self.canopyRadius = canopyRadius
        self.dbh = dbh
        self.afissPercentage = afissPercentage
        self.species = species
        self.dateCreated = Date()
        
        // Calculate TreeScore: TS = Height × (Canopy × 2) × (DBH/12) + HI
        let baseScore = height * (canopyRadius * 2) * (dbh / 12.0)
        let hazardImpact = baseScore * (afissPercentage / 100.0)
        let finalTreeScore = baseScore + hazardImpact
        let formula = "TS = \(height) × (\(canopyRadius) × 2) × (\(dbh)/12) + (\(String(format: "%.0f", baseScore)) × \(afissPercentage)%) = \(String(format: "%.0f", finalTreeScore))"
        
        self.treeScore = TreeScoreResult(
            baseScore: baseScore,
            hazardImpact: hazardImpact,
            finalTreeScore: finalTreeScore,
            formula: formula,
            isValid: height > 0 && canopyRadius > 0 && dbh > 0,
            gpsAccuracy: gpsAccuracy
        )
        
        super.init()
    }
    
    func createMapAnnotation() -> TreeScoreAnnotation {
        let annotation = TreeScoreAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "TreeScore: \(String(format: "%.0f", treeScore.finalTreeScore))"
        annotation.subtitle = species ?? "Tree"
        annotation.treeInventoryItem = self
        return annotation
    }
    
    func getComplexityLevel() -> TreeComplexity {
        switch treeScore.finalTreeScore {
        case 0..<500: return .low
        case 500..<1500: return .medium
        case 1500..<3000: return .high
        default: return .extreme
        }
    }
    
    func getFormattedTreeScore() -> String {
        return String(format: "%.0f pts", treeScore.finalTreeScore)
    }
    
    func getFormattedEstimatedTime() -> String? {
        return "Est. time N/A" // Simplified for demo
    }
    
    func getFormattedEstimatedCost() -> String? {
        return "Est. cost N/A" // Simplified for demo
    }
}

/// Tree Inventory Manager
class TreeInventoryManager {
    static let shared = TreeInventoryManager()
    private var trees: [TreeInventoryItem] = []
    
    func addTree(_ tree: TreeInventoryItem) {
        trees.append(tree)
    }
    
    func getTrees() -> [TreeInventoryItem] {
        return trees
    }
    
    func deleteTree(by id: UUID) {
        trees.removeAll { $0.id == id }
    }
    
    func getTotalTreeScore() -> Double {
        return trees.reduce(0) { $0 + $1.treeScore.finalTreeScore }
    }
    
    func getAverageTreeScore() -> Double {
        guard !trees.isEmpty else { return 0 }
        return getTotalTreeScore() / Double(trees.count)
    }
    
    func exportTreeScoreData() -> URL? {
        return nil // Simplified for demo
    }
}

/// TreeScore Input Delegate
protocol TreeScoreInputDelegate: AnyObject {
    func didCreateTreeInventoryItem(_ item: TreeInventoryItem)
    func didCancelTreeInput()
}