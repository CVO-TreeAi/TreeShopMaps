import UIKit
import MapKit
import CoreLocation

// MARK: - TreeShop Scoreboard Data Provider

class TreeShopScoreboardDataProvider: ScoreboardDataProvider {
    
    // MARK: - Properties
    weak var mapViewController: MainMapViewController?
    private var cachedAreaData: AreaMeasurementData?
    private var cachedTreeData: TreeInventoryData?
    private var cachedGPSData: GPSData?
    
    // MARK: - Initialization
    
    init(mapViewController: MainMapViewController?) {
        self.mapViewController = mapViewController
        setupDataObservation()
    }
    
    // MARK: - ScoreboardDataProvider Implementation
    
    func getWidgetsForState(_ state: ScoreboardState) -> [WidgetData] {
        switch state {
        case .defaultView:
            return getDefaultViewWidgets()
        case .areaDrawing:
            return getAreaDrawingWidgets()
        case .treeInventory:
            return getTreeInventoryWidgets()
        case .measurement:
            return getMeasurementWidgets()
        case .packageSelection:
            return getPackageSelectionWidgets()
        }
    }
    
    func getContextualActions(for state: ScoreboardState) -> [ScoreboardAction] {
        switch state {
        case .defaultView:
            return getDefaultActions()
        case .areaDrawing:
            return getAreaDrawingActions()
        case .treeInventory:
            return getTreeInventoryActions()
        case .measurement:
            return getMeasurementActions()
        case .packageSelection:
            return getPackageSelectionActions()
        }
    }
    
    func getHeaderInfo(for state: ScoreboardState) -> (title: String, subtitle: String, progress: Float?) {
        switch state {
        case .defaultView:
            return ("TreeShop Maps", "Ready for mapping", nil)
        case .areaDrawing:
            let progress = cachedAreaData?.completionProgress ?? 0.0
            return ("Area Drawing", "\(cachedAreaData?.pointCount ?? 0) points marked", progress > 0 ? progress : nil)
        case .treeInventory:
            let treeCount = cachedTreeData?.treeCount ?? 0
            return ("Tree Assessment", "\(treeCount) trees assessed", nil)
        case .measurement:
            return ("GPS Measurement", "±\(cachedGPSData?.accuracy ?? 0.0)m accuracy", nil)
        case .packageSelection:
            return ("Package Selection", "Choose service package", nil)
        }
    }
    
    // MARK: - Default View Widgets
    
    private func getDefaultViewWidgets() -> [WidgetData] {
        refreshCachedData()
        
        var widgets: [WidgetData] = []
        
        // Current area widget
        if let areaData = cachedAreaData, areaData.area > 0 {
            widgets.append(WidgetData(
                id: "current_area",
                title: "Current Area",
                value: String(format: "%.2f ac", areaData.area),
                subtitle: "Last measured",
                icon: "map.fill",
                color: TreeShopTheme.primaryGreen,
                action: { [weak self] in
                    self?.showAreaDetails()
                }
            ))
        }
        
        // Tree count widget
        let treeCount = cachedTreeData?.treeCount ?? 0
        if treeCount > 0 {
            widgets.append(WidgetData(
                id: "tree_count",
                title: "Trees Assessed",
                value: "\(treeCount)",
                subtitle: "Total inventory",
                icon: "tree.fill",
                color: UIColor.systemOrange,
                action: { [weak self] in
                    self?.showTreeInventory()
                }
            ))
        }
        
        // GPS accuracy widget
        widgets.append(WidgetData(
            id: "gps_accuracy",
            title: "GPS Accuracy",
            value: "±\(String(format: "%.1f", cachedGPSData?.accuracy ?? 0.0))m",
            subtitle: "Current precision",
            icon: "location.fill",
            color: getGPSAccuracyColor()
        ))
        
        // Today's progress widget
        widgets.append(WidgetData(
            id: "daily_progress",
            title: "Today's Work",
            value: "\(getDailyAreaCount()) areas",
            subtitle: "Areas mapped",
            icon: "calendar.badge.plus",
            color: TreeShopTheme.accentGreen
        ))
        
        return widgets
    }
    
