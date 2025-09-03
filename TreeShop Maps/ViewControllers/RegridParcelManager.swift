import Foundation
import MapKit
import CoreLocation

// MARK: - Regrid API Models
struct RegridParcel: Codable {
    let llUuid: String
    let headline: String?
    let ownership: ParcelOwnership?
    let geometry: ParcelGeometry
    let properties: ParcelProperties?
    
    enum CodingKeys: String, CodingKey {
        case llUuid = "ll_uuid"
        case headline, ownership, geometry, properties
    }
}

struct ParcelOwnership: Codable {
    let ownerName: String?
    let ownerAddress: String?
    let mailingAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case ownerName = "owner_name"
        case ownerAddress = "owner_address"
        case mailingAddress = "mailing_address"
    }
}

struct ParcelGeometry: Codable {
    let type: String
    let coordinates: [[[[Double]]]]
}

struct ParcelProperties: Codable {
    let apn: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let acreage: Double?
    let landUse: String?
    
    enum CodingKeys: String, CodingKey {
        case apn, address, city, state
        case zipCode = "zip_code"
        case acreage
        case landUse = "land_use"
    }
}

struct RegridResponse: Codable {
    let type: String
    let features: [RegridFeature]
}

struct RegridFeature: Codable {
    let type: String
    let geometry: ParcelGeometry
    let properties: RegridFeatureProperties
}

struct RegridFeatureProperties: Codable {
    let llUuid: String
    let headline: String?
    let ownerName: String?
    let ownerAddress: String?
    let apn: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let acreage: Double?
    let landUse: String?
    
    enum CodingKeys: String, CodingKey {
        case llUuid = "ll_uuid"
        case headline
        case ownerName = "owner_name"
        case ownerAddress = "owner_address"
        case apn, address, city, state
        case zipCode = "zip_code"
        case acreage
        case landUse = "land_use"
    }
}

// MARK: - API Errors
enum RegridAPIError: Error, LocalizedError {
    case invalidURL
    case noAPIToken
    case invalidResponse
    case noData
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAPIToken:
            return "TreeShop backend authentication failed"
        case .invalidResponse:
            return "Invalid response from Regrid API"
        case .noData:
            return "No parcel data found"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Regrid Parcel Manager
class RegridParcelManager {
    static let shared = RegridParcelManager()
    
    // TreeShop backend proxy - keeps Regrid token secure on server
    private let baseURL = "http://localhost:3003/v1/parcels"
    private let session = URLSession.shared
    private var appToken: String? // TreeShop app authentication token
    
    private init() {
        loadAppToken()
    }
    
    private func loadAppToken() {
        // Load TreeShop app authentication token (not Regrid token)
        // In production, this would be generated during app authentication
        appToken = "treeshop_app_\(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")"
    }
    
    // MARK: - Public API Methods
    
