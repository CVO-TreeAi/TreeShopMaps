import Foundation
import CoreLocation

// MARK: - TreeScore Calculation System
class TreeScoreCalculator {
    
    // MARK: - Core TreeScore Formula
    /// TS = Height × (Canopy Radius × 2) × (DBH/12) + HI
    /// Where HI = AFISS Hazard Impact percentage
    static func calculateTreeScore(height: Double, 
                                 canopyRadius: Double, 
                                 dbh: Double, 
                                 afissHazardImpact: Double) -> Double {
        
        // Base calculation: Height × (Canopy Radius × 2) × (DBH/12)
        let baseScore = height * (canopyRadius * 2.0) * (dbh / 12.0)
        
        // Add AFISS Hazard Impact as percentage
        let hazardImpactValue = baseScore * (afissHazardImpact / 100.0)
        
        let finalScore = baseScore + hazardImpactValue
        
        print("TreeScore Calculation:")
        print("  Base: \(height) × \(canopyRadius * 2) × \(dbh/12) = \(baseScore)")
        print("  AFISS Impact (\(afissHazardImpact)%): +\(hazardImpactValue)")
        print("  Final TreeScore: \(finalScore)")
        
        return finalScore
    }
    
    // MARK: - AFISS Categories
    enum AFISSCategory {
        case structures        // Buildings, fences, infrastructure
        case landscape        // Lawns, gardens, aesthetic features
        case utilities        // Power lines, underground utilities
        case access          // Site conditions, equipment access
        case projectSpecific // Special requirements, permits
        
        var displayName: String {
            switch self {
            case .structures: return "Structures & Infrastructure"
            case .landscape: return "Landscape & Aesthetic Features"
            case .utilities: return "Utilities & Services"
            case .access: return "Access & Site Conditions"
            case .projectSpecific: return "Project-Specific Factors"
            }
        }
    }
    
    // MARK: - AFISS Factor Definitions
    struct AFISSFactor {
        let category: AFISSCategory
        let name: String
        let impactPercentage: Double
        let description: String
        
        static let standardFactors: [AFISSFactor] = [
            // Category 1: Structures & Infrastructure
            AFISSFactor(category: .structures, name: "Building proximity", impactPercentage: 15.0, description: "House/building within 10 feet"),
            AFISSFactor(category: .structures, name: "Pool/deck nearby", impactPercentage: 12.0, description: "Swimming pool or deck protection required"),
            AFISSFactor(category: .structures, name: "Fencing", impactPercentage: 8.0, description: "Fence removal/protection needed"),
            AFISSFactor(category: .structures, name: "Driveway risk", impactPercentage: 10.0, description: "Concrete/paved surface protection"),
            
            // Category 2: Landscape & Aesthetic Features
            AFISSFactor(category: .landscape, name: "Manicured lawn", impactPercentage: 8.0, description: "High-maintenance landscaping"),
            AFISSFactor(category: .landscape, name: "Flower beds", impactPercentage: 6.0, description: "Ornamental plantings protection"),
            AFISSFactor(category: .landscape, name: "Hardscape elements", impactPercentage: 10.0, description: "Patios, fire pits, outdoor features"),
            AFISSFactor(category: .landscape, name: "Sprinkler system", impactPercentage: 5.0, description: "Underground irrigation lines"),
            
            // Category 3: Utilities & Services  
            AFISSFactor(category: .utilities, name: "Power lines overhead", impactPercentage: 20.0, description: "Electrical lines within 10 feet"),
            AFISSFactor(category: .utilities, name: "Underground utilities", impactPercentage: 15.0, description: "Gas, water, electric lines"),
            AFISSFactor(category: .utilities, name: "Communication cables", impactPercentage: 8.0, description: "Cable, internet, phone lines"),
            AFISSFactor(category: .utilities, name: "Transformer nearby", impactPercentage: 25.0, description: "Electrical transformer protection"),
            
            // Category 4: Access & Site Conditions
            AFISSFactor(category: .access, name: "Narrow gate access", impactPercentage: 12.0, description: "Gate width less than 4 feet"),
            AFISSFactor(category: .access, name: "Slope/terrain", impactPercentage: 10.0, description: "Significant grade or uneven ground"),
            AFISSFactor(category: .access, name: "Soft ground", impactPercentage: 8.0, description: "Equipment stability concerns"),
            AFISSFactor(category: .access, name: "Limited parking", impactPercentage: 6.0, description: "Equipment positioning challenges"),
            
            // Category 5: Project-Specific Factors
            AFISSFactor(category: .projectSpecific, name: "Permit required", impactPercentage: 15.0, description: "City/county permit needed"),
            AFISSFactor(category: .projectSpecific, name: "Specialized equipment", impactPercentage: 18.0, description: "Crane or special tools required"),
            AFISSFactor(category: .projectSpecific, name: "Weather constraints", impactPercentage: 10.0, description: "Seasonal or weather limitations"),
            AFISSFactor(category: .projectSpecific, name: "Customer schedule", impactPercentage: 5.0, description: "Restrictive timing requirements")
        ]
    }
    
    // MARK: - Tree Status Workflow
    enum TreeStatus: String, CaseIterable {
        case measured = "Measured"
        case quoted = "Quoted" 
        case approved = "Approved"
        case completed = "Completed"
        
