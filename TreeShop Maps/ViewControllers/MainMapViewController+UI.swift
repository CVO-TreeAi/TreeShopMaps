import UIKit
import MapKit

// MARK: - UI Setup Extension
extension MainMapViewController {
    
    func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        // Setup UI elements in proper order: map first, then UI on top
        setupMapView()
        setupSearchBar()
        // setupZoomControls() // Moved to bottom section
        setupMyLocationButton()
        setupBottomToolsView()
        // REMOVE ALL EXISTING TOOLBARS
        view.subviews.forEach { subview in
            if subview is UIToolbar {
                subview.removeFromSuperview()
            }
        }
        // setupForcedCleanToolbar() // Disabled for clean workflow UI
        // Initialize toolbar to prevent crashes but don't show it
        toolbar = UIToolbar()
        setupScreenLockButton()
        setupProfessionalUI()
    }
    
    func setupMapView() {
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .hybridFlyover
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupSearchBar() {
        searchContainerView = UIView()
        searchContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.backgroundColor = .clear
        view.addSubview(searchContainerView)
        
        searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Search for addresses or places..."
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        searchBar.searchBarStyle = .minimal
        
        if let textField = searchBar.searchTextField {
            textField.backgroundColor = TreeShopTheme.cardBackground
            textField.textColor = TreeShopTheme.primaryText
            textField.layer.cornerRadius = TreeShopTheme.cornerRadius
            textField.layer.masksToBounds = true
            textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search for addresses or places...",
                attributes: [NSAttributedString.Key.foregroundColor: TreeShopTheme.tertiaryText]
            )
        }
        
        searchContainerView.addSubview(searchBar)
        
        // Search results table view
        searchResultsTableView = UITableView()
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.backgroundColor = TreeShopTheme.cardBackground
        searchResultsTableView.layer.cornerRadius = TreeShopTheme.cornerRadius
        searchResultsTableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        searchResultsTableView.isHidden = true
        searchResultsTableView.separatorColor = TreeShopTheme.buttonBackground
        searchContainerView.addSubview(searchResultsTableView)
        
        NSLayoutConstraint.activate([
            searchContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            searchBar.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            
            searchResultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            searchResultsTableView.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchResultsTableView.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            searchResultsTableView.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
            searchResultsTableView.heightAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
    }
    
    func setupMyLocationButton() {
        // The location functionality is now in the bottom section
    }
    
    func setupScreenLockButton() {
        // Screen lock is now in the bottom section
    }
    
    func setupProfessionalUI() {
        // Additional professional features setup
    }
}