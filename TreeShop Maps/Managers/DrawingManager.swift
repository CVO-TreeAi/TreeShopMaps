import Foundation
import MapKit
import UIKit

enum DrawingTool {
    case polygon
    case freehand
    case rectangle
    case circle
    case eraser
    
    var name: String {
        switch self {
        case .polygon: return "Polygon"
        case .freehand: return "Freehand"
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .eraser: return "Eraser"
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .polygon: return UIImage(systemName: "pentagon")
        case .freehand: return UIImage(systemName: "pencil.tip")
        case .rectangle: return UIImage(systemName: "rectangle")
        case .circle: return UIImage(systemName: "circle")
        case .eraser: return UIImage(systemName: "eraser")
        }
    }
}

protocol DrawingManagerDelegate: AnyObject {
    func drawingManager(_ manager: DrawingManager, didCreatePolygon polygon: MKPolygon, servicePackage: ServicePackage)
    func drawingManager(_ manager: DrawingManager, didUpdatePolygon polygon: MKPolygon)
    func drawingManager(_ manager: DrawingManager, didDeletePolygon polygon: MKPolygon)
    func drawingManagerDidStartDrawing(_ manager: DrawingManager)
    func drawingManagerDidEndDrawing(_ manager: DrawingManager)
}

class DrawingManager: NSObject {
    weak var delegate: DrawingManagerDelegate?
    weak var mapView: MKMapView?
    
    private var currentTool: DrawingTool = .polygon
    private var currentServicePackage: ServicePackage = .medium
    private var isDrawing = false
    
    private var drawingPoints: [CLLocationCoordinate2D] = []
    private var tempOverlay: MKOverlay?
    private var activePolygons: [MKPolygon] = []
    
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    init(mapView: MKMapView) {
        self.mapView = mapView
        super.init()
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer?.delegate = self
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer?.delegate = self
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer?.delegate = self
        
        if let mapView = mapView {
            mapView.addGestureRecognizer(tapGestureRecognizer!)
            mapView.addGestureRecognizer(panGestureRecognizer!)
            mapView.addGestureRecognizer(longPressGestureRecognizer!)
        }
        
        panGestureRecognizer?.isEnabled = false
        tapGestureRecognizer?.isEnabled = false
        longPressGestureRecognizer?.isEnabled = false
    }
    
    func setCurrentTool(_ tool: DrawingTool) {
        currentTool = tool
        resetDrawing()
        
        switch tool {
        case .polygon, .rectangle:
            tapGestureRecognizer?.isEnabled = true
            panGestureRecognizer?.isEnabled = false
        case .freehand, .circle:
            tapGestureRecognizer?.isEnabled = false
            panGestureRecognizer?.isEnabled = true
        case .eraser:
            tapGestureRecognizer?.isEnabled = true
            panGestureRecognizer?.isEnabled = false
        }
    }
    
    func setServicePackage(_ package: ServicePackage) {
        currentServicePackage = package
    }
    
    func startDrawing() {
        isDrawing = true
        drawingPoints.removeAll()
        delegate?.drawingManagerDidStartDrawing(self)
        
        mapView?.isScrollEnabled = false
        mapView?.isZoomEnabled = false
        mapView?.isRotateEnabled = false
    }
    
    func endDrawing() {
        isDrawing = false
        
        mapView?.isScrollEnabled = true
        mapView?.isZoomEnabled = true
        mapView?.isRotateEnabled = true
        
        if let overlay = tempOverlay {
            mapView?.removeOverlay(overlay)
            tempOverlay = nil
        }
        
        drawingPoints.removeAll()
        delegate?.drawingManagerDidEndDrawing(self)
    }
    