    /// Search parcels by coordinate point via TreeShop backend
    func searchParcels(at coordinate: CLLocationCoordinate2D, 
                      radius: Double = 100,
                      completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        
        guard let token = appToken else {
            completion(.failure(.noAPIToken))
            return
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "app_token", value: token),
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    /// Search parcel by Assessor Parcel Number (APN)
    func searchParcel(byAPN apn: String,
                     completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        
        guard let token = appToken else {
            completion(.failure(.noAPIToken))
            return
        }
        
        var components = URLComponents(string: "\(baseURL)/apn")!
        components.queryItems = [
            URLQueryItem(name: "app_token", value: token),
            URLQueryItem(name: "apn", value: apn),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    /// Search parcel by street address
    func searchParcel(byAddress address: String,
                     completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        
        guard let token = appToken else {
            completion(.failure(.noAPIToken))
            return
        }
        
        var components = URLComponents(string: "\(baseURL)/address")!
        components.queryItems = [
            URLQueryItem(name: "app_token", value: token),
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "limit", value: "5")
        ]
        
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    /// Search parcels within a polygon area
    func searchParcels(withinPolygon polygon: MKPolygon,
                      completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        
        guard let token = appToken else {
            completion(.failure(.noAPIToken))
            return
        }
        
        // Convert MKPolygon to GeoJSON
        let geoJSON = convertPolygonToGeoJSON(polygon)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/parcels")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderValue: "Content-Type")
        
        let requestBody: [String: Any] = [
            "token": token,
            "geojson": geoJSON,
            "limit": 50
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }
        
        performRequest(request: request, completion: completion)
    }
    
    /// Get specific parcel by Regrid UUID
    func getParcel(byUUID uuid: String,
                  completion: @escaping (Result<RegridParcel, RegridAPIError>) -> Void) {
        
        guard let token = appToken else {
            completion(.failure(.noAPIToken))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/parcels/\(uuid)?token=\(token)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            do {
                let parcel = try JSONDecoder().decode(RegridParcel.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(parcel))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // MARK: - Private Helper Methods
    
    private func performRequest(url: URL, completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderValue: "Accept")
        performRequest(request: request, completion: completion)
    }
    
    private func performRequest(request: URLRequest, completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Debug: Print raw response for troubleshooting
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Regrid API Response: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(RegridResponse.self, from: data)
                let parcels = response.features.map { feature in
                    return RegridParcel(
                        llUuid: feature.properties.llUuid,
                        headline: feature.properties.headline,
                        ownership: ParcelOwnership(
                            ownerName: feature.properties.ownerName,
                            ownerAddress: feature.properties.ownerAddress,
                            mailingAddress: nil
                        ),
                        geometry: feature.geometry,
                        properties: ParcelProperties(
                            apn: feature.properties.apn,
                            address: feature.properties.address,
                            city: feature.properties.city,
                            state: feature.properties.state,
                            zipCode: feature.properties.zipCode,
                            acreage: feature.properties.acreage,
                            landUse: feature.properties.landUse
                        )
                    )
                }
                
                DispatchQueue.main.async {
                    completion(.success(parcels))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    private func convertPolygonToGeoJSON(_ polygon: MKPolygon) -> [String: Any] {
        let coordinates = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        let coordinateArray = coordinates.map { [$0.coordinate.longitude, $0.coordinate.latitude] }
        
        return [
            "type": "Polygon",
            "coordinates": [coordinateArray]
        ]
    }
}

// MARK: - MapKit Extensions for Parcel Display
extension RegridParcel {
    
    /// Convert Regrid parcel to MKPolygon for map display
    func createMapPolygon() -> MKPolygon? {
        guard geometry.type == "Polygon" || geometry.type == "MultiPolygon" else {
            return nil
        }
        
        // Handle Polygon type
        if geometry.type == "Polygon", let firstRing = geometry.coordinates.first?.first {
            let coordinates = firstRing.compactMap { coord in
                guard coord.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
            }
            
            if coordinates.count >= 3 {
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                polygon.title = headline ?? "Parcel \(llUuid)"
                polygon.subtitle = ownership?.ownerName ?? "Unknown Owner"
                return polygon
            }
        }
        
        // Handle MultiPolygon type - use first polygon
        if geometry.type == "MultiPolygon", 
           let firstPolygon = geometry.coordinates.first,
           let firstRing = firstPolygon.first {
            let coordinates = firstRing.compactMap { coord in
                guard coord.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
            }
            
            if coordinates.count >= 3 {
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                polygon.title = headline ?? "Parcel \(llUuid)"
                polygon.subtitle = ownership?.ownerName ?? "Unknown Owner"
                return polygon
            }
        }
        
        return nil
    }
    
    /// Get formatted display information
    func getDisplayInfo() -> String {
        var info = [String]()
        
        if let headline = headline {
            info.append("📍 \(headline)")
        }
        
        if let ownerName = ownership?.ownerName {
            info.append("👤 Owner: \(ownerName)")
        }
        
        if let address = properties?.address {
            info.append("🏠 \(address)")
        }
        
        if let city = properties?.city, let state = properties?.state {
            info.append("📍 \(city), \(state)")
        }
        
        if let acreage = properties?.acreage {
            info.append("📐 \(String(format: "%.2f", acreage)) acres")
        }
        
        if let apn = properties?.apn {
            info.append("🆔 APN: \(apn)")
        }
        
        if let landUse = properties?.landUse {
            info.append("🏗️ Land Use: \(landUse)")
        }
        
        return info.joined(separator: "\n")
    }
    
    /// Get owner contact information
    func getOwnerInfo() -> String {
        var ownerInfo = [String]()
        
        if let ownerName = ownership?.ownerName {
            ownerInfo.append("Owner: \(ownerName)")
        }
        
        if let ownerAddress = ownership?.ownerAddress {
            ownerInfo.append("Address: \(ownerAddress)")
        }
        
        if let mailingAddress = ownership?.mailingAddress {
            ownerInfo.append("Mailing: \(mailingAddress)")
        }
        
        return ownerInfo.isEmpty ? "Owner information not available" : ownerInfo.joined(separator: "\n")
    }
}

// MARK: - Parcel Annotation for Map Display
class ParcelAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let parcel: RegridParcel
    
    init(parcel: RegridParcel, coordinate: CLLocationCoordinate2D) {
        self.parcel = parcel
        self.coordinate = coordinate
        self.title = parcel.headline ?? "Parcel"
        self.subtitle = parcel.ownership?.ownerName ?? "Unknown Owner"
        super.init()
    }
}

// MARK: - TreeShop Maps Integration
extension RegridParcelManager {
    
    /// Quick parcel lookup for contractors - finds parcel at tapped location
    func getParcelInfo(at coordinate: CLLocationCoordinate2D,
                      completion: @escaping (String) -> Void) {
        
        searchParcels(at: coordinate) { result in
            switch result {
            case .success(let parcels):
                if let parcel = parcels.first {
                    completion(parcel.getDisplayInfo())
                } else {
                    completion("No parcel information found at this location")
                }
            case .failure(let error):
                completion("Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get property owner for contractor permissioning
    func getPropertyOwner(at coordinate: CLLocationCoordinate2D,
                         completion: @escaping (String) -> Void) {
        
        searchParcels(at: coordinate) { result in
            switch result {
            case .success(let parcels):
                if let parcel = parcels.first {
                    completion(parcel.getOwnerInfo())
                } else {
                    completion("Property owner information not available")
                }
            case .failure(let error):
                completion("Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Find all parcels within contractor's work area
    func getParcelsInWorkArea(_ polygon: MKPolygon,
                             completion: @escaping (Result<[RegridParcel], RegridAPIError>) -> Void) {
        
        searchParcels(withinPolygon: polygon, completion: completion)
    }
    
    /// Verify if contractor is on correct property
    func verifyLocation(at coordinate: CLLocationCoordinate2D,
                       expectedAddress: String,
                       completion: @escaping (Bool, String) -> Void) {
        
        searchParcels(at: coordinate) { result in
            switch result {
            case .success(let parcels):
                if let parcel = parcels.first {
                    let parcelAddress = parcel.properties?.address ?? parcel.headline ?? ""
                    let isMatch = parcelAddress.lowercased().contains(expectedAddress.lowercased()) ||
                                 expectedAddress.lowercased().contains(parcelAddress.lowercased())
                    
                    let message = isMatch ? 
                        "✅ Correct property: \(parcelAddress)" : 
                        "⚠️ Different property: \(parcelAddress)\nExpected: \(expectedAddress)"
                    
                    completion(isMatch, message)
                } else {
                    completion(false, "Unable to verify property at this location")
                }
            case .failure(let error):
                completion(false, "Verification error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - API Configuration Helper
extension RegridParcelManager {
    
    /// Check if API is properly configured
    var isConfigured: Bool {
        return appToken != nil && !appToken!.isEmpty
    }
    
    /// Get configuration status for UI display
    func getConfigurationStatus() -> String {
        if isConfigured {
            return "✅ Regrid API configured"
        } else {
            return "⚠️ Regrid API token required for parcel lookup"
        }
    }
    
    /// Setup wizard for API configuration
    func showAPISetupAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Configure Regrid API",
            message: "Enter your Regrid API token to enable parcel lookup and property owner identification:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Enter Regrid API token"
            textField.text = self.appToken
            textField.isSecureTextEntry = false
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let token = alert.textFields?.first?.text, !token.isEmpty {
                self.appToken = token
                
                // Test the token
                self.searchParcels(at: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)) { result in
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            let successAlert = UIAlertController(title: "Success", message: "Regrid API configured successfully!", preferredStyle: .alert)
                            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            viewController.present(successAlert, animated: true)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            let errorAlert = UIAlertController(title: "API Error", message: error.localizedDescription, preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            viewController.present(errorAlert, animated: true)
                        }
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)
    }
}