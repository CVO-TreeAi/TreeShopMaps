import UIKit
import MapKit

// MARK: - Search & Location Extension
extension MainMapViewController {
    
    func setupSearchCompleter() {
        localSearchCompleter = MKLocalSearchCompleter()
        localSearchCompleter.delegate = self
        localSearchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        
        // Set a wider region for better search results
        let center = mapView.region.center
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        localSearchCompleter.region = MKCoordinateRegion(center: center, span: span)
        
        print("🔍 Search completer setup complete - region: \(localSearchCompleter.region)")
    }
    
    @objc func centerOnMyLocation() {
        guard let userLocation = mapView.userLocation.location else {
            print("📍 User location not available")
            return
        }
        
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        mapView.setRegion(region, animated: true)
        print("📍 Centered on user location")
    }
    
    @objc func zoomIn() {
        var region = mapView.region
        region.span.latitudeDelta *= 0.5
        region.span.longitudeDelta *= 0.5
        mapView.setRegion(region, animated: true)
    }
    
    @objc func zoomOut() {
        var region = mapView.region
        region.span.latitudeDelta *= 2.0
        region.span.longitudeDelta *= 2.0
        mapView.setRegion(region, animated: true)
    }
    
    func showSearchResults() {
        searchResultsTableView.reloadData()
        searchResultsTableView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.searchResultsTableView.alpha = 1.0
        }
    }
    
    func hideSearchResults() {
        UIView.animate(withDuration: 0.3) {
            self.searchResultsTableView.alpha = 0.0
        } completion: { _ in
            self.searchResultsTableView.isHidden = true
        }
    }
    
    private func performSearch(with completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Search failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let firstItem = response.mapItems.first {
                DispatchQueue.main.async {
                    self.showLocationOnMap(firstItem)
                }
            }
        }
    }
    
    private func showLocationOnMap(_ mapItem: MKMapItem) {
        // Remove previous search annotation
        if let annotation = currentSearchLocationAnnotation {
            mapView.removeAnnotation(annotation)
        }
        
        // Add new search annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = mapItem.name
        annotation.subtitle = mapItem.placemark.title
        
        mapView.addAnnotation(annotation)
        currentSearchLocationAnnotation = annotation
        
        // Center map on location
        let region = MKCoordinateRegion(
            center: mapItem.placemark.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
        
        // Hide search results
        hideSearchResults()
        searchBar.resignFirstResponder()
    }
}