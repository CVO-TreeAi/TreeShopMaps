import UIKit
import MapKit
import CoreLocation

// MARK: - TreeScore Integration Extension
extension MainMapViewController: TreeScoreInputDelegate {
    
    // MARK: - TreeScore Properties (add these to main class)
    /*
    Add these properties to the main MainMapViewController class:
    
    // TreeScore Properties
    private var treeInventoryMode: Bool = false
    private var treeScoreAnnotations: [TreeScoreAnnotation] = []
    private var pendingTreeLocation: CLLocationCoordinate2D?
    */
    
    // MARK: - TreeScore Mode Management
    func enableTreeScoreMode() {
        // Update mode to show we're in tree inventory mode
        currentModeLabel.text = "Tree Inventory Mode - Tap map to add trees"
        currentModeLabel.backgroundColor = TreeShopTheme.primaryGreen
        
        // Enable tree inventory mode flag (need to add this property to main class)
        // treeInventoryMode = true
        
        // Update toolbar to show TreeScore tools
        updateToolbarForTreeScoreMode()
        
        print("🌲 TreeScore inventory mode activated")
    }
    
    func disableTreeScoreMode() {
        currentModeLabel.text = "Ready"
        currentModeLabel.backgroundColor = UIColor.red
        
        // treeInventoryMode = false
        
        // Restore normal toolbar
        updateToolbarForMode(.normal)
        
        print("🌲 TreeScore inventory mode deactivated")
    }
    
    private func updateToolbarForTreeScoreMode() {
        // Create TreeScore-specific toolbar buttons
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Tree inventory button (active/highlighted)
        let treeBtn = UIBarButtonItem(
            image: UIImage(systemName: "tree.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleTreeInventoryMode)
        )
        treeBtn.tintColor = TreeShopTheme.primaryGreen
        
        // Drawing button (inactive)
        let drawBtn = UIBarButtonItem(
            image: UIImage(systemName: "pencil.tip.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleDrawingMode)
        )
        
        // Measuring button
        let measureBtn = UIBarButtonItem(
            image: UIImage(systemName: "ruler"),
            style: .plain,
            target: self,
            action: #selector(toggleMeasuringMode)
        )
        
        // Export TreeScore data button
        let exportBtn = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportTreeScoreData)
        )
        
        // More options button
        let moreBtn = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )
        
