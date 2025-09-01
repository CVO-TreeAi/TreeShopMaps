import UIKit
import MapKit

class MapDownloadViewController: UIViewController {
    
    // MARK: - Properties
    private let mapView = MKMapView()
    private var selectionOverlay: MKCircle?
    private var downloadRegions: [DownloadRegion] = []
    private let bottomPanel = UIView()
    private let downloadButton = UIButton(type: .system)
    private let sizeLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let radiusSlider = UISlider()
    private let radiusLabel = UILabel()
    private var currentRadius: CLLocationDistance = 5000 // 5km default
    
    private let qualitySegment = UISegmentedControl(items: ["Low", "Standard", "High", "Maximum"])
    
    struct DownloadRegion {
        let center: CLLocationCoordinate2D
        let radius: CLLocationDistance
        let quality: DownloadQuality
    }
    
    enum DownloadQuality: Int {
        case low = 0
        case standard = 1
        case high = 2
        case maximum = 3
        
        var zoomLevels: [Int] {
            switch self {
            case .low: return [13, 14, 15]
            case .standard: return [14, 15, 16, 17]
            case .high: return [15, 16, 17, 18]
            case .maximum: return [15, 16, 17, 18, 19, 20]
            }
        }
        
        var description: String {
            switch self {
            case .low: return "Basic navigation"
            case .standard: return "Property viewing"
            case .high: return "Detailed work"
            case .maximum: return "Maximum detail"
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        loadSavedRegions()
    }
    
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        title = "Download Maps"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear Cache",
            style: .plain,
            target: self,
            action: #selector(clearCache)
        )
        
        // Map View
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.mapType = .hybrid
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        
        // Bottom Panel
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.backgroundColor = TreeShopTheme.cardBackground
        bottomPanel.layer.cornerRadius = TreeShopTheme.cornerRadius
        bottomPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(bottomPanel)
        
        // Quality Segment
        qualitySegment.translatesAutoresizingMaskIntoConstraints = false
        qualitySegment.selectedSegmentIndex = 1 // Standard by default
        qualitySegment.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        bottomPanel.addSubview(qualitySegment)
        