    // MARK: - Area Drawing Widgets
    
    private func getAreaDrawingWidgets() -> [WidgetData] {
        refreshCachedData()
        
        var widgets: [WidgetData] = []
        
        // Current area being drawn
        widgets.append(WidgetData(
            id: "current_area_size",
            title: "Area Size",
            value: String(format: "%.3f ac", cachedAreaData?.area ?? 0.0),
            subtitle: "Live calculation",
            icon: "ruler.fill",
            color: TreeShopTheme.primaryGreen,
            trend: getAreaTrend()
        ))
        
        // Perimeter length
        widgets.append(WidgetData(
            id: "perimeter",
            title: "Perimeter",
            value: String(format: "%.1f ft", cachedAreaData?.perimeter ?? 0.0),
            subtitle: "Boundary length",
            icon: "triangle.fill",
            color: TreeShopTheme.accentGreen
        ))
        
        // Points marked
        widgets.append(WidgetData(
            id: "points_marked",
            title: "Points",
            value: "\(cachedAreaData?.pointCount ?? 0)",
            subtitle: "Boundary markers",
            icon: "mappin.circle.fill",
            color: UIColor.systemBlue
        ))
        
        // Estimated cost
        if let estimatedCost = calculateEstimatedCost() {
            widgets.append(WidgetData(
                id: "estimated_cost",
                title: "Est. Cost",
                value: "$\(String(format: "%.0f", estimatedCost))",
                subtitle: "Based on package",
                icon: "dollarsign.circle.fill",
                color: TreeShopTheme.successGreen
            ))
        }
        
        return widgets
    }
    
    // MARK: - Tree Inventory Widgets
    
    private func getTreeInventoryWidgets() -> [WidgetData] {
        refreshCachedData()
        
        var widgets: [WidgetData] = []
        
        // Total TreeScore
        let totalScore = cachedTreeData?.totalTreeScore ?? 0.0
        widgets.append(WidgetData(
            id: "total_treescore",
            title: "Total TreeScore",
            value: String(format: "%.0f pts", totalScore),
            subtitle: "Assessment total",
            icon: "star.fill",
            color: UIColor.systemOrange
        ))
        
        // Average TreeScore
        let avgScore = cachedTreeData?.averageTreeScore ?? 0.0
        widgets.append(WidgetData(
            id: "avg_treescore",
            title: "Avg TreeScore",
            value: String(format: "%.0f pts", avgScore),
            subtitle: "Per tree",
            icon: "chart.bar.fill",
            color: getTreeScoreColor(avgScore)
        ))
        
        // Tree complexity breakdown
        let complexityData = cachedTreeData?.complexityBreakdown ?? [:]
        if !complexityData.isEmpty {
            let highRiskCount = complexityData[.high] ?? 0 + complexityData[.extreme] ?? 0
            widgets.append(WidgetData(
                id: "high_risk_trees",
                title: "High Risk",
                value: "\(highRiskCount)",
                subtitle: "Trees requiring attention",
                icon: "exclamationmark.triangle.fill",
                color: highRiskCount > 0 ? TreeShopTheme.errorRed : TreeShopTheme.successGreen
            ))
        }
        
        // Recent assessment
        if let lastTree = cachedTreeData?.lastAssessedTree {
            widgets.append(WidgetData(
                id: "last_assessment",
                title: "Last Tree",
                value: String(format: "%.0f pts", lastTree.treeScore.finalTreeScore),
                subtitle: lastTree.species ?? "Unknown species",
                icon: "clock.fill",
                color: getTreeScoreColor(lastTree.treeScore.finalTreeScore)
            ))
        }
        
        return widgets
    }
    
    // MARK: - Measurement Widgets
    
