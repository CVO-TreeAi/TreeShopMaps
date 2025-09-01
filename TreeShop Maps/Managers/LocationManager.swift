import Foundation
import CoreLocation
import MapKit
import UIKit

protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: LocationManager, didUpdateBoundaryDistance distance: Double, zone: BoundaryZone)
    func locationManager(_ manager: LocationManager, didUpdateHeading heading: CLHeading)
}

enum BoundaryZone {
    case critical
    case warning
    case safe
    case none
    
    var color: UIColor {
        switch self {
        case .critical: return .red
        case .warning: return UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        case .safe: return .green
        case .none: return .clear
        }
    }
    
    var message: String {
        switch self {
        case .critical: return "BOUNDARY - 15 FT"
        case .warning: return "Approaching Edge - 30 FT"
        case .safe: return "Safe Zone"
        case .none: return ""
        }
    }
    
    var hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .critical: return .heavy
        case .warning: return .medium
        case .safe, .none: return nil
        }
    }
}

class LocationManager: NSObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var breadcrumbLocations: [CLLocation] = []
    private var isTracking = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var currentBoundary: MKPolygon?
    private var trackingTimer: Timer?
    
    weak var delegate: LocationManagerDelegate?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func requestLocationPermissions() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            showLocationPermissionAlert()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let alert = UIAlertController(
                    title: "Location Access Required",
                    message: "TreeShop Maps needs location access to track work progress and navigate property boundaries. Please enable location access in Settings.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    func startTracking() {
        isTracking = true
        breadcrumbLocations.removeAll()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordBreadcrumb()
        }
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    func startBackgroundTracking() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        startTracking()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func recordBreadcrumb() {
        guard let location = locationManager.location else { return }
        breadcrumbLocations.append(location)
        
        if breadcrumbLocations.count > 10000 {
            breadcrumbLocations.removeFirst(1000)
        }
    }
    
    func setBoundary(_ polygon: MKPolygon) {
        currentBoundary = polygon
    }
    
    func calculateDistanceToBoundary(from location: CLLocation) -> (distance: Double, zone: BoundaryZone)? {
        guard let boundary = currentBoundary else { return nil }
        
        let coordinate = location.coordinate
        let mapPoint = MKMapPoint(coordinate)
        
        var minDistance = Double.greatestFiniteMagnitude
        let points = boundary.points()
        let pointCount = boundary.pointCount
        
        for i in 0..<pointCount {
            let point1 = points[i]
            let point2 = points[(i + 1) % pointCount]
            
            let distance = distanceFromPoint(mapPoint, toLineSegmentBetween: point1, and: point2)
            minDistance = min(minDistance, distance)
        }
        
        let distanceInFeet = minDistance * 3.28084
        
        let zone: BoundaryZone
        if distanceInFeet <= 15 {
            zone = .critical
        } else if distanceInFeet <= 30 {
            zone = .warning
        } else if distanceInFeet <= 50 {
            zone = .safe
        } else {
            zone = .none
        }
        
        return (distanceInFeet, zone)
    }
    
    private func distanceFromPoint(_ point: MKMapPoint, toLineSegmentBetween p1: MKMapPoint, and p2: MKMapPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        
        if dx == 0 && dy == 0 {
            return point.distance(to: p1)
        }
        
        let t = ((point.x - p1.x) * dx + (point.y - p1.y) * dy) / (dx * dx + dy * dy)
        
        let clampedT = max(0, min(1, t))
        
        let closestPoint = MKMapPoint(x: p1.x + clampedT * dx, y: p1.y + clampedT * dy)
        return point.distance(to: closestPoint)
    }
    
    func getBreadcrumbPath() -> MKPolyline {
        let coordinates = breadcrumbLocations.map { $0.coordinate }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    func getCoveragePolygon(machineWidth: Double = 8.0) -> MKPolygon? {
        guard breadcrumbLocations.count > 2 else { return nil }
        
        var polygonCoordinates: [CLLocationCoordinate2D] = []
        let widthInMeters = machineWidth * 0.3048
        
        for i in 0..<breadcrumbLocations.count {
            let location = breadcrumbLocations[i]
            let coordinate = location.coordinate
            
            var bearing: Double = 0
            if i > 0 {
                let prevLocation = breadcrumbLocations[i - 1]
                bearing = calculateBearing(from: prevLocation.coordinate, to: coordinate)
            } else if i < breadcrumbLocations.count - 1 {
                let nextLocation = breadcrumbLocations[i + 1]
                bearing = calculateBearing(from: coordinate, to: nextLocation.coordinate)
            }
            
            let perpBearing1 = bearing + 90
            let perpBearing2 = bearing - 90
            
            let offset1 = coordinateWithBearing(from: coordinate, bearing: perpBearing1, distance: widthInMeters / 2)
            let offset2 = coordinateWithBearing(from: coordinate, bearing: perpBearing2, distance: widthInMeters / 2)
            
            polygonCoordinates.append(offset1)
            polygonCoordinates.insert(offset2, at: 0)
        }
        
        return MKPolygon(coordinates: polygonCoordinates, count: polygonCoordinates.count)
    }
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y)
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
    
    private func coordinateWithBearing(from coordinate: CLLocationCoordinate2D, bearing: Double, distance: Double) -> CLLocationCoordinate2D {
        let distanceRadians = distance / 6371000.0
        let bearingRadians = bearing * .pi / 180
        let fromLatRadians = coordinate.latitude * .pi / 180
        let fromLonRadians = coordinate.longitude * .pi / 180
        
        let toLatRadians = asin(sin(fromLatRadians) * cos(distanceRadians) + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians))
        let toLonRadians = fromLonRadians + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians) - sin(fromLatRadians) * sin(toLatRadians))
        
        return CLLocationCoordinate2D(latitude: toLatRadians * 180 / .pi, longitude: toLonRadians * 180 / .pi)
    }
    
    func getCurrentLocation() -> CLLocation? {
        return locationManager.location
    }
    
    func getLocationAccuracy() -> CLLocationAccuracy? {
        return locationManager.location?.horizontalAccuracy
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        delegate?.locationManager(self, didUpdateLocation: location)
        
        if let boundaryInfo = calculateDistanceToBoundary(from: location) {
            delegate?.locationManager(self, didUpdateBoundaryDistance: boundaryInfo.distance, zone: boundaryInfo.zone)
            
            if let hapticStyle = boundaryInfo.zone.hapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                generator.impactOccurred()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdateHeading: newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}