        // Radius Slider
        radiusSlider.translatesAutoresizingMaskIntoConstraints = false
        radiusSlider.minimumValue = 1000 // 1km
        radiusSlider.maximumValue = 50000 // 50km
        radiusSlider.value = 5000 // 5km default
        radiusSlider.addTarget(self, action: #selector(radiusChanged), for: .valueChanged)
        radiusSlider.tintColor = TreeShopTheme.primaryGreen
        bottomPanel.addSubview(radiusSlider)
        
        // Radius Label
        radiusLabel.translatesAutoresizingMaskIntoConstraints = false
        radiusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        radiusLabel.textColor = TreeShopTheme.primaryText
        radiusLabel.text = "Radius: 5.0 km"
        bottomPanel.addSubview(radiusLabel)
        
        // Size Label
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        sizeLabel.textColor = TreeShopTheme.secondaryText
        sizeLabel.text = "Estimated size: Calculating..."
        bottomPanel.addSubview(sizeLabel)
        
        // Progress View
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = TreeShopTheme.primaryGreen
        progressView.trackTintColor = TreeShopTheme.buttonBackground
        progressView.isHidden = true
        bottomPanel.addSubview(progressView)
        
        // Download Button
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.setTitle("Download Selected Area", for: .normal)
        downloadButton.backgroundColor = TreeShopTheme.primaryGreen
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        downloadButton.addTarget(self, action: #selector(downloadArea), for: .touchUpInside)
        bottomPanel.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            // Map View
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor),
            
            // Bottom Panel
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPanel.heightAnchor.constraint(equalToConstant: 280),
            
            // Quality Segment
            qualitySegment.topAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: 20),
            qualitySegment.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            qualitySegment.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            
            // Radius Label
            radiusLabel.topAnchor.constraint(equalTo: qualitySegment.bottomAnchor, constant: 20),
            radiusLabel.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            
            // Radius Slider
            radiusSlider.topAnchor.constraint(equalTo: radiusLabel.bottomAnchor, constant: 8),
            radiusSlider.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            radiusSlider.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            
            // Size Label
            sizeLabel.topAnchor.constraint(equalTo: radiusSlider.bottomAnchor, constant: 16),
            sizeLabel.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            
            // Download Button
            downloadButton.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            downloadButton.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            downloadButton.bottomAnchor.constraint(equalTo: bottomPanel.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            downloadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupMapView() {
        // Add tap gesture to select download center
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Center on user location or default location
        let defaultCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // SF as default
        let region = MKCoordinateRegion(
            center: defaultCenter,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(region, animated: false)
        updateSelectionOverlay(at: defaultCenter)
    }
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        updateSelectionOverlay(at: coordinate)
        estimateDownloadSize()
    }
    
    private func updateSelectionOverlay(at coordinate: CLLocationCoordinate2D) {
        // Remove existing overlay
        if let overlay = selectionOverlay {
            mapView.removeOverlay(overlay)
        }
        
        // Add new overlay
        selectionOverlay = MKCircle(center: coordinate, radius: currentRadius)
        mapView.addOverlay(selectionOverlay!)
    }
    
    @objc private func radiusChanged() {
        currentRadius = CLLocationDistance(radiusSlider.value)
        radiusLabel.text = String(format: "Radius: %.1f km", currentRadius / 1000)
        
        if let center = selectionOverlay?.coordinate {
            updateSelectionOverlay(at: center)
        }
        
        estimateDownloadSize()
    }
    
    @objc private func qualityChanged() {
        estimateDownloadSize()
    }
    
    private func estimateDownloadSize() {
        guard selectionOverlay != nil else {
            sizeLabel.text = "Tap map to select area"
            return
        }
        
        let quality = DownloadQuality(rawValue: qualitySegment.selectedSegmentIndex) ?? .standard
        let tileCount = estimateTileCount(radius: currentRadius, quality: quality)
        let estimatedSize = tileCount * 50 * 1024 // Assume 50KB per tile average
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        
        sizeLabel.text = "Estimated size: \(formatter.string(fromByteCount: Int64(estimatedSize))) (\(tileCount) tiles)"
    }
    
    private func estimateTileCount(radius: CLLocationDistance, quality: DownloadQuality) -> Int {
        var totalTiles = 0
        
        for zoomLevel in quality.zoomLevels {
            let tilesPerSide = Int(ceil(radius * 2 / metersPerTileAtZoom(zoomLevel)))
            totalTiles += tilesPerSide * tilesPerSide
        }
        
        return totalTiles
    }
    
    private func metersPerTileAtZoom(_ zoom: Int) -> Double {
        return 40075016.686 / pow(2.0, Double(zoom)) // Earth circumference / 2^zoom
    }
    
    @objc private func downloadArea() {
        guard let overlay = selectionOverlay else {
            showAlert(title: "No Area Selected", message: "Please tap on the map to select an area to download.")
            return
        }
        
        let quality = DownloadQuality(rawValue: qualitySegment.selectedSegmentIndex) ?? .standard
        
        // Show progress
        progressView.isHidden = false
        progressView.progress = 0
        downloadButton.isEnabled = false
        downloadButton.alpha = 0.5
        
        // Create enhanced cache manager with better performance
        let enhancedCache = EnhancedMapCache()
        
        enhancedCache.downloadRegion(
            center: overlay.coordinate,
            radius: currentRadius,
            quality: quality
        ) { [weak self] progress, completed, error in
            DispatchQueue.main.async {
                self?.progressView.progress = Float(progress)
                
                if completed {
                    self?.progressView.isHidden = true
                    self?.downloadButton.isEnabled = true
                    self?.downloadButton.alpha = 1.0
                    
                    if let error = error {
                        self?.showAlert(title: "Download Failed", message: error.localizedDescription)
                    } else {
                        self?.saveDownloadRegion(center: overlay.coordinate, radius: self?.currentRadius ?? 5000, quality: quality)
                        self?.showAlert(title: "Download Complete", message: "Maps have been cached for offline use.")
                    }
                }
            }
        }
    }
    
    private func saveDownloadRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance, quality: DownloadQuality) {
        let region = DownloadRegion(center: center, radius: radius, quality: quality)
        downloadRegions.append(region)
        
        // Save to UserDefaults for persistence
        var savedRegions = UserDefaults.standard.array(forKey: "DownloadedRegions") as? [[String: Any]] ?? []
        savedRegions.append([
            "latitude": center.latitude,
            "longitude": center.longitude,
            "radius": radius,
            "quality": quality.rawValue
        ])
        UserDefaults.standard.set(savedRegions, forKey: "DownloadedRegions")
    }
    
    private func loadSavedRegions() {
        guard let savedRegions = UserDefaults.standard.array(forKey: "DownloadedRegions") as? [[String: Any]] else { return }
        
        for regionData in savedRegions {
            if let latitude = regionData["latitude"] as? Double,
               let longitude = regionData["longitude"] as? Double,
               let radius = regionData["radius"] as? CLLocationDistance,
               let qualityRaw = regionData["quality"] as? Int,
               let quality = DownloadQuality(rawValue: qualityRaw) {
                
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let region = DownloadRegion(center: center, radius: radius, quality: quality)
                downloadRegions.append(region)
                
                // Add overlay to show downloaded regions
                let circle = MKCircle(center: center, radius: radius)
                mapView.addOverlay(circle)
            }
        }
    }
    