    private func getMeasurementWidgets() -> [WidgetData] {
        refreshCachedData()
        
        var widgets: [WidgetData] = []
        
        // GPS accuracy
        widgets.append(WidgetData(
            id: "gps_precision",
            title: "GPS Precision",
            value: "±\(String(format: "%.1f", cachedGPSData?.accuracy ?? 0.0))m",
            subtitle: "Current accuracy",
            icon: "location.circle.fill",
            color: getGPSAccuracyColor()
        ))
        
        // Satellite count
        widgets.append(WidgetData(
            id: "satellite_count",
            title: "Satellites",
            value: "\(cachedGPSData?.satelliteCount ?? 0)",
            subtitle: "In view",
            icon: "dot.radiowaves.left.and.right",
            color: getSatelliteColor()
        ))
        
        // Current coordinates
        if let location = cachedGPSData?.currentLocation {
            widgets.append(WidgetData(
                id: "coordinates",
                title: "Coordinates",
                value: String(format: "%.6f°", location.coordinate.latitude),
                subtitle: String(format: "%.6f°", location.coordinate.longitude),
                icon: "globe",
                color: TreeShopTheme.primaryText
            ))
        }
        
        // Altitude
        if let altitude = cachedGPSData?.altitude {
            widgets.append(WidgetData(
                id: "altitude",
                title: "Elevation",
                value: String(format: "%.1f ft", altitude * 3.28084), // Convert m to ft
                subtitle: "Above sea level",
                icon: "mountain.2.fill",
                color: TreeShopTheme.accentGreen
            ))
        }
        
        return widgets
    }
    
    // MARK: - Package Selection Widgets
    
    private func getPackageSelectionWidgets() -> [WidgetData] {
        refreshCachedData()
        
        var widgets: [WidgetData] = []
        
        for package in ServicePackage.allCases {
            let isSelected = getCurrentSelectedPackage() == package
            let cost = calculateCostForPackage(package)
            
            widgets.append(WidgetData(
                id: "package_\(package.rawValue)",
                title: package.description,
                value: "$\(String(format: "%.0f", cost))",
                subtitle: "\(package.rawValue) Package",
                icon: isSelected ? "checkmark.circle.fill" : "circle",
                color: isSelected ? TreeShopTheme.primaryGreen : package.color,
                action: { [weak self] in
                    self?.selectPackage(package)
                }
            ))
        }
        
        return widgets
    }
    
    // MARK: - Action Methods
    
    private func getDefaultActions() -> [ScoreboardAction] {
        return [
            ScoreboardAction(
                id: "draw_area",
                title: "Draw Area",
                icon: "pencil.circle",
                style: .primary
            ) { [weak self] in
                self?.startAreaDrawing()
            },
            ScoreboardAction(
                id: "assess_tree",
                title: "Assess Tree",
                icon: "tree.circle",
                style: .secondary
            ) { [weak self] in
                self?.startTreeAssessment()
            },
            ScoreboardAction(
                id: "measure",
                title: "Measure",
                icon: "ruler.fill",
                style: .secondary
            ) { [weak self] in
                self?.startMeasurement()
            }
        ]
    }
    
    private func getAreaDrawingActions() -> [ScoreboardAction] {
        var actions: [ScoreboardAction] = []
        
        if (cachedAreaData?.pointCount ?? 0) >= 3 {
            actions.append(ScoreboardAction(
                id: "complete_area",
                title: "Complete",
                icon: "checkmark.circle.fill",
                style: .success
            ) { [weak self] in
                self?.completeAreaDrawing()
            })
        }
        
        actions.append(ScoreboardAction(
            id: "undo_point",
            title: "Undo",
            icon: "arrow.uturn.backward",
            style: .secondary
        ) { [weak self] in
            self?.undoLastPoint()
        })
        
        actions.append(ScoreboardAction(
            id: "clear_area",
            title: "Clear",
            icon: "trash",
            style: .destructive
        ) { [weak self] in
            self?.clearCurrentArea()
        })
        
        return actions
    }
    
