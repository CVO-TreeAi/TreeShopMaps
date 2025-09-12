import Foundation
import MapKit
import CoreLocation

// MARK: - TreeScore Calculation Models
// Implements the official TreeAI TreeScore formula: TS = Height × (Canopy Radius × 2) × (DBH/12) + HI

/// Core TreeScore calculation result with GPS integration
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

/// GPS-located tree with TreeScore calculation
class TreeInventoryItem: NSObject, NSCoding {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let gpsAccuracy: CLLocationAccuracy
    
    // Tree Measurements
    let height: Double          // feet
    let canopyRadius: Double    // feet
    let dbh: Double            // diameter at breast height in inches
    let afissPercentage: Double // AFISS hazard impact percentage (0-100)
    
    // TreeScore Results
    let treeScore: TreeScoreResult
    let estimatedTimeHours: Double?  // Based on PpH rating
    let estimatedCost: Double?       // Based on service package
    
    // Metadata
    let species: String?
    let healthStatus: String?
    let notes: String?
    let dateCreated: Date
    let createdBy: String?
    
    // ServicePackage Association
    let servicePackage: ServicePackage?
    
    init(id: UUID = UUID(),
         coordinate: CLLocationCoordinate2D,
         gpsAccuracy: CLLocationAccuracy,
         height: Double,
         canopyRadius: Double,
         dbh: Double,
         afissPercentage: Double,
         species: String? = nil,
         healthStatus: String? = nil,
         notes: String? = nil,
         servicePackage: ServicePackage? = nil,
         crewPpH: Double? = nil,
         createdBy: String? = nil) {
        
        self.id = id
        self.coordinate = coordinate
        self.gpsAccuracy = gpsAccuracy
        self.height = height
        self.canopyRadius = canopyRadius
        self.dbh = dbh
        self.afissPercentage = afissPercentage
        self.species = species
        self.healthStatus = healthStatus
        self.notes = notes
        self.dateCreated = Date()
        self.createdBy = createdBy
        self.servicePackage = servicePackage
        
        // Calculate TreeScore using official formula
        self.treeScore = TreeScoreCalculator.calculateTreeScore(
            height: height,
            canopyRadius: canopyRadius,
            dbh: dbh,
            afissPercentage: afissPercentage,
            gpsAccuracy: gpsAccuracy
        )
        
        // Calculate estimated time if crew PpH provided
        if let crewPpH = crewPpH, crewPpH > 0 {
            self.estimatedTimeHours = self.treeScore.finalTreeScore / crewPpH
        } else {
            self.estimatedTimeHours = nil
        }
        
        // Calculate estimated cost if service package provided
        if let package = servicePackage, let timeHours = estimatedTimeHours {
            // Estimate based on package hourly rate
            let hourlyRate = package.pricePerAcre / package.estimatedHoursPerAcre
            self.estimatedCost = timeHours * hourlyRate
        } else {
            self.estimatedCost = nil
        }
        
        super.init()
    }
    
    // MARK: - NSCoding Implementation
    func encode(with coder: NSCoder) {
        coder.encode(id.uuidString, forKey: "id")
        coder.encode(coordinate.latitude, forKey: "latitude")
        coder.encode(coordinate.longitude, forKey: "longitude")
        coder.encode(gpsAccuracy, forKey: "gpsAccuracy")
        coder.encode(height, forKey: "height")
        coder.encode(canopyRadius, forKey: "canopyRadius")
        coder.encode(dbh, forKey: "dbh")
        coder.encode(afissPercentage, forKey: "afissPercentage")
        coder.encode(species, forKey: "species")
        coder.encode(healthStatus, forKey: "healthStatus")
        coder.encode(notes, forKey: "notes")
        coder.encode(dateCreated, forKey: "dateCreated")
        coder.encode(createdBy, forKey: "createdBy")
        coder.encode(servicePackage?.rawValue, forKey: "servicePackage")
        coder.encode(estimatedTimeHours, forKey: "estimatedTimeHours")
        coder.encode(estimatedCost, forKey: "estimatedCost")
        
        // Encode TreeScore result
        coder.encode(treeScore.baseScore, forKey: "treeScoreBase")
        coder.encode(treeScore.hazardImpact, forKey: "treeScoreHazard")
        coder.encode(treeScore.finalTreeScore, forKey: "treeScoreFinal")
        coder.encode(treeScore.formula, forKey: "treeScoreFormula")
        coder.encode(treeScore.isValid, forKey: "treeScoreValid")
    }
    
