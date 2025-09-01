import UIKit
import MapKit

extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        setRegion(coordinateRegion, animated: true)
    }
}

extension MKPolygon {
    var area: Double {
        let coordinates = Array(UnsafeBufferPointer(start: self.points(), count: self.pointCount))
        var area = 0.0
        
        for i in 0..<coordinates.count {
            let j = (i + 1) % coordinates.count
            area += coordinates[i].x * coordinates[j].y
            area -= coordinates[j].x * coordinates[i].y
        }
        
        area = abs(area) / 2.0
        
        let metersToAcres = 0.000247105
        return area * metersToAcres
    }
    
    var perimeter: Double {
        let coordinates = Array(UnsafeBufferPointer(start: self.points(), count: self.pointCount))
        var perimeter = 0.0
        
        for i in 0..<coordinates.count {
            let j = (i + 1) % coordinates.count
            let distance = sqrt(pow(coordinates[j].x - coordinates[i].x, 2) + pow(coordinates[j].y - coordinates[i].y, 2))
            perimeter += distance
        }
        
        let metersToFeet = 3.28084
        return perimeter * metersToFeet
    }
}

extension UIColor {
    static let treeGreen = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1.0)
    static let workZoneBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.3)
    static let boundaryRed = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
}

extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

extension Double {
    var formattedAcres: String {
        return String(format: "%.2f acres", self)
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }
    
    var formattedDistance: String {
        if self < 1000 {
            return String(format: "%.0f ft", self)
        } else {
            let miles = self / 5280
            return String(format: "%.2f mi", miles)
        }
    }
}

extension CLLocationCoordinate2D {
    static func isEqual(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 0.00001 &&
               abs(lhs.longitude - rhs.longitude) < 0.00001
    }
}

extension UIViewController {
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func showConfirmation(title: String, message: String, confirmTitle: String = "Confirm", cancelTitle: String = "Cancel", onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }
}

extension FileManager {
    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func cacheDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func sizeOfFile(at url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}

extension MKMapPoint {
    func distance(to point: MKMapPoint) -> Double {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}