    @objc private func clearCache() {
        let alert = UIAlertController(
            title: "Clear Cache",
            message: "This will delete all downloaded map tiles. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            MapCacheManager.shared.clearCache()
            UserDefaults.standard.removeObject(forKey: "DownloadedRegions")
            self.downloadRegions.removeAll()
            self.mapView.removeOverlays(self.mapView.overlays)
            self.showAlert(title: "Cache Cleared", message: "All map tiles have been deleted.")
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MKMapViewDelegate
extension MapDownloadViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            
            if circle == selectionOverlay {
                // Selection overlay - active selection
                renderer.fillColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.2)
                renderer.strokeColor = TreeShopTheme.primaryGreen
                renderer.lineWidth = 2
            } else {
                // Previously downloaded region
                renderer.fillColor = TreeShopTheme.successGreen.withAlphaComponent(0.1)
                renderer.strokeColor = TreeShopTheme.successGreen.withAlphaComponent(0.5)
                renderer.lineWidth = 1
                renderer.lineDashPattern = [5, 5]
            }
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}

// MARK: - Enhanced Map Cache
class EnhancedMapCache {
    private let session = URLSession(configuration: .default)
    private let cacheDirectory: URL
    private let downloadQueue = OperationQueue()
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("MapCache")
        
        // Configure download queue for optimal performance
        downloadQueue.maxConcurrentOperationCount = 6 // Parallel downloads
        downloadQueue.qualityOfService = .userInitiated
        
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func downloadRegion(center: CLLocationCoordinate2D, 
                       radius: CLLocationDistance,
                       quality: MapDownloadViewController.DownloadQuality,
                       completion: @escaping (Double, Bool, Error?) -> Void) {
        
        let tiles = calculateTiles(center: center, radius: radius, zoomLevels: quality.zoomLevels)
        var downloadedCount = 0
        let totalCount = tiles.count
        
        for tile in tiles {
            let operation = TileDownloadOperation(
                tile: tile,
                cacheDirectory: cacheDirectory,
                session: session
            ) { success in
                downloadedCount += 1
                let progress = Double(downloadedCount) / Double(totalCount)
                
                if downloadedCount == totalCount {
                    completion(1.0, true, nil)
                } else {
                    completion(progress, false, nil)
                }
            }
            
            downloadQueue.addOperation(operation)
        }
    }
    
    private func calculateTiles(center: CLLocationCoordinate2D, 
                               radius: CLLocationDistance,
                               zoomLevels: [Int]) -> [(x: Int, y: Int, z: Int)] {
        var tiles: [(x: Int, y: Int, z: Int)] = []
        
        for zoom in zoomLevels {
            let region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            
            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLon = region.center.longitude - region.span.longitudeDelta / 2
            let maxLon = region.center.longitude + region.span.longitudeDelta / 2
            
            let minTile = tileForCoordinate(lat: maxLat, lon: minLon, zoom: zoom)
            let maxTile = tileForCoordinate(lat: minLat, lon: maxLon, zoom: zoom)
            
            for x in minTile.x...maxTile.x {
                for y in minTile.y...maxTile.y {
                    tiles.append((x: x, y: y, z: zoom))
                }
            }
        }
        
        return tiles
    }
    
    private func tileForCoordinate(lat: Double, lon: Double, zoom: Int) -> (x: Int, y: Int) {
        let n = pow(2.0, Double(zoom))
        let x = Int((lon + 180.0) / 360.0 * n)
        let latRad = lat * .pi / 180.0
        let y = Int((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n)
        return (x: x, y: y)
    }
}

// MARK: - Tile Download Operation
class TileDownloadOperation: Operation, @unchecked Sendable {
    let tile: (x: Int, y: Int, z: Int)
    let cacheDirectory: URL
    let session: URLSession
    let completion: (Bool) -> Void
    
    init(tile: (x: Int, y: Int, z: Int), 
         cacheDirectory: URL,
         session: URLSession,
         completion: @escaping (Bool) -> Void) {
        self.tile = tile
        self.cacheDirectory = cacheDirectory
        self.session = session
        self.completion = completion
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        let tileKey = "\(tile.z)_\(tile.x)_\(tile.y).png"
        let tilePath = cacheDirectory.appendingPathComponent(tileKey)
        
        // Check if already cached
        if FileManager.default.fileExists(atPath: tilePath.path) {
            completion(true)
            return
        }
        
        // Download tile
        let urlString = "https://tile.openstreetmap.org/\(tile.z)/\(tile.x)/\(tile.y).png"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            defer { semaphore.signal() }
            
            guard let data = data, error == nil else {
                self?.completion(false)
                return
            }
            
            do {
                try data.write(to: tilePath)
                self?.completion(true)
            } catch {
                self?.completion(false)
            }
        }
        
        task.resume()
        semaphore.wait()
    }
}