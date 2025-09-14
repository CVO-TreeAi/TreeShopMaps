import UIKit
import MapKit
import CoreLocation
import CoreData
import CloudKit

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

/// Tree Inventory Manager with Core Data + CloudKit
class TreeInventoryManager {
    static let shared = TreeInventoryManager()
    
    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "TreeShopMaps")
        
        // Configure for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
            } else {
                print("✅ Core Data + CloudKit loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func addTree(_ tree: TreeInventoryItem) {
        let treeMark = TreeMark(context: context)
        treeMark.id = tree.id
        treeMark.latitude = tree.coordinate.latitude
        treeMark.longitude = tree.coordinate.longitude
        treeMark.height = tree.height
        treeMark.canopyRadius = tree.canopyRadius
        treeMark.dbh = tree.dbh
        treeMark.species = tree.species
        treeMark.healthStatus = "Good" // Default health status
        treeMark.notes = "TreeScore: \(Int(tree.treeScore.finalTreeScore))"
        treeMark.dateMarked = Date()
        treeMark.markedBy = "TreeShop Professional Assessment"
        
        saveContext()
        print("🌲 Tree saved to Core Data + CloudKit: \(tree.treeScore.finalTreeScore)")
    }
    
    func getTrees() -> [TreeInventoryItem] {
        let request: NSFetchRequest<TreeMark> = TreeMark.fetchRequest()
        
        do {
            let treeMarks = try context.fetch(request)
            return treeMarks.compactMap { treeMark in
                guard treeMark.id != nil else { return nil }
                
                return TreeInventoryItem(
                    coordinate: CLLocationCoordinate2D(latitude: treeMark.latitude, longitude: treeMark.longitude),
                    gpsAccuracy: 5.0, // Default accuracy
                    height: treeMark.height,
                    canopyRadius: treeMark.canopyRadius,
                    dbh: treeMark.dbh,
                    afissPercentage: 25.0, // Default AFISS
                    species: treeMark.species
                )
            }
        } catch {
            print("❌ Failed to fetch trees: \(error)")
            return []
        }
    }
    
    func deleteTree(by id: UUID) {
        let request: NSFetchRequest<TreeMark> = TreeMark.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let trees = try context.fetch(request)
            for tree in trees {
                context.delete(tree)
            }
            saveContext()
        } catch {
            print("❌ Failed to delete tree: \(error)")
        }
    }
    
    func getTotalTreeScore() -> Double {
        return getTrees().reduce(0) { $0 + $1.treeScore.finalTreeScore }
    }
    
    func getAverageTreeScore() -> Double {
        let trees = getTrees()
        guard !trees.isEmpty else { return 0 }
        return getTotalTreeScore() / Double(trees.count)
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ Failed to save Core Data: \(error)")
            }
        }
    }
    
    func loadExistingTrees(on mapView: MKMapView) {
        let trees = getTrees()
        print("🌲 Loading \(trees.count) existing trees from Core Data")
        
        for tree in trees {
            let annotation = tree.createMapAnnotation()
            mapView.addAnnotation(annotation)
        }
    }
    
    func exportTreeScoreData() -> URL? {
        return nil // TODO: Implement export
    }
}

/// TreeScore Input Delegate
protocol TreeScoreInputDelegate: AnyObject {
    func didCreateTreeInventoryItem(_ item: TreeInventoryItem)
    func didCancelTreeInput()
}