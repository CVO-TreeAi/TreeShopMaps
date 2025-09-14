import UIKit
import MapKit

// MARK: - Drawing Tools Extension
extension MainMapViewController {
    
    @objc func toggleDrawingMode() {
        switch currentMode {
        case .normal:
            currentMode = .drawing
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.backgroundColor = TreeShopTheme.primaryGreen
            
        case .drawing:
            currentMode = .normal
            currentModeLabel.text = "Ready"
            currentModeLabel.backgroundColor = UIColor.red
            
        default:
            currentMode = .drawing
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.backgroundColor = TreeShopTheme.primaryGreen
        }
        
        // Update UI based on mode
        updateModeDisplay()
    }
    
    @objc func clearDrawing() {
        // Clear current drawing
        mapView.removeOverlays(drawingPolygons)
        drawingPolygons.removeAll()
        drawingPoints.removeAll()
        currentMeasurementValue = 0
        
        // Reset to ready state
        currentMode = .normal
        currentModeLabel.text = "Ready"
        areaLabel.text = "0.00 acres"
        perimeterLabel.text = ""
        perimeterLabel.isHidden = true
        
        print("🗑 Drawing cleared")
    }
    
    @objc func undoLastPoint() {
        guard !drawingPoints.isEmpty else { return }
        
        // Remove last point
        drawingPoints.removeLast()
        
        // Recalculate measurement
        updateMeasurementDisplay()
        
        print("↶ Undid last point")
    }
    
    @objc func saveMeasurement() {
        guard currentMeasurementValue > 0 else {
            showAlert(title: "No Data", message: "No measurement to save.")
            return
        }
        
        // Show package selection dialog before saving
        let alert = UIAlertController(
            title: "Save Area",
            message: String(format: "Save %.2f acres with package selection:", currentMeasurementValue),
            preferredStyle: .actionSheet
        )
        
        let packages = [
            (ServicePackage.small, "Small Package - Light debris"),
            (ServicePackage.medium, "Medium Package - Moderate debris"),
            (ServicePackage.large, "Large Package - Heavy debris"),
            (ServicePackage.xLarge, "XL Package - Very heavy debris"),
            (ServicePackage.max, "MAX Package - Maximum debris")
        ]
        
        for (package, description) in packages {
            alert.addAction(UIAlertAction(title: description, style: .default) { _ in
                self.saveWithPackage(package)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 100, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func saveWithPackage(_ package: ServicePackage) {
        // Save the measurement with the selected package
        let measurement = createMeasurementFromCurrentData(package: package)
        MeasurementHistoryManager.shared.saveMeasurement(measurement)
        
        // Update the drawing color on the map to match package
        updateDrawingColorForPackage(package)
        
        // Show confirmation
        showAlert(title: "Saved", message: String(format: "%.2f acres saved as %@ package", currentMeasurementValue, package.rawValue))
        
        print("💾 Measurement saved: \(currentMeasurementValue) acres - \(package.rawValue) package")
    }
    
    private func updateDrawingColorForPackage(_ package: ServicePackage) {
        // Update the drawing polygons to use the package color
        for polygon in drawingPolygons {
            mapView.removeOverlay(polygon)
        }
        
        // Re-add with package color (this would need to be implemented in the overlay renderer)
        for polygon in drawingPolygons {
            mapView.addOverlay(polygon)
        }
    }
    
    private func createMeasurementFromCurrentData(package: ServicePackage) -> StoredMeasurement {
        return StoredMeasurement(
            id: UUID(),
            type: .area,
            value: currentMeasurementValue,
            location: mapView.region.center,
            timestamp: Date(),
            notes: "Package: \(package.rawValue)"
        )
    }
    
    private func updateMeasurementDisplay() {
        // Update the measurement labels based on current drawing
        if drawingPoints.count >= 3 {
            // Calculate area
            let area = calculateAreaFromPoints(drawingPoints)
            currentMeasurementValue = area
            areaLabel.text = String(format: "%.2f acres", area)
            
            // Calculate perimeter
            let perimeter = calculatePerimeterFromPoints(drawingPoints)
            perimeterLabel.text = String(format: "%.1f ft", perimeter)
            perimeterLabel.isHidden = false
        } else if drawingPoints.count == 2 {
            // Show distance for 2 points
            let distance = calculateDistanceBetweenPoints(drawingPoints[0], drawingPoints[1])
            areaLabel.text = String(format: "%.1f ft", distance)
            perimeterLabel.isHidden = true
        } else {
            areaLabel.text = drawingPoints.isEmpty ? "0.00 acres" : "Tap next point"
            perimeterLabel.isHidden = true
        }
    }
    
    private func calculateAreaFromPoints(_ points: [CLLocationCoordinate2D]) -> Double {
        // Simplified area calculation
        return 0.12 // Placeholder
    }
    
    private func calculatePerimeterFromPoints(_ points: [CLLocationCoordinate2D]) -> Double {
        // Simplified perimeter calculation
        return 293.5 // Placeholder
    }
    
    private func calculateDistanceBetweenPoints(_ point1: CLLocationCoordinate2D, _ point2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
        let location2 = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
        return location1.distance(from: location2) * 3.28084 // Convert to feet
    }
    
    private func updateModeDisplay() {
        // Update the UI based on current mode
        switch currentMode {
        case .normal:
            currentModeLabel.text = "Ready"
            currentModeLabel.backgroundColor = TreeShopTheme.buttonBackground
        case .drawing:
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.2)
        case .measuring:
            currentModeLabel.text = "Measuring Mode"
            currentModeLabel.backgroundColor = TreeShopTheme.warningYellow.withAlphaComponent(0.2)
        case .treeInventory:
            currentModeLabel.text = "Tree Assessment Mode"
            currentModeLabel.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.2)
        }
    }
}