    private func getTreeInventoryActions() -> [ScoreboardAction] {
        return [
            ScoreboardAction(
                id: "new_assessment",
                title: "New Tree",
                icon: "plus.circle.fill",
                style: .primary
            ) { [weak self] in
                self?.startNewTreeAssessment()
            },
            ScoreboardAction(
                id: "view_inventory",
                title: "View All",
                icon: "list.bullet",
                style: .secondary
            ) { [weak self] in
                self?.showTreeInventoryList()
            },
            ScoreboardAction(
                id: "export_data",
                title: "Export",
                icon: "square.and.arrow.up",
                style: .secondary
            ) { [weak self] in
                self?.exportTreeData()
            }
        ]
    }
    
    private func getMeasurementActions() -> [ScoreboardAction] {
        return [
            ScoreboardAction(
                id: "start_measurement",
                title: "Start",
                icon: "play.circle.fill",
                style: .primary
            ) { [weak self] in
                self?.startPreciseMeasurement()
            },
            ScoreboardAction(
                id: "calibrate_gps",
                title: "Calibrate",
                icon: "location.magnifyingglass",
                style: .secondary
            ) { [weak self] in
                self?.calibrateGPS()
            }
        ]
    }
    
    private func getPackageSelectionActions() -> [ScoreboardAction] {
        return [
            ScoreboardAction(
                id: "apply_package",
                title: "Apply",
                icon: "checkmark.circle.fill",
                style: .primary
            ) { [weak self] in
                self?.applySelectedPackage()
            },
            ScoreboardAction(
                id: "compare_packages",
                title: "Compare",
                icon: "chart.bar.xaxis",
                style: .secondary
            ) { [weak self] in
                self?.showPackageComparison()
            }
        ]
    }
    
    // MARK: - Data Management
    
    func refreshData() {
        refreshCachedData()
        
        // Notify widgets of data updates
        NotificationCenter.default.post(name: .scoreboardDataUpdated, object: nil)
    }
    
    private func refreshCachedData() {
        cachedAreaData = getCurrentAreaData()
        cachedTreeData = getCurrentTreeData()
        cachedGPSData = getCurrentGPSData()
    }
    
    private func setupDataObservation() {
        // Observe location updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidUpdate),
            name: .locationManagerDidUpdateLocation,
            object: nil
        )
        