        var color: String {
            switch self {
            case .measured: return "systemBlue"
            case .quoted: return "systemOrange"
            case .approved: return "systemGreen"
            case .completed: return "systemPurple"
            }
        }
        
        var nextStatus: TreeStatus? {
            switch self {
            case .measured: return .quoted
            case .quoted: return .approved
            case .approved: return .completed
            case .completed: return nil
            }
        }
    }
    
    // MARK: - Tree Photo Requirements
    enum TreePhotoType: String, CaseIterable {
        case overview = "overview"
        case trunk = "trunk"
        case canopy = "canopy"
        
        var displayName: String {
            switch self {
            case .overview: return "Overview Shot"
            case .trunk: return "Trunk Detail"
            case .canopy: return "Canopy/Crown"
            }
        }
        
        var instructions: String {
            switch self {
            case .overview:
                return "Full tree view showing overall structure and surroundings"
            case .trunk:
                return "Close-up of trunk at chest height showing bark and any defects"
            case .canopy:
                return "Upward view of canopy showing branch structure and leaf density"
            }
        }
    }
    
    // MARK: - Validation
    static func validateTreeData(height: Double?, canopyRadius: Double?, dbh: Double?, photos: [String: Data?]) -> [String] {
        var errors: [String] = []
        
        // Validate measurements
        if height == nil || height! <= 0 {
            errors.append("Tree height is required and must be greater than 0")
        }
        if canopyRadius == nil || canopyRadius! <= 0 {
            errors.append("Canopy radius is required and must be greater than 0")
        }
        if dbh == nil || dbh! <= 0 {
            errors.append("DBH (Diameter at Breast Height) is required and must be greater than 0")
        }
        
        // Validate required photos
        for photoType in TreePhotoType.allCases {
            if photos[photoType.rawValue] == nil {
                errors.append("\(photoType.displayName) photo is required")
            }
        }
        
        if errors.isEmpty {
            print("✅ Tree data validation passed - all requirements met")
        } else {
            print("❌ Tree data validation failed:")
            errors.forEach { print("  - \($0)") }
        }
        
        return errors
    }
    
    // MARK: - Difficulty Factor Calculation
    static func calculateDifficultyFactor(afissFactors: [AFISSFactor]) -> Double {
        // Base difficulty is 1.0
        var difficulty = 1.0
        
        // Add complexity based on AFISS factors
        let totalAFISS = afissFactors.reduce(0) { $0 + $1.impactPercentage }
        
        // Convert AFISS percentage to difficulty multiplier
        difficulty += (totalAFISS / 100.0) * 0.5 // 50% of AFISS impact becomes difficulty
        
        return min(difficulty, 3.0) // Cap at 3.0x difficulty
    }
    
    // MARK: - PpH Integration
    /// Convert TreeScore to estimated work hours using Points per Hour system
    static func estimateWorkTime(treeScore: Double, crewPpHRating: Double) -> Double {
        guard crewPpHRating > 0 else { return 0 }
        return treeScore / crewPpHRating
    }
    
    // MARK: - Sample Calculations
    static func runSampleCalculation() {
        print("\n=== TreeScore Sample Calculation ===")
        
        // Sample tree: 40ft tall, 15ft canopy radius, 24" DBH
        let height: Double = 40
        let canopyRadius: Double = 15
        let dbh: Double = 24
        
        // Sample AFISS factors
        let sampleFactors = [
            AFISSFactor.standardFactors.first { $0.name == "Power lines overhead" }!,
            AFISSFactor.standardFactors.first { $0.name == "Manicured lawn" }!,
            AFISSFactor.standardFactors.first { $0.name == "Narrow gate access" }!
        ]
        
        let totalAFISS = sampleFactors.reduce(0) { $0 + $1.impactPercentage }
        let treeScore = calculateTreeScore(height: height, 
                                         canopyRadius: canopyRadius, 
                                         dbh: dbh, 
                                         afissHazardImpact: totalAFISS)
        
        let difficultyFactor = calculateDifficultyFactor(afissFactors: sampleFactors)
        let estimatedHours = estimateWorkTime(treeScore: treeScore, crewPpHRating: 500)
        
        print("\nAFISS Factors Applied:")
        sampleFactors.forEach { factor in
            print("  - \(factor.name): +\(factor.impactPercentage)%")
        }
        print("  Total AFISS Impact: \(totalAFISS)%")
        print("  Difficulty Factor: \(String(format: "%.1f", difficultyFactor))x")
        print("  Estimated Work Time: \(String(format: "%.1f", estimatedHours)) hours")
        print("=====================================\n")
    }
}

// MARK: - TreeMark Extension for TreeScore
extension TreeMark {
    var calculatedTreeScore: Double {
        return TreeScoreCalculator.calculateTreeScore(
            height: self.height,
            canopyRadius: self.canopyRadius,
            dbh: self.dbh,
            afissHazardImpact: 0 // TODO: Add AFISS calculation from stored factors
        )
    }
    
    var hasAllRequiredPhotos: Bool {
        return overviewPhotoData != nil && 
               trunkPhotoData != nil && 
               canopyPhotoData != nil
    }
    
    var photoCompletionStatus: String {
        let photoCount = [overviewPhotoData, trunkPhotoData, canopyPhotoData].compactMap { $0 }.count
        return "\(photoCount)/3 photos"
    }
    
    var statusColor: String {
        return TreeScoreCalculator.TreeStatus(rawValue: status ?? "Measured")?.color ?? "systemGray"
    }
}