    private func resetDrawing() {
        endDrawing()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        switch currentTool {
        case .polygon:
            handlePolygonTap(coordinate)
        case .rectangle:
            handleRectangleTap(coordinate)
        case .eraser:
            handleEraserTap(point)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let mapView = mapView else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        switch gesture.state {
        case .began:
            startDrawing()
            drawingPoints.append(coordinate)
        case .changed:
            switch currentTool {
            case .freehand:
                handleFreehandDraw(coordinate)
            case .circle:
                handleCircleDraw(coordinate)
            default:
                break
            }
        case .ended, .cancelled:
            finishCurrentDrawing()
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            resetDrawing()
        }
    }
    
    private func handlePolygonTap(_ coordinate: CLLocationCoordinate2D) {
        if !isDrawing {
            startDrawing()
        }
        
        drawingPoints.append(coordinate)
        updateTempPolygon()
        
        if drawingPoints.count >= 3 && isNearFirstPoint(coordinate) {
            finishPolygon()
        }
    }
    
    private func handleRectangleTap(_ coordinate: CLLocationCoordinate2D) {
        if !isDrawing {
            startDrawing()
            drawingPoints.append(coordinate)
        } else if drawingPoints.count == 1 {
            drawingPoints.append(coordinate)
            createRectangle()
            finishCurrentDrawing()
        }
    }
    
    private func handleFreehandDraw(_ coordinate: CLLocationCoordinate2D) {
        drawingPoints.append(coordinate)
        
        if drawingPoints.count % 5 == 0 {
            drawingPoints = simplifyPath(drawingPoints)
        }
        
        updateTempPolygon()
    }
    
    private func handleCircleDraw(_ coordinate: CLLocationCoordinate2D) {
        guard drawingPoints.count > 0 else { return }
        
        let center = drawingPoints[0]
        let radius = distance(from: center, to: coordinate)
        
        let circlePoints = createCirclePoints(center: center, radius: radius)
        
        if let overlay = tempOverlay {
            mapView?.removeOverlay(overlay)
        }
        
        let polygon = MKPolygon(coordinates: circlePoints, count: circlePoints.count)
        polygon.title = currentServicePackage.rawValue
        tempOverlay = polygon
        mapView?.addOverlay(polygon)
    }
    
    private func handleEraserTap(_ point: CGPoint) {
        guard let mapView = mapView else { return }
        
        for polygon in activePolygons {
            let renderer = MKPolygonRenderer(polygon: polygon)
            let mapPoint = MKMapPoint(mapView.convert(point, toCoordinateFrom: mapView))
            let rendererPoint = renderer.point(for: mapPoint)
            
            if renderer.path?.contains(rendererPoint) ?? false {
                mapView.removeOverlay(polygon)
                if let index = activePolygons.firstIndex(of: polygon) {
                    activePolygons.remove(at: index)
                }
                delegate?.drawingManager(self, didDeletePolygon: polygon)
                break
            }
        }
    }
    
    private func updateTempPolygon() {
        guard drawingPoints.count >= 2 else { return }
        
        if let overlay = tempOverlay {
            mapView?.removeOverlay(overlay)
        }
        
        let polygon = MKPolygon(coordinates: drawingPoints, count: drawingPoints.count)
        polygon.title = currentServicePackage.rawValue
        tempOverlay = polygon
        mapView?.addOverlay(polygon)
    }
    
    private func finishPolygon() {
        guard drawingPoints.count >= 3 else { return }
        
        if let overlay = tempOverlay {
            mapView?.removeOverlay(overlay)
        }
        
        let polygon = MKPolygon(coordinates: drawingPoints, count: drawingPoints.count)
        polygon.title = currentServicePackage.rawValue
        
        mapView?.addOverlay(polygon)
        activePolygons.append(polygon)
        
        delegate?.drawingManager(self, didCreatePolygon: polygon, servicePackage: currentServicePackage)
        
        endDrawing()
    }
    
    private func createRectangle() {
        guard drawingPoints.count == 2 else { return }
        
        let corner1 = drawingPoints[0]
        let corner2 = drawingPoints[1]
        
        let rectanglePoints = [
            corner1,
            CLLocationCoordinate2D(latitude: corner1.latitude, longitude: corner2.longitude),
            corner2,
            CLLocationCoordinate2D(latitude: corner2.latitude, longitude: corner1.longitude)
        ]
        
        let polygon = MKPolygon(coordinates: rectanglePoints, count: rectanglePoints.count)
        polygon.title = currentServicePackage.rawValue
        
        mapView?.addOverlay(polygon)
        activePolygons.append(polygon)
        
        delegate?.drawingManager(self, didCreatePolygon: polygon, servicePackage: currentServicePackage)
    }
    
    private func finishCurrentDrawing() {
        switch currentTool {
        case .freehand:
            if drawingPoints.count >= 3 {
                finishPolygon()
            }
        case .circle:
            if let tempOverlay = tempOverlay as? MKPolygon {
                mapView?.removeOverlay(tempOverlay)
                mapView?.addOverlay(tempOverlay)
                activePolygons.append(tempOverlay)
                delegate?.drawingManager(self, didCreatePolygon: tempOverlay, servicePackage: currentServicePackage)
            }
        default:
            break
        }
        
        endDrawing()
    }
    
    private func isNearFirstPoint(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let firstPoint = drawingPoints.first else { return false }
        let distance = self.distance(from: firstPoint, to: coordinate)
        return distance < 30
    }
    
    private func distance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    private func createCirclePoints(center: CLLocationCoordinate2D, radius: Double, pointCount: Int = 60) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        
        let angleStep = (2 * Double.pi) / Double(pointCount)
        
        for i in 0..<pointCount {
            let angle = Double(i) * angleStep
            let dx = radius * cos(angle)
            let dy = radius * sin(angle)
            
            let lat = center.latitude + (dy / 111111.0)
            let lon = center.longitude + (dx / (111111.0 * cos(center.latitude * .pi / 180)))
            
            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        return points
    }
    
    private func simplifyPath(_ points: [CLLocationCoordinate2D], tolerance: Double = 0.00001) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }
        
