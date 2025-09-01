import Foundation
import MapKit
import CoreData

// MARK: - Measurement Types
enum MeasurementType: String, CaseIterable {
    case distance = "Distance"
    case area = "Area"
    
    var systemImageName: String {
        switch self {
        case .distance: return "ruler"
        case .area: return "square.dashed"
        }
    }
}

// MARK: - Measurement Units
enum DistanceUnit: String, CaseIterable {
    case feet = "feet"
    case meters = "meters"
    case yards = "yards"
    
    var abbreviation: String {
        switch self {
        case .feet: return "ft"
        case .meters: return "m"
        case .yards: return "yd"
        }
    }
    
    func convert(from feet: Double) -> Double {
        switch self {
        case .feet: return feet
        case .meters: return feet * 0.3048
        case .yards: return feet / 3.0
        }
    }
    
    func convertToFeet(from value: Double) -> Double {
        switch self {
        case .feet: return value
        case .meters: return value / 0.3048
        case .yards: return value * 3.0
        }
    }
}

enum AreaUnit: String, CaseIterable {
    case acres = "acres"
    case hectares = "hectares"
    case squareFeet = "square feet"
    case squareMeters = "square meters"
    
    var abbreviation: String {
        switch self {
        case .acres: return "ac"
        case .hectares: return "ha"
        case .squareFeet: return "sq ft"
        case .squareMeters: return "sq m"
        }
    }
    
    func convert(from acres: Double) -> Double {
        switch self {
        case .acres: return acres
        case .hectares: return acres * 0.404686
        case .squareFeet: return acres * 43560
        case .squareMeters: return acres * 4046.86
        }
    }
    
    func convertToAcres(from value: Double) -> Double {
        switch self {
        case .acres: return value
        case .hectares: return value / 0.404686
        case .squareFeet: return value / 43560
        case .squareMeters: return value / 4046.86
        }
    }
}

// MARK: - Stored Measurement Model
class StoredMeasurement: NSObject, NSCoding {
    let id: UUID
    let name: String
    let type: MeasurementType
    let coordinates: [CLLocationCoordinate2D]
    let value: Double // Base unit: feet for distance, acres for area
    let perimeter: Double? // Only for area measurements
    let dateCreated: Date
    let notes: String?
    let accuracy: CLLocationAccuracy?
    
    init(id: UUID = UUID(),
         name: String,
         type: MeasurementType,
         coordinates: [CLLocationCoordinate2D],
         value: Double,
         perimeter: Double? = nil,
         notes: String? = nil,
         accuracy: CLLocationAccuracy? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.coordinates = coordinates
        self.value = value
        self.perimeter = perimeter
        self.dateCreated = Date()
        self.notes = notes
        self.accuracy = accuracy
        super.init()
    }
    
    // MARK: - NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(id.uuidString, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(value, forKey: "value")
        coder.encode(perimeter, forKey: "perimeter")
        coder.encode(dateCreated, forKey: "dateCreated")
        coder.encode(notes, forKey: "notes")
        coder.encode(accuracy, forKey: "accuracy")
        
        // Encode coordinates
        let coordData = coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] }
        coder.encode(coordData, forKey: "coordinates")
    }
    
    required init?(coder: NSCoder) {
        guard let idString = coder.decodeObject(forKey: "id") as? String,
              let id = UUID(uuidString: idString),
              let name = coder.decodeObject(forKey: "name") as? String,
              let typeString = coder.decodeObject(forKey: "type") as? String,
              let type = MeasurementType(rawValue: typeString),
              let dateCreated = coder.decodeObject(forKey: "dateCreated") as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.type = type
        self.value = coder.decodeDouble(forKey: "value")
        self.perimeter = coder.decodeObject(forKey: "perimeter") as? Double
        self.dateCreated = dateCreated
        self.notes = coder.decodeObject(forKey: "notes") as? String
        self.accuracy = coder.decodeObject(forKey: "accuracy") as? CLLocationAccuracy
        
        // Decode coordinates
        if let coordData = coder.decodeObject(forKey: "coordinates") as? [[String: Double]] {
            self.coordinates = coordData.compactMap { dict in
                guard let lat = dict["lat"], let lon = dict["lon"] else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        } else {
            self.coordinates = []
        }
        
        super.init()
    }
    
    // MARK: - Convenience Methods
    func getFormattedValue(distanceUnit: DistanceUnit = .feet, areaUnit: AreaUnit = .acres) -> String {
        switch type {
        case .distance:
            let convertedValue = distanceUnit.convert(from: value)
            return String(format: "%.1f %@", convertedValue, distanceUnit.abbreviation)
        case .area:
            let convertedValue = areaUnit.convert(from: value)
            return String(format: "%.2f %@", convertedValue, areaUnit.abbreviation)
        }
    }
    
    func getFormattedPerimeter(distanceUnit: DistanceUnit = .feet) -> String? {
        guard let perimeter = perimeter else { return nil }
        let convertedValue = distanceUnit.convert(from: perimeter)
        return String(format: "%.1f %@ perimeter", convertedValue, distanceUnit.abbreviation)
    }
    
    func createMapOverlay() -> MKOverlay {
        switch type {
        case .distance:
            return MKPolyline(coordinates: coordinates, count: coordinates.count)
        case .area:
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        }
    }
    
    func createAnnotations() -> [MKPointAnnotation] {
        return coordinates.enumerated().map { index, coordinate in
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(name) - Point \(index + 1)"
            return annotation
        }
    }
}