    required init?(coder: NSCoder) {
        guard let idString = coder.decodeObject(forKey: "id") as? String,
              let id = UUID(uuidString: idString),
              let dateCreated = coder.decodeObject(forKey: "dateCreated") as? Date else {
            return nil
        }
        
        self.id = id
        self.coordinate = CLLocationCoordinate2D(
            latitude: coder.decodeDouble(forKey: "latitude"),
            longitude: coder.decodeDouble(forKey: "longitude")
        )
        self.gpsAccuracy = coder.decodeDouble(forKey: "gpsAccuracy")
        self.height = coder.decodeDouble(forKey: "height")
        self.canopyRadius = coder.decodeDouble(forKey: "canopyRadius")
        self.dbh = coder.decodeDouble(forKey: "dbh")
        self.afissPercentage = coder.decodeDouble(forKey: "afissPercentage")
        self.species = coder.decodeObject(forKey: "species") as? String
        self.healthStatus = coder.decodeObject(forKey: "healthStatus") as? String
        self.notes = coder.decodeObject(forKey: "notes") as? String
        self.dateCreated = dateCreated
        self.createdBy = coder.decodeObject(forKey: "createdBy") as? String
        self.estimatedTimeHours = coder.decodeObject(forKey: "estimatedTimeHours") as? Double
        self.estimatedCost = coder.decodeObject(forKey: "estimatedCost") as? Double
        
        // Decode service package
        if let packageRaw = coder.decodeObject(forKey: "servicePackage") as? String {
            self.servicePackage = ServicePackage(rawValue: packageRaw)
        } else {
            self.servicePackage = nil
        }
        
        // Reconstruct TreeScore result
        self.treeScore = TreeScoreResult(
            baseScore: coder.decodeDouble(forKey: "treeScoreBase"),
            hazardImpact: coder.decodeDouble(forKey: "treeScoreHazard"),
            finalTreeScore: coder.decodeDouble(forKey: "treeScoreFinal"),
            formula: (coder.decodeObject(forKey: "treeScoreFormula") as? String) ?? "",
            isValid: coder.decodeBool(forKey: "treeScoreValid")
        )
        
        super.init()
    }
    
    // MARK: - Map Annotation
    func createMapAnnotation() -> TreeScoreAnnotation {
        let annotation = TreeScoreAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "TreeScore: \(String(format: "%.0f", treeScore.finalTreeScore))"
        annotation.subtitle = species ?? "Tree"
        annotation.treeInventoryItem = self
        return annotation
    }
    
    // MARK: - Display Methods
    func getFormattedTreeScore() -> String {
        return String(format: "%.0f pts", treeScore.finalTreeScore)
    }
    
    func getFormattedEstimatedTime() -> String? {
        guard let timeHours = estimatedTimeHours else { return nil }
        if timeHours < 1.0 {
            let minutes = Int(timeHours * 60)
            return "\(minutes) min"
        } else {
            return String(format: "%.1f hrs", timeHours)
        }
    }
    
    func getFormattedEstimatedCost() -> String? {
        guard let cost = estimatedCost else { return nil }
        return String(format: "$%.0f", cost)
    }
    
    func getComplexityLevel() -> TreeComplexity {
        switch treeScore.finalTreeScore {
        case 0..<500:
            return .low
        case 500..<1500:
            return .medium
        case 1500..<3000:
            return .high
        default:
            return .extreme
        }
    }
}

/// TreeScore complexity levels for visual representation
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

/// Custom map annotation for TreeScore items
class TreeScoreAnnotation: MKPointAnnotation {
    var treeInventoryItem: TreeInventoryItem?
}

// MARK: - TreeScore Calculator Service
class TreeScoreCalculator {
    
    /// Calculate TreeScore using the official TreeAI formula
    /// Formula: TS = Height × (Canopy Radius × 2) × (DBH/12) + HI
    /// Where HI = Base Score × (AFISS percentage / 100)
    static func calculateTreeScore(
        height: Double,
        canopyRadius: Double,
        dbh: Double,
        afissPercentage: Double,
        gpsAccuracy: CLLocationAccuracy? = nil
    ) -> TreeScoreResult {
        
        // Validate inputs
        guard height > 0, canopyRadius > 0, dbh > 0, afissPercentage >= 0 else {
            return TreeScoreResult(
                baseScore: 0,
                hazardImpact: 0,
                finalTreeScore: 0,
                formula: "Invalid inputs",
                isValid: false,
                gpsAccuracy: gpsAccuracy
            )
        }
        
        // Base TreeScore calculation: Height × (Canopy Radius × 2) × (DBH/12)
        let baseScore = height * (canopyRadius * 2) * (dbh / 12.0)
        
        // AFISS Hazard Impact: Base Score × (AFISS percentage / 100)
        let hazardImpact = baseScore * (afissPercentage / 100.0)
        
        // Final TreeScore: Base + Hazard Impact
        let finalTreeScore = baseScore + hazardImpact
        
        // Generate formula string for documentation
        let formula = "TS = \(height) × (\(canopyRadius) × 2) × (\(dbh)/12) + (\(String(format: "%.0f", baseScore)) × \(afissPercentage)%) = \(String(format: "%.0f", finalTreeScore))"
        
        return TreeScoreResult(
            baseScore: baseScore,
            hazardImpact: hazardImpact,
            finalTreeScore: finalTreeScore,
            formula: formula,
            isValid: true,
            gpsAccuracy: gpsAccuracy
        )
    }
    