        // Observe drawing updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(drawingDidUpdate),
            name: .drawingManagerDidUpdateArea,
            object: nil
        )
        
        // Observe tree inventory updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(treeInventoryDidUpdate),
            name: .treeInventoryDidUpdate,
            object: nil
        )
    }
    
    @objc private func locationDidUpdate() {
        cachedGPSData = getCurrentGPSData()
        refreshData()
    }
    
    @objc private func drawingDidUpdate() {
        cachedAreaData = getCurrentAreaData()
        refreshData()
    }
    
    @objc private func treeInventoryDidUpdate() {
        cachedTreeData = getCurrentTreeData()
        refreshData()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentAreaData() -> AreaMeasurementData? {
        // Implementation would get data from MapViewController
        // This is a simplified version
        return AreaMeasurementData(
            area: 0.12,
            perimeter: 293.5,
            pointCount: 4,
            completionProgress: 0.8
        )
    }
    
    private func getCurrentTreeData() -> TreeInventoryData? {
        let trees = TreeInventoryManager.shared.getTrees()
        guard !trees.isEmpty else { return nil }
        
        let totalScore = trees.reduce(0) { $0 + $1.treeScore.finalTreeScore }
        let avgScore = totalScore / Double(trees.count)
        
        var complexityBreakdown: [TreeComplexity: Int] = [:]
        for tree in trees {
            let complexity = tree.getComplexityLevel()
            complexityBreakdown[complexity, default: 0] += 1
        }
        
        return TreeInventoryData(
            treeCount: trees.count,
            totalTreeScore: totalScore,
            averageTreeScore: avgScore,
            complexityBreakdown: complexityBreakdown,
            lastAssessedTree: trees.last
        )
    }
    
    private func getCurrentGPSData() -> GPSData? {
        // Get from LocationManager
        return GPSData(
            accuracy: 2.1,
            satelliteCount: 8,
            currentLocation: mapViewController?.mapView.userLocation.location,
            altitude: mapViewController?.mapView.userLocation.location?.altitude
        )
    }
    
    private func getGPSAccuracyColor() -> UIColor {
        let accuracy = cachedGPSData?.accuracy ?? 10.0
        switch accuracy {
        case 0..<3: return TreeShopTheme.successGreen
        case 3..<5: return TreeShopTheme.warningYellow
        default: return TreeShopTheme.errorRed
        }
    }
    
    private func getSatelliteColor() -> UIColor {
        let count = cachedGPSData?.satelliteCount ?? 0
        switch count {
        case 8...: return TreeShopTheme.successGreen
        case 5..<8: return TreeShopTheme.warningYellow
        default: return TreeShopTheme.errorRed
        }
    }
    
    private func getTreeScoreColor(_ score: Double) -> UIColor {
        switch score {
        case 0..<500: return TreeShopTheme.successGreen
        case 500..<1500: return TreeShopTheme.warningYellow
        case 1500..<3000: return TreeShopTheme.errorRed
        default: return UIColor.systemPurple
        }
    }
    
    private func getAreaTrend() -> WidgetTrend? {
        // Could implement trend analysis here
        return nil
    }
    
    private func calculateEstimatedCost() -> Double? {
        guard let area = cachedAreaData?.area, area > 0 else { return nil }
        let package = getCurrentSelectedPackage()
        return area * package.pricePerAcre
    }
    
    private func calculateCostForPackage(_ package: ServicePackage) -> Double {
        let area = cachedAreaData?.area ?? 0.12 // Default demo area
        return area * package.pricePerAcre
    }
    
    private func getCurrentSelectedPackage() -> ServicePackage {
        return .medium // Default selection
    }
    
    private func getDailyAreaCount() -> Int {
        return 3 // Demo value
    }
    
    // MARK: - Action Implementations (Simplified)
    
    private func showAreaDetails() { }
    private func showTreeInventory() { }
    private func startAreaDrawing() { }
    private func startTreeAssessment() { }
    private func startMeasurement() { }
    private func completeAreaDrawing() { }
    private func undoLastPoint() { }
    private func clearCurrentArea() { }
    private func startNewTreeAssessment() { }
    private func showTreeInventoryList() { }
    private func exportTreeData() { }
    private func startPreciseMeasurement() { }
    private func calibrateGPS() { }
    private func selectPackage(_ package: ServicePackage) { }
    private func applySelectedPackage() { }
    private func showPackageComparison() { }
}

// MARK: - Data Structures

struct AreaMeasurementData {
    let area: Double
    let perimeter: Double
    let pointCount: Int
    let completionProgress: Float
}

struct TreeInventoryData {
    let treeCount: Int
    let totalTreeScore: Double
    let averageTreeScore: Double
    let complexityBreakdown: [TreeComplexity: Int]
    let lastAssessedTree: TreeInventoryItem?
}

struct GPSData {
    let accuracy: Double
    let satelliteCount: Int
    let currentLocation: CLLocation?
    let altitude: Double?
}

// MARK: - Notifications

extension Notification.Name {
    static let scoreboardDataUpdated = Notification.Name("ScoreboardDataUpdated")
    static let locationManagerDidUpdateLocation = Notification.Name("LocationManagerDidUpdateLocation")
    static let drawingManagerDidUpdateArea = Notification.Name("DrawingManagerDidUpdateArea")
    static let treeInventoryDidUpdate = Notification.Name("TreeInventoryDidUpdate")
}