        toolbar.items = [treeBtn, flexSpace, drawBtn, flexSpace, measureBtn, flexSpace, exportBtn, flexSpace, moreBtn]
    }
    
    // MARK: - TreeScore Actions
    @objc private func toggleTreeInventoryMode() {
        if currentMode == .normal {
            currentMode = .measuring // Reuse measuring mode logic but for trees
            enableTreeScoreMode()
        } else {
            currentMode = .normal
            disableTreeScoreMode()
        }
    }
    
    @objc private func toggleMeasuringMode() {
        // Switch to regular measuring mode
        currentMode = currentMode == .measuring ? .normal : .measuring
        disableTreeScoreMode()
        updateToolbarForMode(currentMode)
    }
    
    @objc private func exportTreeScoreData() {
        guard let exportURL = TreeInventoryManager.shared.exportTreeScoreData() else {
            showAlert(title: "Export Failed", message: "Unable to export TreeScore data.")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
        
        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = toolbar.items?.first { item in
                item.image == UIImage(systemName: "square.and.arrow.up")
            }
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - Map Touch Handling for TreeScore
    func handleTreeInventoryMapTap(at coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        // Store the pending location
        // pendingTreeLocation = coordinate
        
        // Present TreeScore input controller
        let treeScoreVC = TreeScoreInputViewController()
        treeScoreVC.delegate = self
        treeScoreVC.setLocation(coordinate, accuracy: accuracy)
        
        // Pre-select service package if we have area measurements
        if let lastMeasurement = getLastAreaMeasurement() {
            let suggestedPackage = suggestServicePackage(forArea: lastMeasurement.value)
            treeScoreVC.setPrefilledServicePackage(suggestedPackage)
        }
        
        // Present modally with navigation
        let navController = UINavigationController(rootViewController: treeScoreVC)
        navController.modalPresentationStyle = .formSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(navController, animated: true)
    }
    
    // MARK: - TreeScoreInputDelegate
    func didCreateTreeInventoryItem(_ item: TreeInventoryItem) {
        // Add to inventory manager
        TreeInventoryManager.shared.addTree(item)
        
        // Create and add map annotation
        let annotation = item.createMapAnnotation()
        mapView.addAnnotation(annotation)
        
        // Store annotation for management
        // treeScoreAnnotations.append(annotation)
        
        // Update area label with tree count and total TreeScore
        updateAreaLabelWithTreeScoreInfo()
        
        // Dismiss the input controller
        dismiss(animated: true) {
            self.showTreeAddedConfirmation(treeScore: item.treeScore.finalTreeScore)
        }
        
        print("🌲 Added tree with TreeScore: \(item.treeScore.finalTreeScore)")
    }
    
    func didCancelTreeInput() {
        dismiss(animated: true)
    }
    
    // MARK: - Helper Methods
    private func getLastAreaMeasurement() -> StoredMeasurement? {
        return MeasurementHistoryManager.shared.getMeasurements().first { $0.type == .area }
    }
    
    private func suggestServicePackage(forArea acres: Double) -> ServicePackage {
        // Suggest service package based on area size
        switch acres {
        case 0..<0.5:
            return .small
        case 0.5..<2.0:
            return .medium
        case 2.0..<5.0:
            return .large
        case 5.0..<10.0:
            return .xLarge
        default:
            return .max
        }
    }
    
    private func updateAreaLabelWithTreeScoreInfo() {
        let trees = TreeInventoryManager.shared.getTrees()
        let totalTreeScore = TreeInventoryManager.shared.getTotalTreeScore()
        let averageTreeScore = TreeInventoryManager.shared.getAverageTreeScore()
        
        if trees.isEmpty {
            areaLabel.text = "0.00 acres | No trees"
        } else {
            // Get the last area measurement if available
            if let lastMeasurement = getLastAreaMeasurement() {
                areaLabel.text = String(format: "%.2f acres | %d trees | Avg TS: %.0f", 
                                      lastMeasurement.value, trees.count, averageTreeScore)
            } else {
                areaLabel.text = String(format: "%d trees | Total TS: %.0f | Avg: %.0f", 
                                      trees.count, totalTreeScore, averageTreeScore)
            }
        }
    }
    
    private func showTreeAddedConfirmation(treeScore: Double) {
        let complexity = getTreeComplexity(for: treeScore)
        
        let alert = UIAlertController(
            title: "🌲 Tree Added to Inventory",
            message: String(format: "TreeScore: %.0f pts\nComplexity: %@", treeScore, complexity.rawValue),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Add Another", style: .default) { _ in
            // Keep in tree inventory mode
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { _ in
            self.disableTreeScoreMode()
        })
        
        present(alert, animated: true)
    }
    
    private func getTreeComplexity(for treeScore: Double) -> TreeComplexity {
        switch treeScore {
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TreeScore Map Annotation View
extension MainMapViewController {
    
    func createTreeScoreAnnotationView(for annotation: TreeScoreAnnotation, on mapView: MKMapView) -> MKAnnotationView? {
        let identifier = "TreeScoreAnnotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: 0, y: -5)
            
            // Add detail disclosure button
            let detailButton = UIButton(type: .detailDisclosure)
            detailButton.tintColor = TreeShopTheme.primaryGreen
            annotationView?.rightCalloutAccessoryView = detailButton
        } else {
            annotationView?.annotation = annotation
        }
        
        // Set custom tree icon based on complexity
        if let treeItem = annotation.treeInventoryItem {
            let complexity = treeItem.getComplexityLevel()
            annotationView?.image = createTreeIcon(for: complexity)
        } else {
            annotationView?.image = createTreeIcon(for: .medium)
        }
        
        return annotationView
    }
    
    private func createTreeIcon(for complexity: TreeComplexity) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
        let baseImage = UIImage(systemName: complexity.iconName, withConfiguration: config)
        
        // Tint the image with complexity color
        return baseImage?.withTintColor(complexity.color, renderingMode: .alwaysOriginal)
    }
    
    func handleTreeScoreAnnotationTap(_ annotation: TreeScoreAnnotation) {
        guard let treeItem = annotation.treeInventoryItem else { return }
        
        let alert = UIAlertController(
            title: "🌲 Tree Details",
            message: String(format: """
            TreeScore: %@
            Species: %@
            Height: %.1f ft
            Canopy Radius: %.1f ft
            DBH: %.1f in
            AFISS Impact: %.0f%%
            Estimated Time: %@
            Estimated Cost: %@
            GPS Accuracy: ±%.1fm
            """,
            treeItem.getFormattedTreeScore(),
            treeItem.species ?? "Unknown",
            treeItem.height,
            treeItem.canopyRadius,
            treeItem.dbh,
            treeItem.afissPercentage,
            treeItem.getFormattedEstimatedTime() ?? "N/A",
            treeItem.getFormattedEstimatedCost() ?? "N/A",
            treeItem.gpsAccuracy
            ),
            preferredStyle: .alert
        )
        
        // Edit button
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { _ in
            self.editTreeItem(treeItem)
        })
        
        // Delete button
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteTreeItem(treeItem)
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func editTreeItem(_ treeItem: TreeInventoryItem) {
        let treeScoreVC = TreeScoreInputViewController()
        treeScoreVC.delegate = self
        treeScoreVC.setLocation(treeItem.coordinate, accuracy: treeItem.gpsAccuracy)
        
        // Pre-fill with existing values would require additional setup in TreeScoreInputViewController
        
        let navController = UINavigationController(rootViewController: treeScoreVC)
        navController.modalPresentationStyle = .formSheet
        
        present(navController, animated: true)
    }
    
    private func deleteTreeItem(_ treeItem: TreeInventoryItem) {
        // Remove from inventory manager
        TreeInventoryManager.shared.deleteTree(by: treeItem.id)
        
        // Remove annotation from map
        if let annotationToRemove = mapView.annotations.first(where: { annotation in
            if let treeAnnotation = annotation as? TreeScoreAnnotation {
                return treeAnnotation.treeInventoryItem?.id == treeItem.id
            }
            return false
        }) {
            mapView.removeAnnotation(annotationToRemove)
        }
        
        // Update display
        updateAreaLabelWithTreeScoreInfo()
        
        showAlert(title: "Tree Deleted", message: "Tree has been removed from inventory.")
    }
}

// MARK: - TreeScore Statistics and Reporting
extension MainMapViewController {
    
    func showTreeScoreStatistics() {
        let trees = TreeInventoryManager.shared.getTrees()
        let treesByComplexity = TreeInventoryManager.shared.getTreesByComplexity()
        
        guard !trees.isEmpty else {
            showAlert(title: "No Trees", message: "No trees have been added to inventory yet.")
            return
        }
        
        let totalTreeScore = TreeInventoryManager.shared.getTotalTreeScore()
        let averageTreeScore = TreeInventoryManager.shared.getAverageTreeScore()
        
        var message = String(format: """
        Total Trees: %d
        Total TreeScore: %.0f pts
        Average TreeScore: %.0f pts
        
        Complexity Breakdown:
        """, trees.count, totalTreeScore, averageTreeScore)
        
        for complexity in TreeComplexity.allCases {
            let count = treesByComplexity[complexity]?.count ?? 0
            message += "\n\(complexity.rawValue): \(count) trees"
        }
        
        let alert = UIAlertController(title: "📊 TreeScore Statistics", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Export Data", style: .default) { _ in
            self.exportTreeScoreData()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
}