// MARK: - User Settings for Units
class MeasurementSettings {
    static let shared = MeasurementSettings()
    
    private let userDefaults = UserDefaults.standard
    private let distanceUnitKey = "MeasurementDistanceUnit"
    private let areaUnitKey = "MeasurementAreaUnit"
    private let showAccuracyKey = "MeasurementShowAccuracy"
    private let showCoordinatesKey = "MeasurementShowCoordinates"
    
    var distanceUnit: DistanceUnit {
        get {
            let rawValue = userDefaults.string(forKey: distanceUnitKey) ?? DistanceUnit.feet.rawValue
            return DistanceUnit(rawValue: rawValue) ?? .feet
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: distanceUnitKey)
        }
    }
    
    var areaUnit: AreaUnit {
        get {
            let rawValue = userDefaults.string(forKey: areaUnitKey) ?? AreaUnit.acres.rawValue
            return AreaUnit(rawValue: rawValue) ?? .acres
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: areaUnitKey)
        }
    }
    
    var showAccuracy: Bool {
        get {
            return userDefaults.bool(forKey: showAccuracyKey)
        }
        set {
            userDefaults.set(newValue, forKey: showAccuracyKey)
        }
    }
    
    var showCoordinates: Bool {
        get {
            return userDefaults.bool(forKey: showCoordinatesKey)
        }
        set {
            userDefaults.set(newValue, forKey: showCoordinatesKey)
        }
    }
}

// MARK: - Measurement History Manager
class MeasurementHistoryManager {
    static let shared = MeasurementHistoryManager()
    
    private let userDefaults = UserDefaults.standard
    private let measurementsKey = "StoredMeasurements"
    
    private var measurements: [StoredMeasurement] = []
    
    init() {
        loadMeasurements()
    }
    
    func saveMeasurement(_ measurement: StoredMeasurement) {
        measurements.append(measurement)
        saveMeasurements()
    }
    
    func getMeasurements() -> [StoredMeasurement] {
        return measurements.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    func getMeasurement(by id: UUID) -> StoredMeasurement? {
        return measurements.first { $0.id == id }
    }
    
    func deleteMeasurement(by id: UUID) {
        measurements.removeAll { $0.id == id }
        saveMeasurements()
    }
    
    func updateMeasurement(_ measurement: StoredMeasurement) {
        if let index = measurements.firstIndex(where: { $0.id == measurement.id }) {
            measurements[index] = measurement
            saveMeasurements()
        }
    }
    
    private func saveMeasurements() {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: measurements, requiringSecureCoding: false)
        userDefaults.set(data, forKey: measurementsKey)
    }
    
    private func loadMeasurements() {
        guard let data = userDefaults.data(forKey: measurementsKey),
              let loadedMeasurements = try? NSKeyedUnarchiver.unarchiveObject(with: data) as? [StoredMeasurement] else {
            measurements = []
            return
        }
        measurements = loadedMeasurements
    }
    
    // Export functionality
    func exportMeasurementsToCSV() -> URL? {
        let csvHeader = "Name,Type,Value,Perimeter,Date Created,Notes,Coordinates\n"
        var csvContent = csvHeader
        
        for measurement in measurements {
            let coordString = measurement.coordinates.map { "\(\($0.latitude)),\(\($0.longitude))" }.joined(separator: ";")
            let perimeterStr = measurement.perimeter.map { String(format: "%.2f", $0) } ?? ""
            let notesStr = measurement.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            let line = "\"\(measurement.name)\",\(measurement.type.rawValue),\(String(format: "%.3f", measurement.value)),\(perimeterStr),\(measurement.dateCreated),\"\(notesStr)\",\"\(coordString)\"\n"
            csvContent += line
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Measurements_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error exporting CSV: \(error)")
            return nil
        }
    }
}