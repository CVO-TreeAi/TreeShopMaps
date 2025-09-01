import Foundation
import MapKit

class MapCacheManager: NSObject {
    static let shared = MapCacheManager()
    
    private let cacheDirectory: URL
    private let tileLevels = [15, 16, 17, 18, 19]
    private let maxCacheSize: Int64 = 500 * 1024 * 1024
    private var currentCacheSize: Int64 = 0
    
    private let downloadQueue = DispatchQueue(label: "com.treeshop.maps.download", attributes: .concurrent)
    private let cacheQueue = DispatchQueue(label: "com.treeshop.maps.cache", attributes: .concurrent)
    
    override init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("MapCache")
        
        super.init()
        
        createCacheDirectoryIfNeeded()
        calculateCacheSize()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create cache directory: \(error)")
            }
        }
    }
    
    private func calculateCacheSize() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
                
                self.currentCacheSize = files.reduce(0) { total, file in
                    let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    return total + Int64(size)
                }
            } catch {
                print("Failed to calculate cache size: \(error)")
            }
        }
    }
    
    func cacheRegion(center: CLLocationCoordinate2D, radius: Double, completion: @escaping (Bool, Double) -> Void) {
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            let region = MKCoordinateRegion(center: center, latitudinalMeters: radius * 2, longitudinalMeters: radius * 2)
            var totalTiles = 0
            var downloadedTiles = 0
            
            for zoomLevel in self.tileLevels {
                let tiles = self.tilesForRegion(region, zoomLevel: zoomLevel)
                totalTiles += tiles.count
                
                for tile in tiles {
                    if self.downloadTile(x: tile.x, y: tile.y, z: zoomLevel) {
                        downloadedTiles += 1
                    }
                    
                    let progress = Double(downloadedTiles) / Double(totalTiles)
                    DispatchQueue.main.async {
                        completion(false, progress)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(true, 1.0)
            }
        }
    }
    
    private func tilesForRegion(_ region: MKCoordinateRegion, zoomLevel: Int) -> [(x: Int, y: Int)] {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        
        let minTile = tileForCoordinate(lat: maxLat, lon: minLon, zoom: zoomLevel)
        let maxTile = tileForCoordinate(lat: minLat, lon: maxLon, zoom: zoomLevel)
        
        var tiles: [(x: Int, y: Int)] = []
        
        for x in minTile.x...maxTile.x {
            for y in minTile.y...maxTile.y {
                tiles.append((x: x, y: y))
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
    
    private func downloadTile(x: Int, y: Int, z: Int) -> Bool {
        let tileKey = "\(z)_\(x)_\(y).png"
        let tilePath = cacheDirectory.appendingPathComponent(tileKey)
        
        if FileManager.default.fileExists(atPath: tilePath.path) {
            return true
        }
        
        let urlString = "https://tile.openstreetmap.org/\(z)/\(x)/\(y).png"
        guard let url = URL(string: urlString) else { return false }
        
        do {
            let data = try Data(contentsOf: url)
            try data.write(to: tilePath)
            
            currentCacheSize += Int64(data.count)
            
            if currentCacheSize > maxCacheSize {
                cleanupOldTiles()
            }
            
            return true
        } catch {
            print("Failed to download tile: \(error)")
            return false
        }
    }
    
    func loadCachedTiles(region: MKCoordinateRegion) -> [MKTileOverlay] {
        var overlays: [MKTileOverlay] = []
        
        for zoomLevel in tileLevels {
            let overlay = CachedTileOverlay(cacheDirectory: cacheDirectory, zoomLevel: zoomLevel)
            overlay.canReplaceMapContent = false
            overlays.append(overlay)
        }
        
        return overlays
    }
    
    private func cleanupOldTiles() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
                
                let sortedFiles = files.sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    return date1 < date2
                }
                
                var currentSize = self.currentCacheSize
                let targetSize = self.maxCacheSize * 8 / 10
                
                for file in sortedFiles {
                    if currentSize <= targetSize {
                        break
                    }
                    
                    let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    try FileManager.default.removeItem(at: file)
                    currentSize -= Int64(fileSize)
                }
                
                self.currentCacheSize = currentSize
            } catch {
                print("Failed to cleanup cache: \(error)")
            }
        }
    }
    
    func clearCache() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    try FileManager.default.removeItem(at: file)
                }
                self.currentCacheSize = 0
            } catch {
                print("Failed to clear cache: \(error)")
            }
        }
    }
    
    func getCacheSize() -> Int64 {
        return currentCacheSize
    }
}

class CachedTileOverlay: MKTileOverlay {
    private let cacheDirectory: URL
    private let zoomLevel: Int
    
    init(cacheDirectory: URL, zoomLevel: Int) {
        self.cacheDirectory = cacheDirectory
        self.zoomLevel = zoomLevel
        
        let template = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        super.init(urlTemplate: template)
        
        self.minimumZ = zoomLevel
        self.maximumZ = zoomLevel
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let tileKey = "\(path.z)_\(path.x)_\(path.y).png"
        let tilePath = cacheDirectory.appendingPathComponent(tileKey)
        
        if FileManager.default.fileExists(atPath: tilePath.path) {
            return tilePath
        }
        
        return URL(string: "https://tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png")!
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let tileKey = "\(path.z)_\(path.x)_\(path.y).png"
        let tilePath = cacheDirectory.appendingPathComponent(tileKey)
        
        if FileManager.default.fileExists(atPath: tilePath.path) {
            do {
                let data = try Data(contentsOf: tilePath)
                result(data, nil)
                return
            } catch {
                print("Failed to load cached tile: \(error)")
            }
        }
        
        super.loadTile(at: path, result: result)
    }
}