    /// Convert TreeScore to estimated time using crew Points per Hour (PpH) rating
    static func convertTreeScoreToTime(treeScore: Double, crewPpH: Double) -> Double {
        guard crewPpH > 0 else { return 0 }
        return treeScore / crewPpH
    }
    
    /// Calculate estimated billing based on TreeScore and service package
    static func calculateEstimatedBilling(
        treeScore: Double,
        servicePackage: ServicePackage,
        crewPpH: Double
    ) -> Double {
        let estimatedHours = convertTreeScoreToTime(treeScore: treeScore, crewPpH: crewPpH)
        let hourlyRate = servicePackage.pricePerAcre / servicePackage.estimatedHoursPerAcre
        return estimatedHours * hourlyRate
    }
    
    /// Validate TreeScore inputs
    static func validateInputs(height: Double, canopyRadius: Double, dbh: Double, afissPercentage: Double) -> [String] {
        var errors: [String] = []
        
        if height <= 0 {
            errors.append("Height must be greater than 0 feet")
        } else if height > 300 {
            errors.append("Height seems unusually high (>300 feet)")
        }
        
        if canopyRadius <= 0 {
            errors.append("Canopy radius must be greater than 0 feet")
        } else if canopyRadius > 150 {
            errors.append("Canopy radius seems unusually large (>150 feet)")
        }
        
        if dbh <= 0 {
            errors.append("DBH must be greater than 0 inches")
        } else if dbh > 120 {
            errors.append("DBH seems unusually large (>120 inches)")
        }
        
        if afissPercentage < 0 {
            errors.append("AFISS percentage cannot be negative")
        } else if afissPercentage > 100 {
            errors.append("AFISS percentage cannot exceed 100%")
        }
        
        return errors
    }
}

// MARK: - Tree Inventory Manager
class TreeInventoryManager {
    static let shared = TreeInventoryManager()
    
    private let userDefaults = UserDefaults.standard
    private let treeInventoryKey = "TreeInventoryItems"
    
    private var trees: [TreeInventoryItem] = []
    
    init() {
        loadTrees()
    }
    
    func addTree(_ tree: TreeInventoryItem) {
        trees.append(tree)
        saveTrees()
    }
    
    func getTrees() -> [TreeInventoryItem] {
        return trees.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    func getTree(by id: UUID) -> TreeInventoryItem? {
        return trees.first { $0.id == id }
    }
    
    func deleteTree(by id: UUID) {
        trees.removeAll { $0.id == id }
        saveTrees()
    }
    
    func getTreesInArea(center: CLLocationCoordinate2D, radiusMeters: Double) -> [TreeInventoryItem] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        return trees.filter { tree in
            let treeLocation = CLLocation(latitude: tree.coordinate.latitude, longitude: tree.coordinate.longitude)
            return treeLocation.distance(from: centerLocation) <= radiusMeters
        }
    }
    
    func getTotalTreeScore() -> Double {
        return trees.reduce(0) { $0 + $1.treeScore.finalTreeScore }
    }
    
    func getAverageTreeScore() -> Double {
        guard !trees.isEmpty else { return 0 }
        return getTotalTreeScore() / Double(trees.count)
    }
    
    func getTreesByComplexity() -> [TreeComplexity: [TreeInventoryItem]] {
        var result: [TreeComplexity: [TreeInventoryItem]] = [:]
        
        for tree in trees {
            let complexity = tree.getComplexityLevel()
            if result[complexity] == nil {
                result[complexity] = []
            }
            result[complexity]?.append(tree)
        }
        
        return result
    }
    
    private func saveTrees() {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: trees, requiringSecureCoding: false)
        userDefaults.set(data, forKey: treeInventoryKey)
    }
    
    private func loadTrees() {
        guard let data = userDefaults.data(forKey: treeInventoryKey),
              let loadedTrees = try? NSKeyedUnarchiver.unarchiveObject(with: data) as? [TreeInventoryItem] else {
            trees = []
            return
        }
        trees = loadedTrees
    }
    
    // Export functionality for TreeScore data
    func exportTreeScoreData() -> URL? {
        let csvHeader = "TreeScore,Height,Canopy Radius,DBH,AFISS,Species,Latitude,Longitude,GPS Accuracy,Date,Estimated Time,Estimated Cost,Service Package\n"
        var csvContent = csvHeader
        
        for tree in trees {
            let timeStr = tree.getFormattedEstimatedTime() ?? ""
            let costStr = tree.getFormattedEstimatedCost() ?? ""
            let packageStr = tree.servicePackage?.rawValue ?? ""
            let speciesStr = tree.species ?? ""
            
            let line = "\(String(format: "%.0f", tree.treeScore.finalTreeScore)),\(tree.height),\(tree.canopyRadius),\(tree.dbh),\(tree.afissPercentage),\(speciesStr),\(tree.coordinate.latitude),\(tree.coordinate.longitude),\(tree.gpsAccuracy),\(tree.dateCreated),\(timeStr),\(costStr),\(packageStr)\n"
            csvContent += line
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "TreeScore_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting TreeScore CSV: \(error)")
            return nil
        }
    }
}