        var maxDistance = 0.0
        var maxIndex = 0
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        for i in 1..<(points.count - 1) {
            let distance = perpendicularDistance(point: points[i], lineStart: firstPoint, lineEnd: lastPoint)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        if maxDistance > tolerance {
            let leftPart = simplifyPath(Array(points[0...maxIndex]), tolerance: tolerance)
            let rightPart = simplifyPath(Array(points[maxIndex..<points.count]), tolerance: tolerance)
            
            return leftPart.dropLast() + rightPart
        } else {
            return [firstPoint, lastPoint]
        }
    }
    
    private func perpendicularDistance(point: CLLocationCoordinate2D, lineStart: CLLocationCoordinate2D, lineEnd: CLLocationCoordinate2D) -> Double {
        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        
        if dx == 0 && dy == 0 {
            return distance(from: point, to: lineStart)
        }
        
        let t = ((point.longitude - lineStart.longitude) * dx + (point.latitude - lineStart.latitude) * dy) / (dx * dx + dy * dy)
        
        let closestPoint: CLLocationCoordinate2D
        if t < 0 {
            closestPoint = lineStart
        } else if t > 1 {
            closestPoint = lineEnd
        } else {
            closestPoint = CLLocationCoordinate2D(
                latitude: lineStart.latitude + t * dy,
                longitude: lineStart.longitude + t * dx
            )
        }
        
        return distance(from: point, to: closestPoint)
    }
    
    func calculateArea(for polygon: MKPolygon) -> Double {
        let coordinates = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
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
    
    func getActivePolygons() -> [MKPolygon] {
        return activePolygons
    }
    
    func clearAll() {
        for polygon in activePolygons {
            mapView?.removeOverlay(polygon)
        }
        activePolygons.removeAll()
        resetDrawing()
    }
}

extension DrawingManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}