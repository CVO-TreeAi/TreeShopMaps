import Foundation
import MapKit
import UIKit

class WorkArea: NSObject {
    let polygon: MKPolygon
    let servicePackage: ServicePackage
    let area: Double // in acres
    let perimeter: Double // in feet
    let estimatedCost: Double
    let estimatedHours: Double
    let dateCreated: Date
    var name: String
    
    init(polygon: MKPolygon, servicePackage: ServicePackage, name: String = "") {
        self.polygon = polygon
        self.servicePackage = servicePackage
        self.name = name.isEmpty ? servicePackage.description : name
        self.dateCreated = Date()
        
        // Calculate area and perimeter
        let area = WorkArea.calculateArea(polygon: polygon)
        self.area = area
        self.perimeter = WorkArea.calculatePerimeter(polygon: polygon)
        
        // Calculate estimates based on service package
        self.estimatedCost = area * servicePackage.pricePerAcre
        self.estimatedHours = area * servicePackage.estimatedHoursPerAcre
        
        super.init()
        
        // Set polygon properties for display
        polygon.title = servicePackage.rawValue
        polygon.subtitle = String(format: "%.2f acres - $%.0f", area, estimatedCost)
    }
    
    // MARK: - Area and Perimeter Calculations
    
    private static func calculateArea(polygon: MKPolygon) -> Double {
        let points = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        var area: Double = 0
        
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            let xi = points[i].coordinate.longitude
            let yi = points[i].coordinate.latitude
            let xj = points[j].coordinate.longitude
            let yj = points[j].coordinate.latitude
            
            area += xi * yj - xj * yi
        }
        
        area = abs(area) / 2.0
        
        // Convert from decimal degrees to acres (rough approximation)
        let squareMetersPerDegreeSquared = 111000 * 111000 * cos(points.first?.coordinate.latitude ?? 0)
        let squareMeters = area * squareMetersPerDegreeSquared
        let acres = squareMeters / 4047 // Convert square meters to acres
        
        return acres
    }
    
    private static func calculatePerimeter(polygon: MKPolygon) -> Double {
        let points = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        var perimeter: Double = 0
        
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            let point1 = CLLocation(latitude: points[i].coordinate.latitude, longitude: points[i].coordinate.longitude)
            let point2 = CLLocation(latitude: points[j].coordinate.latitude, longitude: points[j].coordinate.longitude)
            perimeter += point1.distance(from: point2)
        }
        
        return perimeter * 3.28084 // Convert meters to feet
    }
    
    // MARK: - Display Information
    
    var detailedInfo: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let cost = formatter.string(from: NSNumber(value: estimatedCost)) ?? "$\(Int(estimatedCost))"
        
        return """
        📏 Area: \(String(format: "%.2f", area)) acres
        📐 Perimeter: \(String(format: "%.0f", perimeter)) ft
        🌳 Service: \(servicePackage.description)
        💰 Estimated Cost: \(cost)
        ⏱️ Estimated Time: \(String(format: "%.1f", estimatedHours)) hours
        📅 Created: \(DateFormatter.localizedString(from: dateCreated, dateStyle: .short, timeStyle: .short))
        """
    }
    
    var color: UIColor {
        return servicePackage.color
    }
    
    var strokeColor: UIColor {
        return servicePackage.color.withAlphaComponent(1.0)
    }
    
    // MARK: - Package Label for Edge Display
    
    func createPackageLabel(at coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = servicePackage.rawValue
        annotation.subtitle = String(format: "%.1f ac", area)
        return annotation
    }
    
    // Get center coordinate for label placement
    var centerCoordinate: CLLocationCoordinate2D {
        let points = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        let sumLat = points.reduce(0) { $0 + $1.coordinate.latitude }
        let sumLon = points.reduce(0) { $0 + $1.coordinate.longitude }
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(points.count),
            longitude: sumLon / Double(points.count)
        )
    }
}

// MARK: - Custom Annotation for Work Area Labels
class WorkAreaLabel: MKPointAnnotation {
    let workArea: WorkArea
    
    init(workArea: WorkArea) {
        self.workArea = workArea
        super.init()
        
        self.coordinate = workArea.centerCoordinate
        self.title = workArea.servicePackage.rawValue
        self.subtitle = String(format: "%.1f acres", workArea.area)
    }
}