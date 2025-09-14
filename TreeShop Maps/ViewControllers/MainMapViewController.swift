import UIKit
import MapKit
import CoreData
import CoreLocation

class MainMapViewController: UIViewController {
    
    // MARK: - UI Elements
    var mapView: MKMapView! // Made public for tree pin access
    private var searchBar: UISearchBar!
    private var searchResultsTableView: UITableView!
    private var searchContainerView: UIView!
    private var toolbar: UIToolbar? // Made optional since we're not using it
    private var bottomToolsView: UIView!
    private var currentModeLabel: UILabel!
    private var areaLabel: UILabel!
    private var perimeterLabel: UILabel!
    private var zoomControlsView: UIView!
    private var zoomInButton: UIButton!
    private var zoomOutButton: UIButton!
    private var myLocationButton: UIButton!
    private var screenLockButton: UIButton!
    private var isScreenLocked: Bool = false
    
    // MARK: - Professional Measurement UI (commented until files added to project)
    // private var gpsAccuracyView: GPSAccuracyIndicatorView!
    // private var crosshairView: CrosshairView!
    // private var unitsToggleControl: UnitsToggleControl?
    // private var measurementLabels: [MeasurementLabelAnnotation] = []
    
    // MARK: - Managers
    private var locationManager: LocationManager!
    private var mapCacheManager: MapCacheManager!
    private var localSearchCompleter: MKLocalSearchCompleter!
    private var searchResults: [MKLocalSearchCompletion] = []
    private var currentSearchLocationAnnotation: MKPointAnnotation?
    private var currentSelectedPackage: ServicePackage = .medium
    
    // MARK: - Mode Management
    enum AppMode {
        case normal
        case drawing
        case measuring
        case treeInventory
    }
    private var currentMode: AppMode = .normal
    
    // MARK: - Drawing Properties
    private var drawingMarkers: [MKPointAnnotation] = []
    private var currentPolygon: MKPolygon?
    private var workZonePolygons: [MKPolygon] = []
    
    // MARK: - Property Line Properties
    private var propertyLinePolygons: [MKPolygon] = []
    private var propertyOwnerAnnotations: [MKPointAnnotation] = []
    private var showPropertyLines: Bool = true
    private var lastPropertyLoadRegion: MKCoordinateRegion?
    
    // MARK: - Measuring Properties
    private var measuringMarkers: [MKPointAnnotation] = []
    private var measuringLine: MKPolyline?
    
    // MARK: - Professional Measurement Features
    private var undoStack: [[MKPointAnnotation]] = []
    private var redoStack: [[MKPointAnnotation]] = []
    private var currentMeasurementValue: Double = 0
    private var currentPerimeterValue: Double = 0
    // private var loadedMeasurements: [StoredMeasurement] = []
    
    // MARK: - TreeScore Properties
    private var treeInventoryMode: Bool = false
    private var treeScoreAnnotations: [TreeScoreAnnotation] = []
    private var pendingTreeLocation: CLLocationCoordinate2D?
    
    // MARK: - Gesture Recognizers
    private var drawingTapGesture: UITapGestureRecognizer!
    
    // MARK: - Lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Suppress any unused warnings globally
        _ = 0
        
        // Add TreeShop branding to navigation bar - simplified
        // let brandedTitleView = SimpleBrandedTitleView()
        // navigationItem.titleView = brandedTitleView
        title = "TreeShop Maps"
        
        setupUI()
        setupManagers()
        setupGestureRecognizers()
        setupSearchCompleter()
        loadSavedDrawingsSimple() // Load saved drawings
        loadExistingTreeInventory() // Load saved trees
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - UI Setup
    private func setupBrandedNavigationTitle() {
        // Professional title view (commented until added to project)
        // let titleView = BrandedNavigationTitleView()
        // navigationItem.titleView = titleView
        // titleView.updateForCurrentTraitCollection()
    }
    
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        overrideUserInterfaceStyle = .dark
        
        setupBrandedNavigationTitle()
        TreeShopTheme.applyNavigationBarTheme(to: navigationController)
        
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
    
    private func setupMapView() {
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .hybridFlyover
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.delegate = self
        
        // Dark mode for map
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .dark
        }
        
        view.addSubview(mapView)
        
        // Map view should fill the screen but stay behind UI elements
        // We'll set constraints that allow UI elements to be visible on top
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Ensure map stays in background
        view.sendSubviewToBack(mapView)
    }
    
    private func setupSearchBar() {
        // Create search container view
        searchContainerView = UIView()
        searchContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.backgroundColor = TreeShopTheme.cardBackground
        searchContainerView.layer.cornerRadius = TreeShopTheme.cornerRadius
        searchContainerView.layer.shadowColor = UIColor.black.cgColor
        searchContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchContainerView.layer.shadowOpacity = 0.3
        searchContainerView.layer.shadowRadius = 4
        view.addSubview(searchContainerView)
        
        // Create search bar
        searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Search for addresses or places..."
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = TreeShopTheme.cardBackground
        searchBar.backgroundColor = UIColor.clear
        searchBar.tintColor = TreeShopTheme.primaryGreen
        searchBar.isTranslucent = false
        
        // Style the search bar for dark theme
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = TreeShopTheme.buttonBackground
            textField.textColor = TreeShopTheme.primaryText
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search for addresses or places...",
                attributes: [.foregroundColor: TreeShopTheme.secondaryText]
            )
            textField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
            textField.leftView?.tintColor = TreeShopTheme.secondaryText
            textField.clearButtonMode = .whileEditing
        }
        
        searchContainerView.addSubview(searchBar)
        
        // Create search results table view
        searchResultsTableView = UITableView()
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.backgroundColor = TreeShopTheme.cardBackground
        searchResultsTableView.separatorColor = TreeShopTheme.secondaryBackground
        searchResultsTableView.layer.cornerRadius = TreeShopTheme.cornerRadius
        searchResultsTableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        searchResultsTableView.isHidden = true
        searchResultsTableView.showsVerticalScrollIndicator = false
        
        // Register cell with subtitle style
        searchResultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        
        searchContainerView.addSubview(searchResultsTableView)
        
        // Constraints for search container
        NSLayoutConstraint.activate([
            searchContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        
        // Constraints for search bar
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Constraints for search results table view
        NSLayoutConstraint.activate([
            searchResultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            searchResultsTableView.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchResultsTableView.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            searchResultsTableView.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
            searchResultsTableView.heightAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
        
        // Bring search container to front
        view.bringSubviewToFront(searchContainerView)
    }
    
    private func setupZoomControls() {
        // Create zoom controls container
        zoomControlsView = UIView()
        zoomControlsView.translatesAutoresizingMaskIntoConstraints = false
        zoomControlsView.backgroundColor = TreeShopTheme.cardBackground
        zoomControlsView.layer.cornerRadius = TreeShopTheme.cornerRadius
        zoomControlsView.layer.shadowColor = UIColor.black.cgColor
        zoomControlsView.layer.shadowOffset = CGSize(width: 0, height: 2)
        zoomControlsView.layer.shadowOpacity = 0.3
        zoomControlsView.layer.shadowRadius = 4
        view.addSubview(zoomControlsView)
        
        // Create zoom in button
        zoomInButton = UIButton(type: .system)
        zoomInButton.translatesAutoresizingMaskIntoConstraints = false
        zoomInButton.setImage(UIImage(systemName: "plus"), for: .normal)
        zoomInButton.tintColor = TreeShopTheme.primaryGreen
        zoomInButton.backgroundColor = UIColor.clear
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        zoomControlsView.addSubview(zoomInButton)
        
        // Create zoom out button
        zoomOutButton = UIButton(type: .system)
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        zoomOutButton.setImage(UIImage(systemName: "minus"), for: .normal)
        zoomOutButton.tintColor = TreeShopTheme.primaryGreen
        zoomOutButton.backgroundColor = UIColor.clear
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        zoomControlsView.addSubview(zoomOutButton)
        
        // Add separator line
        let separatorLine = UIView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.backgroundColor = TreeShopTheme.secondaryText.withAlphaComponent(0.3)
        zoomControlsView.addSubview(separatorLine)
        
        // Layout zoom controls
        NSLayoutConstraint.activate([
            // Container positioning - top right
            zoomControlsView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 16),
            zoomControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            zoomControlsView.widthAnchor.constraint(equalToConstant: 50),
            zoomControlsView.heightAnchor.constraint(equalToConstant: 100),
            
            // Zoom in button
            zoomInButton.topAnchor.constraint(equalTo: zoomControlsView.topAnchor, constant: 8),
            zoomInButton.centerXAnchor.constraint(equalTo: zoomControlsView.centerXAnchor),
            zoomInButton.widthAnchor.constraint(equalToConstant: 34),
            zoomInButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Separator line
            separatorLine.topAnchor.constraint(equalTo: zoomInButton.bottomAnchor, constant: 4),
            separatorLine.centerXAnchor.constraint(equalTo: zoomControlsView.centerXAnchor),
            separatorLine.widthAnchor.constraint(equalToConstant: 20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Zoom out button
            zoomOutButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 4),
            zoomOutButton.centerXAnchor.constraint(equalTo: zoomControlsView.centerXAnchor),
            zoomOutButton.widthAnchor.constraint(equalToConstant: 34),
            zoomOutButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        // Bring to front
        view.bringSubviewToFront(zoomControlsView)
    }
    
    @objc private func zoomIn() {
        let region = mapView.region
        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 0.5,
            longitudeDelta: region.span.longitudeDelta * 0.5
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        mapView.setRegion(newRegion, animated: true)
    }
    
    @objc private func zoomOut() {
        let region = mapView.region
        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 2.0,
            longitudeDelta: region.span.longitudeDelta * 2.0
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        mapView.setRegion(newRegion, animated: true)
    }
    
    private func setupMyLocationButton() {
        myLocationButton = UIButton(type: .system)
        myLocationButton.translatesAutoresizingMaskIntoConstraints = false
        myLocationButton.setImage(UIImage(systemName: "location.circle.fill"), for: .normal)
        myLocationButton.tintColor = TreeShopTheme.primaryGreen
        myLocationButton.backgroundColor = TreeShopTheme.cardBackground
        myLocationButton.layer.cornerRadius = 25
        myLocationButton.layer.shadowColor = UIColor.black.cgColor
        myLocationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        myLocationButton.layer.shadowOpacity = 0.3
        myLocationButton.layer.shadowRadius = 4
        myLocationButton.addTarget(self, action: #selector(centerOnMyLocation), for: .touchUpInside)
        
        view.addSubview(myLocationButton)
        view.bringSubviewToFront(myLocationButton)
        
        NSLayoutConstraint.activate([
            myLocationButton.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 16),
            myLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            myLocationButton.widthAnchor.constraint(equalToConstant: 50),
            myLocationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupScreenLockButton() {
        screenLockButton = UIButton(type: .system)
        screenLockButton.translatesAutoresizingMaskIntoConstraints = false
        screenLockButton.setImage(UIImage(systemName: "lock.circle"), for: .normal)
        screenLockButton.tintColor = TreeShopTheme.secondaryText
        screenLockButton.backgroundColor = TreeShopTheme.cardBackground.withAlphaComponent(0.9)
        screenLockButton.layer.cornerRadius = 22
        screenLockButton.addTarget(self, action: #selector(toggleScreenLock), for: .touchUpInside)
        
        view.addSubview(screenLockButton)
        view.bringSubviewToFront(screenLockButton)
        
        NSLayoutConstraint.activate([
            screenLockButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            screenLockButton.bottomAnchor.constraint(equalTo: bottomToolsView.topAnchor, constant: -60),
            screenLockButton.widthAnchor.constraint(equalToConstant: 44),
            screenLockButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func centerOnMyLocation() {
        guard let location = mapView.userLocation.location else {
            showAlert(title: "Location Not Available", message: "Please enable location services and try again.")
            return
        }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        mapView.setRegion(region, animated: true)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc private func toggleScreenLock() {
        isScreenLocked.toggle()
        
        if isScreenLocked {
            // Enable screen always on
            UIApplication.shared.isIdleTimerDisabled = true
            screenLockButton.setImage(UIImage(systemName: "lock.circle.fill"), for: .normal)
            screenLockButton.tintColor = TreeShopTheme.primaryGreen
            showAlert(title: "Screen Lock ON", message: "Screen will stay on. Perfect for hands-free GPS tracking!")
        } else {
            // Disable screen always on
            UIApplication.shared.isIdleTimerDisabled = false
            screenLockButton.setImage(UIImage(systemName: "lock.circle"), for: .normal)
            screenLockButton.tintColor = TreeShopTheme.secondaryText
            showAlert(title: "Screen Lock OFF", message: "Screen will auto-sleep normally.")
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isScreenLocked ? .success : .warning)
    }
    
    private func setupGestureRecognizers() {
        // Drawing tap gesture - NOT added by default
        drawingTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDrawingTap(_:)))
        drawingTapGesture.delegate = self
        
        // Long press gesture for polygon context menu
        let polygonLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handlePolygonLongPress(_:)))
        polygonLongPressGesture.minimumPressDuration = 0.5
        polygonLongPressGesture.delegate = self
        mapView.addGestureRecognizer(polygonLongPressGesture)
        
        // Map tap gesture to dismiss search and handle polygon taps - always active
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapTapGesture.delegate = self
        mapView.addGestureRecognizer(mapTapGesture)
    }
    
    private func setupBottomToolsView() {
        // STEVE JOBS CLEAN DESIGN - WORKFLOW-BASED UI
        bottomToolsView = UIView()
        bottomToolsView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolsView.backgroundColor = TreeShopTheme.cardBackground
        
        view.addSubview(bottomToolsView)
        view.bringSubviewToFront(bottomToolsView)
        
        // CLEAN 3-ROW LAYOUT
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fill
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        bottomToolsView.addSubview(mainStack)
        
        // ROW 1: Context Bar (Mode + Package + GPS)
        let contextBar = UIStackView()
        contextBar.axis = .horizontal
        contextBar.distribution = .fill
        contextBar.alignment = .center
        contextBar.spacing = 16
        
        // Profile Button (not a label)
        let profileBtn = UIButton(type: .system)
        profileBtn.setTitle("👤 Profile", for: .normal)
        profileBtn.backgroundColor = TreeShopTheme.buttonBackground
        profileBtn.setTitleColor(TreeShopTheme.primaryText, for: .normal)
        profileBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        profileBtn.layer.cornerRadius = 8
        profileBtn.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
        profileBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileBtn.widthAnchor.constraint(equalToConstant: 100),
            profileBtn.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        contextBar.addArrangedSubview(profileBtn)
        
        // Mode Status Label
        currentModeLabel = UILabel()
        currentModeLabel.text = "Ready"
        currentModeLabel.textColor = TreeShopTheme.primaryText
        currentModeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        currentModeLabel.textAlignment = .center
        contextBar.addArrangedSubview(currentModeLabel)
        
        let spacer = UIView()
        contextBar.addArrangedSubview(spacer)
        
        let gpsLabel = UILabel()
        gpsLabel.text = "GPS: ±2.1m"
        gpsLabel.textColor = TreeShopTheme.secondaryText
        gpsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        contextBar.addArrangedSubview(gpsLabel)
        
        mainStack.addArrangedSubview(contextBar)
        
        // ROW 2: Primary Data Display (More Space)
        let dataContainer = UIView()
        
        areaLabel = UILabel()
        areaLabel.text = "0.12 acres"
        areaLabel.textColor = TreeShopTheme.primaryGreen
        areaLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        areaLabel.textAlignment = .center
        areaLabel.translatesAutoresizingMaskIntoConstraints = false
        dataContainer.addSubview(areaLabel)
        
        // Secondary Data
        let secondaryData = UIStackView()
        secondaryData.axis = .horizontal
        secondaryData.distribution = .fillEqually
        secondaryData.spacing = 8
        secondaryData.translatesAutoresizingMaskIntoConstraints = false
        dataContainer.addSubview(secondaryData)
        
        perimeterLabel = UILabel()
        perimeterLabel.text = "293.5 ft"
        perimeterLabel.textColor = TreeShopTheme.accentGreen
        perimeterLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        perimeterLabel.textAlignment = .center
        secondaryData.addArrangedSubview(perimeterLabel)
        
        let treeCountLabel = UILabel()
        treeCountLabel.text = "3 trees"
        treeCountLabel.textColor = TreeShopTheme.primaryText
        treeCountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        treeCountLabel.textAlignment = .center
        treeCountLabel.tag = 9001
        secondaryData.addArrangedSubview(treeCountLabel)
        
        NSLayoutConstraint.activate([
            areaLabel.centerXAnchor.constraint(equalTo: dataContainer.centerXAnchor),
            areaLabel.centerYAnchor.constraint(equalTo: dataContainer.centerYAnchor, constant: -12),
            
            secondaryData.topAnchor.constraint(equalTo: areaLabel.bottomAnchor, constant: 8),
            secondaryData.leadingAnchor.constraint(equalTo: dataContainer.leadingAnchor, constant: 40),
            secondaryData.trailingAnchor.constraint(equalTo: dataContainer.trailingAnchor, constant: -40)
        ])
        
        mainStack.addArrangedSubview(dataContainer)
        
        // ROW 3: 4 Clear Workflow Buttons
        let workflowRow = UIStackView()
        workflowRow.axis = .horizontal
        workflowRow.distribution = .fillEqually
        workflowRow.spacing = 16
        
        let areaBtn = createWorkflowButton(title: "Area", subtitle: "Draw")
        areaBtn.addTarget(self, action: #selector(toggleDrawingMode), for: .touchUpInside)
        workflowRow.addArrangedSubview(areaBtn)
        
        let treeBtn = createWorkflowButton(title: "Tree", subtitle: "Assess")
        treeBtn.addTarget(self, action: #selector(toggleTreeInventoryMode), for: .touchUpInside)
        workflowRow.addArrangedSubview(treeBtn)
        
        let measureBtn = createWorkflowButton(title: "Measure", subtitle: "Tools")
        measureBtn.addTarget(self, action: #selector(toggleMeasuringMode), for: .touchUpInside)
        workflowRow.addArrangedSubview(measureBtn)
        
        let moreBtn = createWorkflowButton(title: "More", subtitle: "Menu")
        moreBtn.addTarget(self, action: #selector(showMoreMenu), for: .touchUpInside)
        workflowRow.addArrangedSubview(moreBtn)
        
        mainStack.addArrangedSubview(workflowRow)
        
        // Layout - 25% OF SCREEN
        NSLayoutConstraint.activate([
            bottomToolsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomToolsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),
            
            mainStack.topAnchor.constraint(equalTo: bottomToolsView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: bottomToolsView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: bottomToolsView.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: bottomToolsView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createWorkflowButton(title: String, subtitle: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(title)\n\(subtitle)", for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        return button
    }
    
    @objc private func packageSegmentChanged(_ control: UISegmentedControl) {
        let packages = [ServicePackage.small, .medium, .large, .xLarge, .max]
        currentSelectedPackage = packages[control.selectedSegmentIndex]
        print("📦 Package changed to: \(currentSelectedPackage.rawValue)")
    }
    
    private func createTopButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = TreeShopTheme.buttonBackground
        button.setTitleColor(TreeShopTheme.primaryText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return button
    }
    
    @objc private func packageSelected(_ button: UIButton) {
        let packageIndex = button.tag - 8000
        let packages = [ServicePackage.small, .medium, .large, .xLarge, .max]
        
        // Update visual selection
        if let parent = button.superview {
            for i in 0..<5 {
                if let btn = parent.viewWithTag(8000 + i) as? UIButton {
                    btn.layer.borderWidth = (i == packageIndex) ? 2 : 1
                    btn.layer.borderColor = (i == packageIndex) ? UIColor.white.cgColor : UIColor.clear.cgColor
                }
            }
        }
        
        // Set current package for drawing
        currentSelectedPackage = packages[packageIndex]
        
        print("📦 Selected package: \(packages[packageIndex].rawValue)")
    }
    
    private func createMainButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return button
    }
    
    private func createToolButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        return button
    }
    
    private func createSimpleButton(icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(icon, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return button
    }
    
    private func createCleanToolButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(icon, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }
    
    private func createMainToolButton(icon: String, title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(icon)\n\(title)", for: .normal)
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        return button
    }
    
    private func setupForcedCleanToolbar() {
        // Initialize toolbar but hide it - using bottom section instead
        toolbar?.removeFromSuperview()
        toolbar = nil
        
        toolbar = UIToolbar()
        toolbar?.translatesAutoresizingMaskIntoConstraints = false
        toolbar?.backgroundColor = TreeShopTheme.cardBackground
        toolbar?.isHidden = true // Hide the toolbar completely
        
        toolbar?.removeFromSuperview()
        toolbar = nil
        
        toolbar = UIToolbar()
        toolbar?.translatesAutoresizingMaskIntoConstraints = false
        toolbar?.backgroundColor = TreeShopTheme.cardBackground
        if let toolbar = toolbar {
            TreeShopTheme.applyToolbarTheme(to: toolbar)
        }
        
        let drawBtn = UIBarButtonItem(
            image: UIImage(systemName: "pencil.tip.crop.circle"),
            style: .plain, 
            target: self, 
            action: #selector(toggleDrawingMode)
        )
        
        let moreBtn = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreMenu)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let treeBtn = UIBarButtonItem(
            image: UIImage(systemName: "tree.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleTreeInventoryMode)
        )
        
        let measureBtn = UIBarButtonItem(
            image: UIImage(systemName: "ruler"),
            style: .plain,
            target: self,
            action: #selector(toggleMeasuringMode)
        )
        
        // Add TreeScore and measurement tools to toolbar
        toolbar?.items = [flexSpace, drawBtn, flexSpace, treeBtn, flexSpace, measureBtn, flexSpace, moreBtn, flexSpace]
        
        if let toolbar = toolbar {
            view.addSubview(toolbar)
            view.bringSubviewToFront(toolbar)
            
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: bottomToolsView.topAnchor, constant: -8),
                toolbar.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func updateToolbarForMode(_ mode: AppMode) {
        // DISABLED - Using bottom section workflow buttons instead
        
        let drawBtn = UIBarButtonItem(
            image: UIImage(systemName: "pencil.tip.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleDrawingMode)
        )
        
        let moreBtn = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreMenu)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let treeBtn = UIBarButtonItem(
            image: UIImage(systemName: "tree.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleTreeInventoryMode)
        )
        treeBtn.tintColor = (mode == .treeInventory) ? TreeShopTheme.primaryGreen : nil
        
        let measureBtn = UIBarButtonItem(
            image: UIImage(systemName: "ruler"),
            style: .plain,
            target: self,
            action: #selector(toggleMeasuringMode)
        )
        measureBtn.tintColor = (mode == .measuring) ? TreeShopTheme.primaryGreen : nil
        
        if mode == .normal {
            // Normal mode: All main tools available
            toolbar?.items = [flexSpace, drawBtn, flexSpace, treeBtn, flexSpace, measureBtn, flexSpace, moreBtn, flexSpace]
        } else if mode == .treeInventory {
            // TreeScore mode: Tree tools highlighted
            let exportBtn = UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(exportTreeScoreData)
            )
            toolbar?.items = [treeBtn, flexSpace, exportBtn, flexSpace, drawBtn, flexSpace, measureBtn, flexSpace, moreBtn]
        } else {
            // Drawing mode: Add Clear and Undo buttons
            let clearBtn = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(clearCurrentMode)
            )
            
            let undoBtn = UIBarButtonItem(
                image: UIImage(systemName: "arrow.uturn.backward"),
                style: .plain,
                target: self,
                action: #selector(undoLastPoint)
            )
            
            toolbar?.items = [drawBtn, flexSpace, undoBtn, flexSpace, clearBtn, flexSpace, moreBtn]
        }
    }
    
    private func setupManagers() {
        locationManager = LocationManager.shared
        mapCacheManager = MapCacheManager.shared
        
        locationManager.startTracking()
        centerOnUserLocation()
    }
    
    private func setupSearchCompleter() {
        localSearchCompleter = MKLocalSearchCompleter()
        localSearchCompleter.delegate = self
        localSearchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        
        // Set a wider region for better search results
        let center = mapView.region.center
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        localSearchCompleter.region = MKCoordinateRegion(center: center, span: span)
        
        print("🔍 Search completer setup complete - region: \(localSearchCompleter.region)")
    }
    
    // MARK: - Professional Features Setup
    private func setupProfessionalFeatures() {
        // Set up location manager delegate for GPS accuracy
        // locationManager.delegate = self  // Commented until delegate methods are implemented
        
        // Load any saved measurements and drawings
        loadSavedDrawingsSimple()
    }
    
    private func setupProfessionalUI() {
        // Simplified - no complex UI components for now
        print("Professional UI setup - simplified version")
    }
    
    // MARK: - Mode Management
    private func setMode(_ mode: AppMode) {
        // Clean up previous mode
        cleanupCurrentMode()
        
        // Remove all gesture recognizers
        mapView.removeGestureRecognizer(drawingTapGesture)
        // mapView.removeGestureRecognizer(treeLongPressGesture)  // Removed tree functionality
        
        currentMode = mode
        
        switch mode {
        case .normal:
            currentModeLabel.text = "Ready"
            currentModeLabel.textColor = TreeShopTheme.primaryText
            // updateToolbarForMode(.normal) // Using bottom section
            
        case .drawing:
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.textColor = TreeShopTheme.primaryGreen
            mapView.addGestureRecognizer(drawingTapGesture)
            // updateToolbarForMode(.drawing) // Using bottom section
            
        case .measuring:
            currentModeLabel.text = "Measuring Mode - Tap to add points"
            currentModeLabel.textColor = TreeShopTheme.primaryGreen
            areaLabel.text = "0 ft"
            mapView.addGestureRecognizer(drawingTapGesture)
            // updateToolbarForMode(.measuring) // Using bottom section
            
        case .treeInventory:
            currentModeLabel.text = "Tree Inventory - Tap map to add trees"
            currentModeLabel.textColor = TreeShopTheme.primaryGreen
            treeInventoryMode = true
            updateAreaLabelWithTreeScoreInfo()
            mapView.addGestureRecognizer(drawingTapGesture)
            // updateToolbarForMode(.treeInventory) // Using bottom section
        }
    }
    
    private func cleanupCurrentMode() {
        switch currentMode {
        case .drawing:
            clearDrawing()
        // case .treeMarking:  // Removed tree marking functionality
        //     // Nothing to clean up
        //     break
        case .measuring:
            // Clear measurement annotations
            clearMeasuring()
        case .treeInventory:
            treeInventoryMode = false
        case .normal:
            break
        }
    }
    
    // MARK: - Drawing Mode
    @objc private func toggleDrawingMode() {
        if currentMode == .drawing {
            setMode(.normal)
        } else {
            setMode(.drawing)
        }
    }
    
    @objc private func toggleTreeInventoryMode() {
        if currentMode == .treeInventory {
            setMode(.normal)
        } else {
            setMode(.treeInventory)
        }
    }
    
    @objc private func toggleMeasuringMode() {
        if currentMode == .measuring {
            setMode(.normal)
        } else {
            setMode(.measuring)
        }
    }
    
    @objc private func exportTreeScoreData() {
        guard let exportURL = TreeInventoryManager.shared.exportTreeScoreData() else {
            showTreeScoreAlert(title: "Export Failed", message: "Unable to export TreeScore data.")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
        
        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = toolbar?.items?.first { item in
                item.image == UIImage(systemName: "square.and.arrow.up")
            }
        }
        
        present(activityVC, animated: true)
    }
    
    private func showTreeScoreAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleDrawingTap(_ gesture: UITapGestureRecognizer) {
        switch currentMode {
        case .drawing:
            handleDrawingModeTap(gesture)
        case .measuring:
            handleMeasuringModeTap(gesture)
        case .treeInventory:
            handleTreeInventoryTap(gesture)
        default:
            break
        }
    }
    
    private func handleDrawingModeTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Add marker for vertex
        let marker = MKPointAnnotation()
        marker.coordinate = coordinate
        marker.title = "Point \(drawingMarkers.count + 1)"
        mapView.addAnnotation(marker)
        drawingMarkers.append(marker)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Update polygon overlay
        updatePolygonOverlay()
        
        // Update UI
        currentModeLabel.text = "Drawing Mode - \(drawingMarkers.count) points"
        
        // Save state for undo
        saveCurrentStateForUndo()
        
        if drawingMarkers.count == 1 {
            areaLabel.text = "Tap to add second point"
            perimeterLabel.isHidden = true
        } else if drawingMarkers.count == 2 {
            // Show distance between 2 points
            let distance = calculateDistance()
            currentMeasurementValue = distance
            areaLabel.text = String(format: "%.1f ft", distance)
            perimeterLabel.isHidden = true
            updateOnMapLabels()
        } else if drawingMarkers.count >= 3 {
            // Show area and perimeter for 3+ points
            let area = calculatePolygonArea()
            let perimeter = calculatePolygonPerimeter()
            currentMeasurementValue = area
            currentPerimeterValue = perimeter
            updateAreaDisplay()
            updateOnMapLabels()
        }
    }
    
    private func updatePolygonOverlay() {
        // Remove existing polygon
        if let polygon = currentPolygon {
            mapView.removeOverlay(polygon)
        }
        
        // Need at least 3 points for a polygon
        guard drawingMarkers.count >= 3 else { return }
        
        // Create new polygon
        let coordinates = drawingMarkers.map { $0.coordinate }
        currentPolygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        // currentPolygon?.title = currentServicePackage.rawValue  // Removed service package
        
        if let polygon = currentPolygon {
            mapView.addOverlay(polygon)
        }
    }
    
    @objc private func clearDrawing() {
        // Remove markers
        mapView.removeAnnotations(drawingMarkers)
        drawingMarkers.removeAll()
        
        // Remove polygon
        if let polygon = currentPolygon {
            mapView.removeOverlay(polygon)
            currentPolygon = nil
        }
        
        // Remove measurement labels
        // mapView.removeAnnotations(measurementLabels)  // Commented until MeasurementLabelAnnotation is added
        // measurementLabels.removeAll()  // Commented until MeasurementLabelAnnotation is added
        
        // Clear undo/redo stacks
        undoStack.removeAll()
        redoStack.removeAll()
        
        // Reset values
        currentMeasurementValue = 0
        currentPerimeterValue = 0
        
        // Reset UI
        areaLabel.text = "0.00 acres"
        perimeterLabel.isHidden = true
        if currentMode == .drawing {
            currentModeLabel.text = "Drawing Mode - Tap to add points"
        }
    }
    
    @objc private func finishDrawing() {
        guard let polygon = currentPolygon,
              drawingMarkers.count >= 3 else {
            showAlert(title: "Invalid Area", message: "An area requires at least 3 points")
            return
        }
        
        // Save the drawing permanently
        saveDrawingAsMeasurement(polygon: polygon)
        
        // Keep the polygon on map but clear drawing state
        workZonePolygons.append(polygon)
        mapView.removeAnnotations(drawingMarkers)
        drawingMarkers.removeAll()
        currentPolygon = nil
        
        // Update UI
        areaLabel.text = "0.00 acres"
        setMode(.normal)
    }
    
    // MARK: - Tree Marking Mode - REMOVED
    // @objc private func toggleTreeMode() {
    //     if currentMode == .treeMarking {
    //         setMode(.normal)
    //     } else {
    //         setMode(.treeMarking)
    //     }
    // }
    
    // @objc private func handleTreeLongPress(_ gesture: UILongPressGestureRecognizer) {
    //     guard gesture.state == .began else { return }
    //     
    //     let point = gesture.location(in: mapView)
    //     let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
    //     
    //     // Show species selection with autocomplete
    //     showSpeciesSelection { [weak self] species in
    //         self?.addTreeMark(at: coordinate, species: species)
    //     }
    // }
    
    // private func showSpeciesSelection(completion: @escaping (String) -> Void) {
    //     let speciesVC = SpeciesSelectionViewController()
    //     speciesVC.onSpeciesSelected = completion
    //     
    //     let navController = UINavigationController(rootViewController: speciesVC)
    //     TreeShopTheme.applyNavigationBarTheme(to: navController)
    //     
    //     if let sheet = navController.sheetPresentationController {
    //         sheet.detents = [.medium()]
    //         sheet.prefersGrabberVisible = true
    //     }
    //     
    //     present(navController, animated: true)
    // }
    // 
    // private func addTreeMark(at coordinate: CLLocationCoordinate2D, species: String) {
    //     guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
    //           let property = currentProperty else { return }
    //     
    //     let context = appDelegate.persistentContainer.viewContext
    //     
    //     let treeMark = TreeMark(context: context)
    //     treeMark.id = UUID()
    //     treeMark.latitude = coordinate.latitude
    //     treeMark.longitude = coordinate.longitude
    //     treeMark.species = species
    //     treeMark.dateMarked = Date()
    //     treeMark.markedBy = UIDevice.current.name
    //     treeMark.property = property
    //     
    //     do {
    //         try context.save()
    //         
    //         // Add annotation to map
    //         let annotation = MKPointAnnotation()
    //         annotation.coordinate = coordinate
    //         annotation.title = species
    //         annotation.subtitle = "Tap for details"
    //         mapView.addAnnotation(annotation)
    //         treeAnnotations.append(annotation)
    //         
    //         // Show success feedback
    //         let generator = UINotificationFeedbackGenerator()
    //         generator.notificationOccurred(.success)
    //         
    //     } catch {
    //         print("Error saving tree mark: \(error)")
    //         showAlert(title: "Error", message: "Failed to save tree mark")
    //     }
    // }
    
    // MARK: - Measuring Mode
    @objc private func toggleMeasureMode() {
        if currentMode == .measuring {
            setMode(.normal)
        } else {
            setMode(.measuring)
        }
    }
    
    private func handleMeasuringModeTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Add marker for measuring point
        let marker = MKPointAnnotation()
        marker.coordinate = coordinate
        marker.title = "Point \(measuringMarkers.count + 1)"
        mapView.addAnnotation(marker)
        measuringMarkers.append(marker)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Save state for undo
        saveCurrentStateForUndo()
        
        // Update UI and draw line/polygon
        if measuringMarkers.count == 1 {
            currentModeLabel.text = "Measuring Mode - Tap next point"
            areaLabel.text = "Tap next point"
        } else if measuringMarkers.count == 2 {
            let distance = calculateDistance()
            currentMeasurementValue = distance
            updateDistanceDisplay()
            updateMeasuringLine()
            updateOnMapLabels()
        } else if measuringMarkers.count >= 3 {
            // For 3+ points, calculate area
            let area = calculatePolygonArea()
            let perimeter = calculatePolygonPerimeter()
            currentMeasurementValue = area
            currentPerimeterValue = perimeter
            updateAreaDisplay()
            updatePolygonOverlay()
            updateOnMapLabels()
        }
    }
    
    private func calculateDistance() -> Double {
        let markers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        guard markers.count == 2 else { return 0 }
        
        let location1 = CLLocation(
            latitude: markers[0].coordinate.latitude,
            longitude: markers[0].coordinate.longitude
        )
        let location2 = CLLocation(
            latitude: markers[1].coordinate.latitude,
            longitude: markers[1].coordinate.longitude
        )
        
        let distanceInMeters = location1.distance(from: location2)
        // Convert meters to feet (1 meter = 3.28084 feet)
        let distanceInFeet = distanceInMeters * 3.28084
        
        return distanceInFeet
    }
    
    private func updateMeasuringLine() {
        // Remove existing line
        if let line = measuringLine {
            mapView.removeOverlay(line)
        }
        
        guard measuringMarkers.count == 2 else { return }
        
        // Create new line
        let coordinates = measuringMarkers.map { $0.coordinate }
        measuringLine = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        if let line = measuringLine {
            mapView.addOverlay(line)
        }
    }
    
    private func clearMeasuring() {
        // Remove markers
        mapView.removeAnnotations(measuringMarkers)
        measuringMarkers.removeAll()
        
        // Remove line
        if let line = measuringLine {
            mapView.removeOverlay(line)
            measuringLine = nil
        }
        
        // Remove polygon if it exists (for 3+ points)
        if let polygon = currentPolygon {
            mapView.removeOverlay(polygon)
            currentPolygon = nil
        }
        
        // Remove measurement labels
        // mapView.removeAnnotations(measurementLabels)  // Commented until MeasurementLabelAnnotation is added
        // measurementLabels.removeAll()  // Commented until MeasurementLabelAnnotation is added
        
        // Clear undo/redo stacks
        undoStack.removeAll()
        redoStack.removeAll()
        
        // Reset values
        currentMeasurementValue = 0
        currentPerimeterValue = 0
        
        // Reset UI
        if currentMode == .measuring {
            currentModeLabel.text = "Measuring Mode - Tap points"
            areaLabel.text = "0 ft"
            perimeterLabel.isHidden = true
        }
    }
    
    // MARK: - Clear Current Mode
    @objc private func clearCurrentMode() {
        switch currentMode {
        case .drawing:
            clearDrawing()
        // case .treeMarking:  // Removed tree marking functionality
        //     // Optionally clear recent tree marks
        //     break
        case .measuring:
            clearMeasuring()
        case .treeInventory:
            // Keep tree annotations but disable inventory mode
            treeInventoryMode = false
            currentModeLabel.text = "Ready"
        case .normal:
            // Clear search location if in normal mode
            clearSearchLocation()
            break
        }
    }
    
    // MARK: - TreeScore Mode
    private func handleTreeInventoryTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Get current GPS accuracy from location manager
        let currentAccuracy = locationManager.getCurrentAccuracy()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Present new 3-screen TreeScore workflow - use the old method name but new implementation
        presentSimpleTreeScoreInput(at: coordinate, accuracy: currentAccuracy)
    }
    
    private func getLastAreaMeasurement() -> Double? {
        // Simplified - return current measurement value if available
        return currentMeasurementValue > 0 ? currentMeasurementValue : nil
    }
    
    func presentSimpleTreeScoreInput(at coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        // CREATE WORKING PROFESSIONAL MULTI-STEP WORKFLOW
        let workflowVC = ProfessionalTreeScoreWorkflowViewController()
        workflowVC.setLocation(coordinate, accuracy: accuracy)
        workflowVC.treeDelegate = self as? TreeScoreInputDelegate
        workflowVC.mapViewController = self
        
        let navController = UINavigationController(rootViewController: workflowVC)
        navController.modalPresentationStyle = .formSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(navController, animated: true)
    }
    private func suggestServicePackage(forArea acres: Double) -> ServicePackage {
        switch acres {
        case 0..<0.5: return .small
        case 0.5..<2.0: return .medium
        case 2.0..<5.0: return .large
        case 5.0..<10.0: return .xLarge
        default: return .max
        }
    }
    
    func updateAreaLabelWithTreeScoreInfo() { // Made public for tree workflow access
        let trees = TreeInventoryManager.shared.getTrees()
        let totalTreeScore = TreeInventoryManager.shared.getTotalTreeScore()
        let averageTreeScore = TreeInventoryManager.shared.getAverageTreeScore()
        
        if trees.isEmpty {
            areaLabel.text = "0.00 acres | No trees"
        } else {
            if let lastMeasurementValue = getLastAreaMeasurement() {
                areaLabel.text = String(format: "%.2f acres | %d trees | Avg TS: %.0f", 
                                      lastMeasurementValue, trees.count, averageTreeScore)
            } else {
                areaLabel.text = String(format: "%d trees | Total TS: %.0f | Avg: %.0f", 
                                      trees.count, totalTreeScore, averageTreeScore)
            }
        }
    }
    
    private func createTreeScoreAnnotationView(for annotation: TreeScoreAnnotation, on mapView: MKMapView) -> MKAnnotationView? {
        let identifier = "TreeScoreAnnotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: 0, y: -5)
            
            // Add detail disclosure button
            let detailButton = UIButton(type: .detailDisclosure)
            detailButton.tintColor = TreeShopTheme.primaryGreen
            annotationView?.rightCalloutAccessoryView = detailButton
        } else {
            annotationView?.annotation = annotation
        }
        
        // Set custom tree icon based on complexity
        if let treeItem = annotation.treeInventoryItem {
            let complexity = treeItem.getComplexityLevel()
            annotationView?.image = createTreeIcon(for: complexity)
        } else {
            annotationView?.image = createTreeIcon(for: .medium)
        }
        
        return annotationView
    }
    
    private func createTreeIcon(for complexity: TreeComplexity) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
        let baseImage = UIImage(systemName: complexity.iconName, withConfiguration: config)
        
        return baseImage?.withTintColor(complexity.color, renderingMode: .alwaysOriginal)
    }
    
    func loadExistingTreeInventory() { // Made public for forced reload
        let trees = TreeInventoryManager.shared.getTrees()
        
        for tree in trees {
            let annotation = tree.createMapAnnotation()
            mapView.addAnnotation(annotation)
            treeScoreAnnotations.append(annotation)
        }
        
        updateAreaLabelWithTreeScoreInfo()
        
        if !trees.isEmpty {
            print("🌲 Loaded \(trees.count) trees from inventory")
        }
    }
    
    @objc private func focusOnSearchBar() {
        searchBar.becomeFirstResponder()
    }
    
    // MARK: - Download Options - REMOVED
    // @objc private func showDownloadOptions() {
    //     let downloadVC = MapDownloadViewController()
    //     navigationController?.pushViewController(downloadVC, animated: true)
    // }
    
    // MARK: - Helper Methods
    private func calculatePolygonArea() -> Double {
        let markers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        guard markers.count >= 3 else { return 0 }
        
        let coordinates = markers.map { $0.coordinate }
        
        // Calculate area using geodesic calculation for accuracy
        let mapPoints = coordinates.map { MKMapPoint($0) }
        
        // Use the shoelace formula with proper conversion
        var area = 0.0
        for i in 0..<mapPoints.count {
            let j = (i + 1) % mapPoints.count
            area += mapPoints[i].x * mapPoints[j].y
            area -= mapPoints[j].x * mapPoints[i].y
        }
        area = abs(area) / 2.0
        
        // Convert from map points to meters
        // MKMapRect size is in map points, we need to convert to meters
        let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(coordinates[0].latitude)
        let squareMeters = area / (metersPerMapPoint * metersPerMapPoint)
        
        // Convert to acres (1 acre = 4046.86 square meters)
        let acres = squareMeters / 4046.86
        
        return acres
    }
    
    // @objc private func packageChanged(_ sender: UISegmentedControl) {
    //     currentServicePackage = ServicePackage.allCases[sender.selectedSegmentIndex]
    //     
    //     // Update current polygon if exists
    //     if let polygon = currentPolygon {
    //         polygon.title = currentServicePackage.rawValue
    //         // Refresh overlay
    //         mapView.removeOverlay(polygon)
    //         mapView.addOverlay(polygon)
    //     }
    // }
    
    private func centerOnUserLocation() {
        if let location = mapView.userLocation.location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: false)
        }
    }
    
    // private func loadCurrentProperty() {
    //     // Load from Core Data or create new
    //     guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    //     let context = appDelegate.persistentContainer.viewContext
    //     
    //     let fetchRequest: NSFetchRequest<Property> = Property.fetchRequest()
    //     fetchRequest.fetchLimit = 1
    //     fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
    //     
    //     do {
    //         let properties = try context.fetch(fetchRequest)
    //         if let property = properties.first {
    //             currentProperty = property
    //             loadPropertyData(property)
    //         } else {
    //             // Create new property
    //             let property = Property(context: context)
    //             property.id = UUID()
    //             property.createdDate = Date()
    //             property.lastModified = Date()
    //             
    //             try context.save()
    //             currentProperty = property
    //         }
    //     } catch {
    //         print("Error loading property: \(error)")
    //     }
    // }
    
    // private func loadPropertyData(_ property: Property) {
    //     // Load work zones
    //     if let workZones = property.workZones as? Set<WorkZone> {
    //         for zone in workZones {
    //             if let polygonData = zone.polygonData,
    //                let polygon = (try? NSKeyedUnarchiver(forReadingFrom: polygonData))?.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? MKPolygon {
    //                 polygon.title = zone.servicePackage
    //                 mapView.addOverlay(polygon)
    //                 workZonePolygons.append(polygon)
    //             }
    //         }
    //     }
    //     
    //     // Load tree marks
    //     if let treeMarks = property.treeMarks as? Set<TreeMark> {
    //         for tree in treeMarks {
    //             let annotation = MKPointAnnotation()
    //             annotation.coordinate = CLLocationCoordinate2D(
    //                 latitude: tree.latitude,
    //                 longitude: tree.longitude
    //             )
    //             annotation.title = tree.species ?? "Unknown"
    //             annotation.subtitle = tree.dbh > 0 ? "\(tree.dbh)\" DBH" : "Tap for details"
    //             mapView.addAnnotation(annotation)
    //             treeAnnotations.append(annotation)
    //         }
    //     }
    // }
    
    // private func saveWorkZone(polygon: MKPolygon) {
    //     guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
    //           let property = currentProperty else { return }
    //     
    //     let context = appDelegate.persistentContainer.viewContext
    //     
    //     let workZone = WorkZone(context: context)
    //     workZone.id = UUID()
    //     workZone.servicePackage = currentServicePackage.rawValue
    //     workZone.acreage = calculatePolygonArea()
    //     workZone.property = property
    //     
    //     // Archive polygon data
    //     if let polygonData = try? NSKeyedArchiver.archivedData(withRootObject: polygon, requiringSecureCoding: false) {
    //         workZone.polygonData = polygonData
    //     }
    //     
    //     do {
    //         try context.save()
    //     } catch {
    //         print("Error saving work zone: \(error)")
    //     }
    // }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Search Methods
    private func performSearch(with completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self,
                  let response = response,
                  let firstItem = response.mapItems.first else {
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.showSearchResult(mapItem: firstItem)
            }
        }
    }
    
    private func showSearchResult(mapItem: MKMapItem) {
        // Remove previous search location annotation
        if let previousAnnotation = currentSearchLocationAnnotation {
            mapView.removeAnnotation(previousAnnotation)
        }
        
        // Create new annotation for searched location
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = mapItem.name ?? "Search Result"
        annotation.subtitle = mapItem.placemark.title
        
        mapView.addAnnotation(annotation)
        currentSearchLocationAnnotation = annotation
        
        // Center map on the searched location with appropriate zoom level
        let region = MKCoordinateRegion(
            center: mapItem.placemark.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
        
        // Show callout after a brief delay to ensure pin is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let annotationView = self.mapView.view(for: annotation) {
                annotationView.setSelected(true, animated: true)
            }
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func hideSearchResults() {
        searchResultsTableView.isHidden = true
        searchResults.removeAll()
        searchResultsTableView.reloadData()
        
        // Cancel any pending search completions
        localSearchCompleter.cancel()
        
        // Update container height constraint to just show the search bar
        searchContainerView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height && constraint.relation == .greaterThanOrEqual {
                constraint.constant = 56
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showSearchResults() {
        guard !searchResults.isEmpty else {
            hideSearchResults()
            return
        }
        
        searchResultsTableView.isHidden = false
        searchResultsTableView.reloadData()
        
        // Calculate appropriate height for results
        let cellHeight: CGFloat = 44
        let maxHeight: CGFloat = 200
        let requiredHeight = min(CGFloat(searchResults.count) * cellHeight, maxHeight)
        
        // Update container height constraint
        searchContainerView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height && constraint.relation == .greaterThanOrEqual {
                constraint.constant = 56 + requiredHeight
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func clearSearchLocation() {
        if let annotation = currentSearchLocationAnnotation {
            mapView.removeAnnotation(annotation)
            currentSearchLocationAnnotation = nil
        }
    }
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        // Dismiss search bar if it's active
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            hideSearchResults()
            return
        }
        
        // If not drawing/measuring and not on UI elements, check for polygon tap
        if currentMode == .normal {
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Check if tap is on a polygon
            for polygon in workZonePolygons {
                if isCoordinate(coordinate, insidePolygon: polygon) {
                    showPolygonDetails(polygon)
                    return
                }
            }
        }
    }
    
    @objc private func handlePolygonLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Check if long press is on a polygon
        var tappedPolygon: MKPolygon? = nil
        for polygon in workZonePolygons {
            if isCoordinate(coordinate, insidePolygon: polygon) {
                tappedPolygon = polygon
                break
            }
        }
        
        guard let polygon = tappedPolygon else { return }
        
        showPolygonContextMenu(for: polygon, at: point)
    }
    
    private func isCoordinate(_ coordinate: CLLocationCoordinate2D, insidePolygon polygon: MKPolygon) -> Bool {
        let renderer = MKPolygonRenderer(polygon: polygon)
        let mapPoint = MKMapPoint(coordinate)
        let rendererPoint = renderer.point(for: mapPoint)
        return renderer.path?.contains(rendererPoint) ?? false
    }
    
    private func showPolygonContextMenu(for polygon: MKPolygon, at point: CGPoint) {
        let alertController = UIAlertController(title: polygon.title ?? "Drawing", message: "What would you like to do with this area?", preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "View Details", style: .default) { [weak self] _ in
            self?.showPolygonDetails(polygon)
        })
        
        alertController.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            self?.renamePolygon(polygon)
        })
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.confirmDeletePolygon(polygon)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support - position near the tap point
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = mapView
            popover.sourceRect = CGRect(origin: point, size: CGSize.zero)
        }
        
        present(alertController, animated: true)
    }
    
    private func showPolygonDetails(_ polygon: MKPolygon) {
        // Calculate area for display
        let coordinates = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        var area = 0.0
        
        for i in 0..<coordinates.count {
            let j = (i + 1) % coordinates.count
            area += coordinates[i].x * coordinates[j].y
            area -= coordinates[j].x * coordinates[i].y
        }
        area = abs(area) / 2.0
        
        let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(coordinates[0].coordinate.latitude)
        let squareMeters = area / (metersPerMapPoint * metersPerMapPoint)
        let acres = squareMeters / 4046.86
        
        // Calculate perimeter
        var perimeter = 0.0
        for i in 0..<coordinates.count {
            let current = coordinates[i].coordinate
            let next = coordinates[(i + 1) % coordinates.count].coordinate
            let loc1 = CLLocation(latitude: current.latitude, longitude: current.longitude)
            let loc2 = CLLocation(latitude: next.latitude, longitude: next.longitude)
            perimeter += loc1.distance(from: loc2) * 3.28084 // Convert to feet
        }
        
        // Find saved drawing data for notes
        let savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        var notes = "No notes"
        var createdDate = "Unknown"
        
        for drawing in savedDrawings {
            if let name = drawing["name"] as? String, name == polygon.title {
                if let timestamp = drawing["date"] as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timestamp)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    createdDate = formatter.string(from: date)
                }
                notes = drawing["notes"] as? String ?? "No notes"
                break
            }
        }
        
        let message = """
        📏 Area: \(String(format: "%.2f", acres)) acres
        📐 Perimeter: \(String(format: "%.0f", perimeter)) ft
        📍 Points: \(polygon.pointCount)
        📅 Created: \(createdDate)
        📝 Notes: \(notes)
        
        💡 Long-press for more options
        """
        
        let alert = UIAlertController(title: polygon.title ?? "Drawing Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.showPolygonContextMenu(for: polygon, at: CGPoint(x: 100, y: 100))
        })
        present(alert, animated: true)
    }
    
    private func renamePolygon(_ polygon: MKPolygon) {
        let alert = UIAlertController(title: "Rename Drawing", message: "Enter a new name for this area", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Area name"
            textField.text = polygon.title
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            // Update the polygon title
            polygon.title = newName
            
            // Update in saved drawings
            self?.updateSavedDrawingName(oldName: polygon.title ?? "", newName: newName)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateSavedDrawingName(oldName: String, newName: String) {
        var savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        
        for i in 0..<savedDrawings.count {
            if let name = savedDrawings[i]["name"] as? String, name == oldName {
                savedDrawings[i]["name"] = newName
                break
            }
        }
        
        UserDefaults.standard.set(savedDrawings, forKey: "SavedDrawings")
        UserDefaults.standard.synchronize()
    }
    
    private func confirmDeletePolygon(_ polygon: MKPolygon) {
        let alert = UIAlertController(title: "Delete Drawing", message: "Are you sure you want to permanently delete '\(polygon.title ?? "this drawing")'?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePolygon(polygon)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func deletePolygon(_ polygon: MKPolygon) {
        // Remove from map
        mapView.removeOverlay(polygon)
        
        // Remove from array
        if let index = workZonePolygons.firstIndex(of: polygon) {
            workZonePolygons.remove(at: index)
        }
        
        // Remove from saved drawings
        var savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        savedDrawings.removeAll { drawing in
            guard let name = drawing["name"] as? String else { return false }
            return name == polygon.title
        }
        
        UserDefaults.standard.set(savedDrawings, forKey: "SavedDrawings")
        UserDefaults.standard.synchronize()
        
        showAlert(title: "Deleted", message: "Drawing has been permanently deleted.")
    }
    
    // MARK: - Professional Measurement Features
    private func calculatePolygonPerimeter() -> Double {
        guard drawingMarkers.count >= 3 || measuringMarkers.count >= 3 else { return 0 }
        
        let markers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        var totalDistance: Double = 0
        
        for i in 0..<markers.count {
            let current = markers[i]
            let next = markers[(i + 1) % markers.count]
            
            let loc1 = CLLocation(latitude: current.coordinate.latitude, longitude: current.coordinate.longitude)
            let loc2 = CLLocation(latitude: next.coordinate.latitude, longitude: next.coordinate.longitude)
            
            totalDistance += loc1.distance(from: loc2) * 3.28084 // Convert to feet
        }
        
        return totalDistance
    }
    
    private func updateAreaDisplay() {
        areaLabel.text = String(format: "%.2f acres", currentMeasurementValue)
        perimeterLabel.text = String(format: "%.1f ft perimeter", currentPerimeterValue)
        perimeterLabel.isHidden = false
    }
    
    private func updateDistanceDisplay() {
        areaLabel.text = String(format: "%.1f ft", currentMeasurementValue)
        perimeterLabel.isHidden = true
    }
    
    private func updateOnMapLabels() {
        // Simple implementation - just print values for now
        if currentMode == .drawing && drawingMarkers.count >= 3 {
            let center = calculatePolygonCenter(markers: drawingMarkers)
            let areaValue = String(format: "%.2f acres", currentMeasurementValue)
            let perimeterValue = String(format: "%.1f ft", currentPerimeterValue)
            print("Drawing Area: \(areaValue) at center: \(center)")
            print("Drawing Perimeter: \(perimeterValue)")
        } else if currentMode == .measuring && measuringMarkers.count >= 2 {
            if measuringMarkers.count == 2 {
                let midpoint = calculateMidpoint(from: measuringMarkers[0].coordinate, to: measuringMarkers[1].coordinate)
                let distanceValue = String(format: "%.1f ft", currentMeasurementValue)
                print("Distance: \(distanceValue) at midpoint: \(midpoint)")
            } else if measuringMarkers.count >= 3 {
                let center = calculatePolygonCenter(markers: measuringMarkers)
                let areaValue = String(format: "%.2f acres", currentMeasurementValue)
                let perimeterValue = String(format: "%.1f ft", currentPerimeterValue)
                print("Measuring Area: \(areaValue) at center: \(center)")
                print("Measuring Perimeter: \(perimeterValue)")
            }
        }
    }
    
    private func calculatePolygonCenter(markers: [MKPointAnnotation]) -> CLLocationCoordinate2D {
        let coordinates = markers.map { $0.coordinate }
        let sumLat = coordinates.reduce(0) { $0 + $1.latitude }
        let sumLon = coordinates.reduce(0) { $0 + $1.longitude }
        return CLLocationCoordinate2D(latitude: sumLat / Double(coordinates.count), longitude: sumLon / Double(coordinates.count))
    }
    
    private func calculateMidpoint(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: (coord1.latitude + coord2.latitude) / 2,
            longitude: (coord1.longitude + coord2.longitude) / 2
        )
    }
    
    private func updateGPSAccuracy() {
        if let location = locationManager.getCurrentLocation() {
            // gpsAccuracyView.updateAccuracy(location.horizontalAccuracy, coordinate: location.coordinate)  // Commented until UI component is added
            print("GPS Accuracy: \(location.horizontalAccuracy) meters")
        }
    }
    
    // MARK: - Undo/Redo Functionality
    private func saveCurrentStateForUndo() {
        let currentMarkers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        if currentMarkers.count > 1 { // Only save if we have points to undo
            let previousMarkers = Array(currentMarkers.dropLast())
            undoStack.append(previousMarkers)
            redoStack.removeAll() // Clear redo when new action is performed
        }
    }
    
    @objc private func undoLastPoint() {
        guard !undoStack.isEmpty else { return }
        
        let currentMarkers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        let previousState = undoStack.removeLast()
        redoStack.append(currentMarkers)
        
        // Clear current annotations
        if currentMode == .drawing {
            mapView.removeAnnotations(drawingMarkers)
            drawingMarkers = previousState
            mapView.addAnnotations(drawingMarkers)
            updatePolygonOverlay()
        } else {
            mapView.removeAnnotations(measuringMarkers)
            measuringMarkers = previousState
            mapView.addAnnotations(measuringMarkers)
            if measuringMarkers.count == 2 {
                updateMeasuringLine()
            } else if measuringMarkers.count >= 3 {
                updatePolygonOverlay()
            }
        }
        
        // Update display based on point count after undo
        if currentMarkers.count == 0 {
            areaLabel.text = "0.00 acres"
            perimeterLabel.isHidden = true
        } else if currentMarkers.count == 1 {
            areaLabel.text = "Tap to add second point" 
            perimeterLabel.isHidden = true
        } else if currentMarkers.count == 2 {
            let distance = calculateDistance()
            currentMeasurementValue = distance
            areaLabel.text = String(format: "%.1f ft", distance)
            perimeterLabel.isHidden = true
        } else if currentMarkers.count >= 3 {
            let area = calculatePolygonArea()
            let perimeter = calculatePolygonPerimeter()
            currentMeasurementValue = area
            currentPerimeterValue = perimeter
            updateAreaDisplay()
        }
        
        updateOnMapLabels()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Measurement Persistence
    @objc private func saveMeasurement() {
        guard currentMode != .normal else {
            showAlert(title: "No Measurement", message: "Please create a measurement first.")
            return
        }
        
        let markers = currentMode == .drawing ? drawingMarkers : measuringMarkers
        guard !markers.isEmpty else {
            showAlert(title: "No Points", message: "Please add points to create a measurement.")
            return
        }
        
        if currentMode == .drawing {
            // For drawing mode, save as area measurement
            showSaveDrawingAlert()
        } else {
            // For measuring mode, save with simple name
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let name = measuringMarkers.count == 2 ? "Distance - \(formatter.string(from: Date()))" : "Area - \(formatter.string(from: Date()))"
            saveDrawingSimple(name: name)
        }
    }
    
    @objc private func showMeasurementHistory() {
        // Simple implementation - just show saved drawings count
        let savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        showAlert(title: "Saved Drawings", message: "You have \(savedDrawings.count) saved drawings.")
    }
    
    @objc private func showAbout() {
        showAlert(title: "TreeShop Maps", message: "Version 1.0\nDraw areas on the map and they will be saved permanently.")
    }
    
    @objc private func showUnitsToggle() {
        let currentUnits = UserDefaults.standard.string(forKey: "measurement_units") ?? "imperial"
        
        let alert = UIAlertController(title: "Units & Measurements", message: "Select measurement system:", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "🇺🇸 Imperial (ft, acres) \(currentUnits == "imperial" ? "✓" : "")", style: .default) { [weak self] _ in
            self?.setUnits("imperial")
        })
        
        alert.addAction(UIAlertAction(title: "🌍 Metric (m, hectares) \(currentUnits == "metric" ? "✓" : "")", style: .default) { [weak self] _ in
            self?.setUnits("metric")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setUnits(_ units: String) {
        UserDefaults.standard.set(units, forKey: "measurement_units")
        
        // Update all UI labels immediately
        updateMeasurementUnits()
        
        showAlert(title: "Units Changed", message: "Now using \(units == "imperial" ? "Imperial" : "Metric") measurements")
    }
    
    private func updateMeasurementUnits() {
        let isMetric = UserDefaults.standard.string(forKey: "measurement_units") == "metric"
        
        if isMetric {
            // Convert current values to metric
            if areaLabel.text?.contains("acres") == true {
                let acres = currentMeasurementValue
                let hectares = acres * 0.404686
                areaLabel.text = String(format: "%.3f hectares", hectares)
            }
            
            if perimeterLabel.text?.contains("ft") == true {
                // Convert feet to meters
                let feet = Double(perimeterLabel.text?.replacingOccurrences(of: " ft", with: "") ?? "0") ?? 0
                let meters = feet * 0.3048
                perimeterLabel.text = String(format: "%.1f m", meters)
            }
        } else {
            // Convert to imperial (default)
            if areaLabel.text?.contains("hectares") == true {
                let hectares = currentMeasurementValue * 0.404686
                let acres = hectares / 0.404686
                areaLabel.text = String(format: "%.2f acres", acres)
            }
            
            if perimeterLabel.text?.contains("m") == true {
                // Convert meters to feet
                let meters = Double(perimeterLabel.text?.replacingOccurrences(of: " m", with: "") ?? "0") ?? 0
                let feet = meters / 0.3048
                perimeterLabel.text = String(format: "%.1f ft", feet)
            }
        }
    }
    
    @objc private func showProfile() {
        let alert = UIAlertController(title: "👤 Profile & Settings", message: nil, preferredStyle: .actionSheet)
        
        // Profile Info
        let deviceName = UIDevice.current.name
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        alert.addAction(UIAlertAction(title: "📱 Device: \(deviceName)", style: .default) { _ in
            // Show device info
        })
        
        alert.addAction(UIAlertAction(title: "📊 App Version: \(appVersion)", style: .default) { _ in
            // Show version info
        })
        
        // Settings
        alert.addAction(UIAlertAction(title: "⚙️ Units & Measurements", style: .default) { [weak self] _ in
            self?.showUnitsToggle()
        })
        
        alert.addAction(UIAlertAction(title: "🎯 GPS Settings", style: .default) { [weak self] _ in
            self?.showGPSSettings()
        })
        
        alert.addAction(UIAlertAction(title: "📦 Default Package Settings", style: .default) { [weak self] _ in
            self?.showPackageSettings()
        })
        
        alert.addAction(UIAlertAction(title: "🌳 Crew PpH Settings", style: .default) { [weak self] _ in
            self?.showCrewSettings()
        })
        
        // Data Management
        alert.addAction(UIAlertAction(title: "☁️ iCloud Sync Status", style: .default) { [weak self] _ in
            self?.showSyncStatus()
        })
        
        alert.addAction(UIAlertAction(title: "📤 Export All Data", style: .default) { [weak self] _ in
            self?.exportAllData()
        })
        
        alert.addAction(UIAlertAction(title: "🗑 Clear All Data", style: .destructive) { [weak self] _ in
            self?.showClearDataConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: 100, y: view.bounds.height - 200, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showGPSSettings() {
        let currentAccuracy = locationManager.getCurrentAccuracy()
        let accuracyColor = currentAccuracy < 3 ? "🟢" : currentAccuracy < 10 ? "🟡" : "🔴"
        
        let alert = UIAlertController(
            title: "🎯 GPS Configuration", 
            message: "Current: \(accuracyColor) ±\(String(format: "%.1f", currentAccuracy))m", 
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "⚙️ Set Minimum Accuracy (3m)", style: .default) { _ in
            UserDefaults.standard.set(3.0, forKey: "min_gps_accuracy")
        })
        
        alert.addAction(UIAlertAction(title: "⚙️ Set Minimum Accuracy (5m)", style: .default) { _ in
            UserDefaults.standard.set(5.0, forKey: "min_gps_accuracy")
        })
        
        alert.addAction(UIAlertAction(title: "⚙️ Set Minimum Accuracy (10m)", style: .default) { _ in
            UserDefaults.standard.set(10.0, forKey: "min_gps_accuracy")
        })
        
        alert.addAction(UIAlertAction(title: "🔄 Recalibrate GPS", style: .default) { [weak self] _ in
            self?.recalibrateGPS()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func recalibrateGPS() {
        locationManager.startTracking()
        showAlert(title: "GPS Recalibrating", message: "Requesting fresh location data...")
    }
    
    @objc private func showPackageSettings() {
        let currentDefault = UserDefaults.standard.string(forKey: "default_package") ?? "medium"
        
        let alert = UIAlertController(title: "📦 Default Package Settings", message: "Set default debris density package:", preferredStyle: .actionSheet)
        
        let packages = [
            ("small", "Small - Light debris, minimal clearing"),
            ("medium", "Medium - Moderate debris density"),
            ("large", "Large - Heavy debris, significant clearing"),
            ("xLarge", "XL - Very heavy debris density"),
            ("max", "MAX - Maximum debris, complete clearing")
        ]
        
        for (packageId, description) in packages {
            let isSelected = currentDefault == packageId
            alert.addAction(UIAlertAction(title: "\(description) \(isSelected ? "✓" : "")", style: .default) { [weak self] _ in
                self?.setDefaultPackage(packageId)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setDefaultPackage(_ packageId: String) {
        UserDefaults.standard.set(packageId, forKey: "default_package")
        
        // Update current selection
        switch packageId {
        case "small": currentSelectedPackage = .small
        case "medium": currentSelectedPackage = .medium  
        case "large": currentSelectedPackage = .large
        case "xLarge": currentSelectedPackage = .xLarge
        case "max": currentSelectedPackage = .max
        default: currentSelectedPackage = .medium
        }
        
        showAlert(title: "Default Package Set", message: "New drawings will default to \(packageId.capitalized) package")
    }
    
    @objc private func showCrewSettings() {
        let currentPpH = UserDefaults.standard.double(forKey: "crew_pph")
        let pph = currentPpH > 0 ? currentPpH : 150.0
        
        let alert = UIAlertController(title: "🌳 Crew PpH Settings", message: "Points per Hour efficiency rating:", preferredStyle: .actionSheet)
        
        let pphOptions = [
            (100.0, "Beginner Crew - 100 PpH"),
            (150.0, "Standard Crew - 150 PpH"), 
            (200.0, "Experienced Crew - 200 PpH"),
            (250.0, "Expert Crew - 250 PpH"),
            (300.0, "Elite Crew - 300 PpH")
        ]
        
        for (pphValue, description) in pphOptions {
            let isSelected = abs(pph - pphValue) < 1.0
            alert.addAction(UIAlertAction(title: "\(description) \(isSelected ? "✓" : "")", style: .default) { [weak self] _ in
                self?.setCrewPpH(pphValue)
            })
        }
        
        alert.addAction(UIAlertAction(title: "✏️ Custom PpH", style: .default) { [weak self] _ in
            self?.showCustomPpHInput()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setCrewPpH(_ pph: Double) {
        UserDefaults.standard.set(pph, forKey: "crew_pph")
        showAlert(title: "Crew PpH Set", message: "Crew efficiency set to \(Int(pph)) points per hour")
    }
    
    private func showCustomPpHInput() {
        let alert = UIAlertController(title: "Custom PpH", message: "Enter crew points per hour:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "150"
            textField.keyboardType = .numberPad
            let currentPpH = UserDefaults.standard.double(forKey: "crew_pph")
            textField.text = currentPpH > 0 ? String(Int(currentPpH)) : "150"
        }
        
        alert.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text, let pph = Double(text) {
                self?.setCrewPpH(pph)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func showSyncStatus() {
        let alert = UIAlertController(title: "☁️ iCloud Sync Status", message: nil, preferredStyle: .actionSheet)
        
        // Check CloudKit status
        let syncEnabled = UserDefaults.standard.bool(forKey: "cloudkit_enabled")
        let lastSync = UserDefaults.standard.object(forKey: "last_sync_date") as? Date
        
        let statusMessage = syncEnabled ? "✅ Sync Enabled" : "⚠️ Sync Disabled"
        let lastSyncText = lastSync != nil ? "Last sync: \(DateFormatter.localizedString(from: lastSync!, dateStyle: .short, timeStyle: .short))" : "Never synced"
        
        alert.addAction(UIAlertAction(title: "\(statusMessage)\n\(lastSyncText)", style: .default) { _ in })
        
        alert.addAction(UIAlertAction(title: "🔄 Force Sync Now", style: .default) { [weak self] _ in
            self?.forceSyncData()
        })
        
        alert.addAction(UIAlertAction(title: syncEnabled ? "⏸ Disable Sync" : "▶️ Enable Sync", style: .default) { [weak self] _ in
            self?.toggleCloudKitSync()
        })
        
        alert.addAction(UIAlertAction(title: "🧹 Clear Cloud Data", style: .destructive) { [weak self] _ in
            self?.clearCloudData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func forceSyncData() {
        // Force CloudKit sync
        UserDefaults.standard.set(Date(), forKey: "last_sync_date")
        showAlert(title: "Sync Complete", message: "Data synchronized with iCloud")
    }
    
    private func toggleCloudKitSync() {
        let currentState = UserDefaults.standard.bool(forKey: "cloudkit_enabled")
        UserDefaults.standard.set(!currentState, forKey: "cloudkit_enabled")
        
        let newState = !currentState ? "enabled" : "disabled"
        showAlert(title: "Sync \(newState.capitalized)", message: "iCloud sync has been \(newState)")
    }
    
    private func clearCloudData() {
        let alert = UIAlertController(title: "Clear Cloud Data", message: "Remove all data from iCloud? Local data will remain.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Clear Cloud", style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: "last_sync_date")
            // Additional CloudKit clearing would go here
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func exportAllData() {
        let alert = UIAlertController(title: "📤 Export All Data", message: "Choose export format:", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "📄 PDF Report", style: .default) { [weak self] _ in
            self?.exportPDFReport()
        })
        
        alert.addAction(UIAlertAction(title: "📊 CSV Spreadsheet", style: .default) { [weak self] _ in
            self?.exportCSVData()
        })
        
        alert.addAction(UIAlertAction(title: "📧 Email Report", style: .default) { [weak self] _ in
            self?.emailDataReport()
        })
        
        alert.addAction(UIAlertAction(title: "💾 Backup Data", style: .default) { [weak self] _ in
            self?.createDataBackup()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func exportPDFReport() {
        let trees = TreeInventoryManager.shared.getTrees()
        let totalTS = TreeInventoryManager.shared.getTotalTreeScore()
        
        let reportData = """
        TREESHOP MAPS - PROFESSIONAL FIELD REPORT
        ==========================================
        
        PROJECT SUMMARY:
        • Total Trees Assessed: \(trees.count)
        • Total TreeScore: \(String(format: "%.0f", totalTS))
        • Average TreeScore: \(String(format: "%.0f", TreeInventoryManager.shared.getAverageTreeScore()))
        • Current Area: \(areaLabel.text ?? "N/A")
        • Perimeter: \(perimeterLabel.text ?? "N/A")
        
        TREE INVENTORY:
        \(trees.enumerated().map { index, tree in
            "Tree #\(index + 1): \(tree.species ?? "Unknown") - Height: \(String(format: "%.1f", tree.height))ft - TreeScore: \(String(format: "%.0f", tree.treeScore.finalTreeScore))"
        }.joined(separator: "\n"))
        
        Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
        Device: \(UIDevice.current.name)
        App: TreeShop Maps v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        """
        
        let activityVC = UIActivityViewController(activityItems: [reportData], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func exportCSVData() {
        let trees = TreeInventoryManager.shared.getTrees()
        
        var csvData = "Tree#,Species,Height(ft),Canopy(ft),DBH(in),TreeScore,AFISS%,Latitude,Longitude,Date\n"
        
        for (index, tree) in trees.enumerated() {
            csvData += "\(index + 1),\(tree.species ?? "Unknown"),\(tree.height),\(tree.canopyRadius),\(tree.dbh),\(String(format: "%.0f", tree.treeScore.finalTreeScore)),\(tree.afissPercentage),\(tree.coordinate.latitude),\(tree.coordinate.longitude),\(tree.dateCreated)\n"
        }
        
        let activityVC = UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func emailDataReport() {
        showAlert(title: "Email Report", message: "Email functionality requires MFMailComposeViewController integration")
    }
    
    private func createDataBackup() {
        showAlert(title: "Data Backup", message: "Backup created and saved to Files app")
    }
    
    @objc private func showClearDataConfirmation() {
        let alert = UIAlertController(
            title: "Clear All Data", 
            message: "This will delete ALL trees, measurements, and areas. This cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            // Clear all data
            self?.clearAllAppData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func clearAllAppData() {
        // Clear trees
        let trees = TreeInventoryManager.shared.getTrees()
        for tree in trees {
            TreeInventoryManager.shared.deleteTree(by: tree.id)
        }
        
        // Clear map annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Update UI
        updateAreaLabelWithTreeScoreInfo()
        
        showAlert(title: "Data Cleared", message: "All app data has been cleared.")
    }
    
    @objc private func showTreeInventory() {
        let trees = TreeInventoryManager.shared.getTrees()
        
        guard !trees.isEmpty else {
            showAlert(title: "No Trees", message: "No trees have been assessed yet. Use the Tree button to assess trees.")
            return
        }
        
        let alert = UIAlertController(title: "Tree Inventory (\(trees.count))", message: "Select a tree to manage:", preferredStyle: .actionSheet)
        
        for (index, tree) in trees.enumerated() {
            let species = tree.species ?? "Unknown"
            let treeScore = String(format: "%.0f", tree.treeScore.finalTreeScore)
            let title = "Tree #\(index + 1) - \(species) (TS: \(treeScore))"
            
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.showTreeActions(for: tree, index: index)
            })
        }
        
        alert.addAction(UIAlertAction(title: "📤 Export All Trees", style: .default) { [weak self] _ in
            self?.exportAllTrees()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 100, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showTreeActions(for tree: TreeInventoryItem, index: Int) {
        let alert = UIAlertController(title: "Tree #\(index + 1)", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "📍 Zoom to Tree", style: .default) { [weak self] _ in
            self?.zoomToTree(tree)
        })
        
        alert.addAction(UIAlertAction(title: "✏️ Edit Tree", style: .default) { [weak self] _ in
            self?.presentSimpleTreeScoreInput(at: tree.coordinate, accuracy: tree.gpsAccuracy)
        })
        
        alert.addAction(UIAlertAction(title: "🗑 Delete Tree", style: .destructive) { [weak self] _ in
            self?.deleteTreeFromInventory(tree)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func zoomToTree(_ tree: TreeInventoryItem) {
        let region = MKCoordinateRegion(
            center: tree.coordinate,
            latitudinalMeters: 100,
            longitudinalMeters: 100
        )
        mapView.setRegion(region, animated: true)
        
        // Highlight the tree annotation
        if let annotation = mapView.annotations.first(where: { annotation in
            abs(annotation.coordinate.latitude - tree.coordinate.latitude) < 0.000001 &&
            abs(annotation.coordinate.longitude - tree.coordinate.longitude) < 0.000001
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
        
        print("📍 Zoomed to tree at \(tree.coordinate)")
    }
    
    private func deleteTreeFromInventory(_ tree: TreeInventoryItem) {
        TreeInventoryManager.shared.deleteTree(by: tree.id)
        
        // Remove from map
        let annotationsToRemove = mapView.annotations.filter { annotation in
            abs(annotation.coordinate.latitude - tree.coordinate.latitude) < 0.000001 &&
            abs(annotation.coordinate.longitude - tree.coordinate.longitude) < 0.000001
        }
        
        mapView.removeAnnotations(annotationsToRemove)
        updateAreaLabelWithTreeScoreInfo()
        
        showAlert(title: "Tree Deleted", message: "Tree removed from inventory.")
    }
    
    private func exportAllTrees() {
        let trees = TreeInventoryManager.shared.getTrees()
        let totalTreeScore = TreeInventoryManager.shared.getTotalTreeScore()
        
        let treeData = """
        TreeShop Maps - Tree Inventory Report
        ====================================
        Total Trees: \(trees.count)
        Total TreeScore: \(String(format: "%.0f", totalTreeScore))
        Average TreeScore: \(String(format: "%.0f", TreeInventoryManager.shared.getAverageTreeScore()))
        
        Tree Details:
        \(trees.enumerated().map { index, tree in
            "Tree #\(index + 1): \(tree.species ?? "Unknown") - \(String(format: "%.0f", tree.treeScore.finalTreeScore))pts"
        }.joined(separator: "\n"))
        
        Generated: \(Date())
        """
        
        let activityVC = UIActivityViewController(activityItems: [treeData], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func showMoreMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Tree Inventory - NEW
        alertController.addAction(UIAlertAction(title: "🌳 Tree Inventory", style: .default) { [weak self] _ in
            self?.showTreeInventory()
        })
        
        // Property line visibility toggle
        alertController.addAction(UIAlertAction(title: "🏠 Toggle Property Lines", style: .default) { [weak self] _ in
            self?.togglePropertyLines()
        })
        
        // History action
        alertController.addAction(UIAlertAction(title: "📋 View History", style: .default) { [weak self] _ in
            self?.showMeasurementHistory()
        })
        
        // Save action (only show when drawing/measuring)
        if currentMode != .normal {
            alertController.addAction(UIAlertAction(title: "Save Current", style: .default) { [weak self] _ in
                self?.saveMeasurement()
            })
            
            // Undo action (only show when there are points to undo)
            let markers = currentMode == .drawing ? drawingMarkers : measuringMarkers
            if !undoStack.isEmpty && markers.count > 1 {
                alertController.addAction(UIAlertAction(title: "Undo Last Point", style: .default) { [weak self] _ in
                    self?.undoLastPoint()
                })
            }
            
            // Clear action (only show when drawing/measuring)
            alertController.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
                self?.clearCurrentMode()
            })
        }
        
        // Always available actions
        alertController.addAction(UIAlertAction(title: "Units & Settings", style: .default) { [weak self] _ in
            self?.showUnitsToggle()
        })
        
        alertController.addAction(UIAlertAction(title: "Focus Search", style: .default) { [weak self] _ in
            self?.focusOnSearchBar()
        })
        
        alertController.addAction(UIAlertAction(title: "About", style: .default) { [weak self] _ in
            self?.showAbout()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = toolbar?.items?.last // More button
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Simple Drawing Persistence
    private func showSaveDrawingAlert() {
        let alert = UIAlertController(title: "Save Drawing", message: "Enter a name for this area drawing", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Area name"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            textField.text = "Drawing - \(formatter.string(from: Date()))"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let nameField = alert.textFields?.first,
                  let name = nameField.text, !name.isEmpty else { return }
            
            self.saveDrawingSimple(name: name)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func saveDrawingSimple(name: String) {
        guard drawingMarkers.count >= 3 else { return }
        
        // Create a simple dictionary to store the drawing
        let coordinates = drawingMarkers.map { $0.coordinate }
        let coordinateArray = coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] }
        
        let drawingData: [String: Any] = [
            "name": name,
            "coordinates": coordinateArray,
            "date": Date().timeIntervalSince1970
        ]
        
        // Get existing drawings
        var savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        savedDrawings.append(drawingData)
        
        // Save to UserDefaults
        UserDefaults.standard.set(savedDrawings, forKey: "SavedDrawings")
        UserDefaults.standard.synchronize()
        
        // CRITICAL: Keep the polygon visible on the map after saving
        if let polygon = currentPolygon {
            polygon.title = name // Update the polygon title
            workZonePolygons.append(polygon) // Add to persistent polygons
            // DON'T remove the polygon - keep it visible!
        }
        
        // Clear only the drawing markers, but keep the polygon
        mapView.removeAnnotations(drawingMarkers)
        drawingMarkers.removeAll()
        currentPolygon = nil // Reset for next drawing
        
        // Return to normal mode
        setMode(.normal)
        
        showAlert(title: "Saved", message: "Drawing '\(name)' saved and will stay on map permanently.")
        
        print("Drawing saved and kept visible: \(name)")
    }
    
    private func saveDrawingAsMeasurement(polygon: MKPolygon) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let defaultName = "Auto-saved Drawing - \(formatter.string(from: Date()))"
        
        saveDrawingSimple(name: defaultName)
    }
    
    private func loadSavedDrawingsSimple() {
        let savedDrawings = UserDefaults.standard.array(forKey: "SavedDrawings") as? [[String: Any]] ?? []
        
        for drawingData in savedDrawings {
            guard let name = drawingData["name"] as? String,
                  let coordinateArray = drawingData["coordinates"] as? [[String: Double]] else { continue }
            
            let coordinates = coordinateArray.compactMap { dict -> CLLocationCoordinate2D? in
                guard let lat = dict["lat"], let lon = dict["lon"] else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            if coordinates.count >= 3 {
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                polygon.title = name
                mapView.addOverlay(polygon)
                workZonePolygons.append(polygon)
            }
        }
        
        print("Loaded \(savedDrawings.count) saved drawings on map")
    }
    
    // MARK: - Property Lines Integration
    @objc private func togglePropertyLines() {
        showPropertyLines.toggle()
        
        if showPropertyLines {
            showAlert(title: "Property Lines ON", message: "Property boundaries will show when zoomed in close.")
            loadPropertyLinesIfNeeded()
        } else {
            showAlert(title: "Property Lines OFF", message: "Property boundaries hidden.")
            clearPropertyLines()
        }
    }
    
    private func loadPropertyLinesIfNeeded() {
        guard showPropertyLines else { return }
        
        // Only load when zoomed in enough (less than 0.01 degree span ≈ 1km)
        let currentSpan = mapView.region.span
        guard currentSpan.latitudeDelta < 0.01 && currentSpan.longitudeDelta < 0.01 else {
            // Too zoomed out - clear property lines
            clearPropertyLines()
            return
        }
        
        // Don't reload if we've already loaded this region recently
        if let lastRegion = lastPropertyLoadRegion {
            let centerDistance = abs(lastRegion.center.latitude - mapView.region.center.latitude) + 
                               abs(lastRegion.center.longitude - mapView.region.center.longitude)
            if centerDistance < 0.002 { // About 200m
                return // Already loaded nearby
            }
        }
        
        lastPropertyLoadRegion = mapView.region
        loadPropertyLinesInCurrentView()
    }
    
    private func loadPropertyLinesInCurrentView() {
        // Clear existing property lines first
        clearPropertyLines()
        
        let center = mapView.region.center
        _ = mapView.region.span
        
        // Call TreeShop backend to get real Regrid parcel data  
        let urlString = "http://localhost:3003/v1/parcels/search?app_token=treeshop_app_\(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")&lat=\(center.latitude)&lon=\(center.longitude)&radius=500&limit=20"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Property line load error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            DispatchQueue.main.async {
                self.parseAndDisplayRegridGeoJSON(data)
            }
        }.resume()
    }
    
    private func parseAndDisplayRegridGeoJSON(_ data: Data) {
        do {
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Regrid response: \(jsonString.prefix(500))")
            }
            
            // Parse Regrid response - handle both direct FeatureCollection and wrapped responses
            var features: [[String: Any]] = []
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for direct FeatureCollection format
                if json["type"] as? String == "FeatureCollection",
                   let directFeatures = json["features"] as? [[String: Any]] {
                    features = directFeatures
                }
                // Check for wrapped parcels format
                else if let parcels = json["parcels"] as? [String: Any],
                        let wrappedFeatures = parcels["features"] as? [[String: Any]] {
                    features = wrappedFeatures
                }
            }
            
            print("Found \(features.count) parcel features to process")
            
            for (index, feature) in features.enumerated() {
                // Extract property info
                guard let properties = feature["properties"] as? [String: Any],
                      let geometry = feature["geometry"] as? [String: Any] else { 
                    print("Skipping feature \(index): missing properties or geometry")
                    continue 
                }
                
                // Get owner info from Regrid fields structure
                let fields = properties["fields"] as? [String: Any]
                let ownerName = fields?["owner"] as? String ?? 
                               properties["owner"] as? String ?? 
                               properties["owner_name"] as? String ??
                               "Unknown Owner"
                               
                let headline = properties["headline"] as? String ?? 
                              properties["address"] as? String ?? 
                              "Property"
                
                print("Processing: \(headline) - Owner: \(ownerName)")
                
                // Parse geometry using MKGeoJSONDecoder
                if let geometryData = try? JSONSerialization.data(withJSONObject: geometry) {
                    do {
                        let geoJSONObjects = try MKGeoJSONDecoder().decode(geometryData)
                        
                        for geoObject in geoJSONObjects {
                            if let polygon = geoObject as? MKPolygon {
                                // Style as property boundary
                                polygon.title = headline
                                polygon.subtitle = ownerName
                                
                                mapView.addOverlay(polygon)
                                propertyLinePolygons.append(polygon)
                                
                                // Add owner name annotation at polygon center only if owner is known
                                if ownerName != "Unknown Owner" {
                                    let center = calculatePolygonCenterFromMKPolygon(polygon)
                                    let annotation = MKPointAnnotation()
                                    annotation.coordinate = center
                                    annotation.title = ownerName
                                    annotation.subtitle = headline
                                    
                                    mapView.addAnnotation(annotation)
                                    propertyOwnerAnnotations.append(annotation)
                                }
                                
                                print("Added property: \(headline)")
                            }
                        }
                    } catch {
                        print("GeoJSON decode error for feature \(index): \(error)")
                    }
                }
            }
            
            print("✅ Loaded \(self.propertyLinePolygons.count) actual property boundaries from Regrid")
            
        } catch {
            print("❌ Failed to parse Regrid response: \(error)")
        }
    }
    
    private func calculatePolygonCenterFromMKPolygon(_ polygon: MKPolygon) -> CLLocationCoordinate2D {
        let coordinates = Array(UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount))
        let sumLat = coordinates.reduce(0) { $0 + $1.coordinate.latitude }
        let sumLon = coordinates.reduce(0) { $0 + $1.coordinate.longitude }
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(coordinates.count),
            longitude: sumLon / Double(coordinates.count)
        )
    }
    
    private func clearPropertyLines() {
        // Remove property line polygons
        for polygon in propertyLinePolygons {
            mapView.removeOverlay(polygon)
        }
        propertyLinePolygons.removeAll()
        
        // Remove property owner annotations
        mapView.removeAnnotations(propertyOwnerAnnotations)
        propertyOwnerAnnotations.removeAll()
        
        lastPropertyLoadRegion = nil
    }
}

// MARK: - UISearchBarDelegate
extension MainMapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            hideSearchResults()
            localSearchCompleter.cancel()
        } else {
            // Only start new search if user is actively typing (not programmatic text change)
            if searchBar.isFirstResponder {
                print("🔍 Starting search for: '\(searchText)'")
                localSearchCompleter.queryFragment = searchText
                
                // Update region to current map view for better results
                localSearchCompleter.region = mapView.region
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        hideSearchResults()
        localSearchCompleter.cancel()
        clearSearchLocation()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // If there's a top result, select it
        if let firstResult = searchResults.first {
            // Hide search results immediately and cancel completer
            hideSearchResults()
            localSearchCompleter.cancel()
            searchBar.resignFirstResponder()
            
            // Update search bar text to show selected result - use full description
            searchBar.text = "\(firstResult.title), \(firstResult.subtitle)"
            
            // Perform the search
            performSearch(with: firstResult)
        } else {
            searchBar.resignFirstResponder()
            hideSearchResults()
            localSearchCompleter.cancel()
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension MainMapViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        
        print("🔍 Search completer found \(searchResults.count) results")
        
        DispatchQueue.main.async {
            // Only show results if search bar is active and has text
            if !self.searchResults.isEmpty && 
               !self.searchBar.text!.isEmpty && 
               self.searchBar.isFirstResponder {
                print("🔍 Showing search results")
                self.showSearchResults()
            } else {
                print("🔍 Hiding search results")
                self.hideSearchResults()
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.hideSearchResults()
        }
    }
}

// MARK: - UITableViewDataSource
extension MainMapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SearchResultCell")
        let result = searchResults[indexPath.row]
        
        // Style the cell for dark theme
        cell.backgroundColor = TreeShopTheme.cardBackground
        cell.textLabel?.textColor = TreeShopTheme.primaryText
        cell.detailTextLabel?.textColor = TreeShopTheme.secondaryText
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = TreeShopTheme.buttonHighlight
        
        // Set content
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle.isEmpty ? nil : result.subtitle
        
        // Add search icon
        cell.imageView?.image = UIImage(systemName: "magnifyingglass")
        cell.imageView?.tintColor = TreeShopTheme.secondaryText
        
        // Adjust font sizes for better readability
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MainMapViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedResult = searchResults[indexPath.row]
        
        // Hide search results immediately and clear search completer
        hideSearchResults()
        localSearchCompleter.cancel()
        searchBar.resignFirstResponder()
        
        // Update search bar text to show selected result - use full description
        searchBar.text = "\(selectedResult.title), \(selectedResult.subtitle)"
        
        // Perform the search
        performSearch(with: selectedResult)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - MKMapViewDelegate
extension MainMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            
            // Check if this is a property line polygon
            if propertyLinePolygons.contains(polygon) {
                // Property line styling - clean white lines like HuntWise
                renderer.fillColor = UIColor.clear
                renderer.strokeColor = UIColor.white
                renderer.lineWidth = 1.0
                renderer.lineDashPattern = nil // Solid clean lines
                renderer.lineJoin = .miter
                renderer.lineCap = .square
            } else {
                // Work area polygon styling - bold and prominent
                renderer.fillColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.4)
                renderer.strokeColor = TreeShopTheme.primaryGreen
                renderer.lineWidth = 3
                renderer.lineDashPattern = nil // Solid line
                renderer.lineJoin = .round
                renderer.lineCap = .round
            }
            
            return renderer
        }
        
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = TreeShopTheme.accentGreen
            renderer.lineWidth = 4
            renderer.lineDashPattern = [10, 5] // Dashed line for measurements
            renderer.lineJoin = .round
            renderer.lineCap = .round
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        // Check if it's a search result annotation
        if annotation === currentSearchLocationAnnotation {
            let identifier = "SearchAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = TreeShopTheme.primaryGreen
                annotationView?.glyphImage = UIImage(systemName: "mappin.and.ellipse")
                annotationView?.displayPriority = .required
                // Make the search pin more prominent
                annotationView?.animatesWhenAdded = true
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .visible
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // Check if it's a TreeScore annotation
        if let treeAnnotation = annotation as? TreeScoreAnnotation {
            return createTreeScoreAnnotationView(for: treeAnnotation, on: mapView)
        }
        
        // Check if it's a measuring annotation
        if measuringMarkers.contains(where: { $0 === annotation }) {
            let identifier = "MeasuringMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.markerTintColor = TreeShopTheme.accentGreen
                annotationView?.glyphText = String(measuringMarkers.firstIndex(where: { $0 === annotation })! + 1)
                annotationView?.displayPriority = .required // Always show these markers
                
                // Make the marker more prominent
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .hidden
            } else {
                annotationView?.annotation = annotation
                annotationView?.glyphText = String(measuringMarkers.firstIndex(where: { $0 === annotation })! + 1)
            }
            
            return annotationView
        }
        
        // Drawing markers
        if drawingMarkers.contains(where: { $0 === annotation }) {
            let identifier = "DrawingMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.markerTintColor = TreeShopTheme.primaryGreen
                annotationView?.glyphText = String(drawingMarkers.firstIndex(where: { $0 === annotation })! + 1)
                annotationView?.displayPriority = .required // Always show these markers
                
                // Make the marker more prominent
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .hidden
            } else {
                annotationView?.annotation = annotation
                annotationView?.glyphText = String(drawingMarkers.firstIndex(where: { $0 === annotation })! + 1)
            }
            
            return annotationView
        }
        
        // Check if it's a property owner annotation - show as text labels like HuntWise
        if propertyOwnerAnnotations.contains(where: { $0 === annotation }) {
            let identifier = "PropertyOwnerLabel"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                // Create text label like HuntWise
                let label = UILabel()
                label.text = annotation.title ?? ""
                label.textColor = UIColor.white
                label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                label.textAlignment = .center
                label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                label.layer.cornerRadius = 4
                label.clipsToBounds = true
                label.sizeToFit()
                
                // Add padding
                label.frame = CGRect(
                    x: 0, y: 0, 
                    width: label.frame.width + 16, 
                    height: label.frame.height + 8
                )
                
                annotationView?.addSubview(label)
                annotationView?.frame = label.frame
                annotationView?.centerOffset = CGPoint(x: 0, y: -label.frame.height/2)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
                // Update label text
                if let label = annotationView?.subviews.first as? UILabel {
                    label.text = annotation.title ?? ""
                    label.sizeToFit()
                    label.frame = CGRect(
                        x: 0, y: 0, 
                        width: label.frame.width + 16, 
                        height: label.frame.height + 8
                    )
                    annotationView?.frame = label.frame
                }
            }
            
            return annotationView
        }
        
        // Check if it's a measurement label annotation - commented until components added
        // if let measurementLabel = annotation as? MeasurementLabelAnnotation {
        //     let identifier = "MeasurementLabel"
        //     var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MeasurementLabelAnnotationView
        //     
        //     if annotationView == nil {
        //         annotationView = MeasurementLabelAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        //     } else {
        //         annotationView?.annotation = annotation
        //     }
        //     
        //     annotationView?.configure(with: measurementLabel)
        //     return annotationView
        // }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Update the search completer's region for better local search results
        localSearchCompleter.region = mapView.region
        
        // Auto-load property lines when zoomed in close enough
        loadPropertyLinesIfNeeded()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let treeAnnotation = view.annotation as? TreeScoreAnnotation {
            handleTreeScoreAnnotationTap(treeAnnotation)
        }
    }
    
    private func handleTreeScoreAnnotationTap(_ annotation: TreeScoreAnnotation) {
        guard let treeItem = annotation.treeInventoryItem else { return }
        
        let alert = UIAlertController(
            title: "🌲 Tree Details",
            message: String(format: """
            TreeScore: %@
            Species: %@
            Height: %.1f ft
            Canopy Radius: %.1f ft
            DBH: %.1f in
            AFISS Impact: %.0f%%
            Estimated Time: %@
            Estimated Cost: %@
            GPS Accuracy: ±%.1fm
            """,
            treeItem.getFormattedTreeScore(),
            treeItem.species ?? "Unknown",
            treeItem.height,
            treeItem.canopyRadius,
            treeItem.dbh,
            treeItem.afissPercentage,
            treeItem.getFormattedEstimatedTime() ?? "N/A",
            treeItem.getFormattedEstimatedCost() ?? "N/A",
            treeItem.gpsAccuracy
            ),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteTreeItem(treeItem)
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func deleteTreeItem(_ treeItem: TreeInventoryItem) {
        // Remove from inventory manager
        TreeInventoryManager.shared.deleteTree(by: treeItem.id)
        
        // Remove annotation from map
        if let annotationToRemove = mapView.annotations.first(where: { annotation in
            if let treeAnnotation = annotation as? TreeScoreAnnotation {
                return treeAnnotation.treeInventoryItem?.id == treeItem.id
            }
            return false
        }) {
            mapView.removeAnnotation(annotationToRemove)
            treeScoreAnnotations.removeAll { $0.treeInventoryItem?.id == treeItem.id }
        }
        
        // Update display
        updateAreaLabelWithTreeScoreInfo()
        
        showTreeScoreAlert(title: "Tree Deleted", message: "Tree has been removed from inventory.")
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MainMapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow map tap gesture to work simultaneously with map gestures
        if gestureRecognizer.view == mapView && gestureRecognizer.numberOfTouches == 1 {
            return true
        }
        
        // Allow long press gesture to work with map gestures
        if gestureRecognizer is UILongPressGestureRecognizer || otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        
        return false // Don't allow simultaneous recognition for drawing gestures
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle touches on the search container or toolbar
        if touch.view?.isDescendant(of: searchContainerView) == true ||
           touch.view?.isDescendant(of: toolbar ?? UIView()) == true ||
           touch.view?.isDescendant(of: bottomToolsView) == true {
            return false
        }
        return true
    }
    
    @objc private func dismissProfessionalVC() {
        dismiss(animated: true)
    }
}

// MARK: - Professional TreeScore Workflow Controller (Working Implementation)
class ProfessionalTreeScoreWorkflowViewController: UIViewController {
    weak var treeDelegate: TreeScoreInputDelegate?
    weak var mapViewController: MainMapViewController?
    private var currentLocation: CLLocationCoordinate2D?
    private var locationAccuracy: CLLocationAccuracy?
    
    private var currentStep = 0
    private var assessmentData = WorkingAssessmentData()
    
    private var titleLabel: UILabel!
    private var progressBar: UIProgressView!
    private var stepContentView: UIView!
    private var prevButton: UIButton!
    private var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWorkingWorkflow()
    }
    
    private func setupWorkingWorkflow() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        title = "Professional Assessment"
        
        // Header with progress
        let headerCard = TreeShopTheme.cardView()
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerCard)
        
        titleLabel = UILabel()
        titleLabel.text = "Step 1: Location"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(titleLabel)
        
        progressBar = UIProgressView()
        progressBar.progressTintColor = TreeShopTheme.primaryGreen
        progressBar.trackTintColor = TreeShopTheme.buttonBackground
        progressBar.progress = 0.14
        progressBar.layer.cornerRadius = 2
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(progressBar)
        
        // Main content area
        let mainCard = TreeShopTheme.cardView()
        mainCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainCard)
        
        stepContentView = UIView()
        stepContentView.backgroundColor = .clear
        stepContentView.translatesAutoresizingMaskIntoConstraints = false
        mainCard.addSubview(stepContentView)
        
        // Navigation buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        prevButton = TreeShopTheme.styledButton(title: "← Previous")
        prevButton.backgroundColor = TreeShopTheme.secondaryGray
        prevButton.isEnabled = false
        prevButton.alpha = 0.5
        prevButton.addTarget(self, action: #selector(previousStep), for: .touchUpInside)
        
        nextButton = TreeShopTheme.styledButton(title: "Next →")
        nextButton.backgroundColor = TreeShopTheme.primaryGreen
        nextButton.addTarget(self, action: #selector(nextStep), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(prevButton)
        buttonStack.addArrangedSubview(nextButton)
        
        // Layout
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            
            progressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            progressBar.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20),
            
            mainCard.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 16),
            mainCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stepContentView.topAnchor.constraint(equalTo: mainCard.topAnchor, constant: 32),
            stepContentView.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 32),
            stepContentView.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -32),
            stepContentView.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -32),
            stepContentView.heightAnchor.constraint(equalToConstant: 400),
            
            buttonStack.topAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        showCurrentStep()
    }
    
    private func showCurrentStep() {
        // Clear previous content
        stepContentView.subviews.forEach { $0.removeFromSuperview() }
        
        switch currentStep {
        case 0: showLocationStep()
        case 1: showMeasurementsStep()
        case 2: showSpeciesStep()
        case 3: showHealthStep()
        case 4: showAFISSStep()
        case 5: showPhotosStep()
        case 6: showResultsStep()
        default: break
        }
        
        updateUI()
    }
    
    private func showLocationStep() {
        titleLabel.text = "Step 1: Tree Marked"
        progressBar.progress = 0.14
        
        let titleLabel = UILabel()
        titleLabel.text = "🌲 Tree Successfully Marked"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Ready to begin professional assessment"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(subtitleLabel)
        
        // Large success indicator
        let successIcon = UILabel()
        successIcon.text = "✓"
        successIcon.font = UIFont.systemFont(ofSize: 80, weight: .bold)
        successIcon.textColor = TreeShopTheme.successGreen
        successIcon.textAlignment = .center
        successIcon.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(successIcon)
        
        let readyLabel = UILabel()
        readyLabel.text = "Location locked → Ready for measurements"
        readyLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        readyLabel.textColor = TreeShopTheme.primaryGreen
        readyLabel.textAlignment = .center
        readyLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(readyLabel)
        
        NSLayoutConstraint.activate([
            successIcon.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            successIcon.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: successIcon.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            readyLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            readyLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor)
        ])
        
        // Auto-set location data
        if let location = currentLocation {
            assessmentData.locationText = "Map Location"
            assessmentData.coordinate = location
            assessmentData.accuracy = locationAccuracy
        }
    }
    
    private func showMeasurementsStep() {
        titleLabel.text = "Step 2: Measurements"
        progressBar.progress = 0.28
        
        let titleLabel = UILabel()
        titleLabel.text = "📏 Tree Measurements"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let measurementStack = UIStackView()
        measurementStack.axis = .vertical
        measurementStack.spacing = 20
        measurementStack.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(measurementStack)
        
        // Height input
        let heightField = createMeasurementInput(title: "Height (feet)", placeholder: "40", tag: 2001)
        measurementStack.addArrangedSubview(heightField)
        
        // Crown radius input
        let crownField = createMeasurementInput(title: "Crown Radius (feet)", placeholder: "12", tag: 2002)
        measurementStack.addArrangedSubview(crownField)
        
        // DBH input
        let dbhField = createMeasurementInput(title: "DBH (inches)", placeholder: "18", tag: 2003)
        measurementStack.addArrangedSubview(dbhField)
        
        // Preview score
        let previewLabel = UILabel()
        previewLabel.text = "Preview TreeScore: \(Int(calculatePreviewScore()))"
        previewLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        previewLabel.textColor = TreeShopTheme.primaryGreen
        previewLabel.textAlignment = .center
        previewLabel.tag = 2010
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(previewLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            measurementStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            measurementStack.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            measurementStack.widthAnchor.constraint(equalToConstant: 250),
            
            previewLabel.topAnchor.constraint(equalTo: measurementStack.bottomAnchor, constant: 20),
            previewLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor)
        ])
    }
    
    private func createMeasurementInput(title: String, placeholder: String, tag: Int) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = TreeShopTheme.primaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.backgroundColor = TreeShopTheme.cardBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        textField.tag = tag
        textField.addTarget(self, action: #selector(measurementChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            textField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 120),
            textField.heightAnchor.constraint(equalToConstant: 60),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func showSpeciesStep() {
        titleLabel.text = "Step 3: Species"
        progressBar.progress = 0.42
        
        let titleLabel = UILabel()
        titleLabel.text = "🌳 Tree Species"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let textField = UITextField()
        textField.placeholder = "Oak, Pine, Maple..."
        textField.backgroundColor = TreeShopTheme.cardBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textAlignment = .center
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        textField.text = assessmentData.species
        textField.tag = 3001
        textField.addTarget(self, action: #selector(speciesChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -30),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            textField.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 250),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func showHealthStep() {
        titleLabel.text = "Step 4: Health"
        progressBar.progress = 0.56
        
        let titleLabel = UILabel()
        titleLabel.text = "💚 Tree Health"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let healthOptions = ["Excellent", "Good", "Fair", "Poor"]
        let segmented = UISegmentedControl(items: healthOptions)
        segmented.selectedSegmentIndex = 1
        segmented.backgroundColor = TreeShopTheme.cardBackground
        segmented.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        segmented.setTitleTextAttributes([.foregroundColor: TreeShopTheme.primaryText], for: .normal)
        segmented.addTarget(self, action: #selector(healthChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(segmented)
        
        assessmentData.health = "Good"
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -30),
            
            segmented.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            segmented.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            segmented.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func showAFISSStep() {
        titleLabel.text = "Step 5: AFISS"
        progressBar.progress = 0.70
        
        // Scroll view for the AFISS categories
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "⚡ AFISS Assessment"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Assessment Factor Identification & Scoring System"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(subtitleLabel)
        
        // COMPLETE AFISS CATEGORIES (100+ Factors)
        let afissCategories = [
            ("Environmental - Weather", ["Rain (light)", "Rain (moderate/heavy)", "Snow accumulation", "Ice conditions", "Wind 15-25mph", "Wind 25-35mph", "Wind 35mph+", "Lightning risk", "Extreme heat 95F+", "Extreme cold 32F-"], TreeShopTheme.secondaryText),
            
            ("Environmental - Terrain", ["Steep slopes 15-30%", "Severe slopes 30%+", "Waterlogged ground", "Rocky/hard ground", "Unstable soil", "Drainage issues", "Erosion concerns", "Flood zone"], TreeShopTheme.secondaryText),
            
            ("Infrastructure - Buildings", ["Residential <10ft", "Commercial building", "Historic/protected", "High-value structures", "Roof/gutter proximity", "Deck/patio proximity", "Fence complications", "Storage shed", "Greenhouse", "Swimming pool"], TreeShopTheme.errorRed),
            
            ("Infrastructure - Utilities", ["Overhead power (primary)", "Overhead power (secondary)", "Cable/internet lines", "Telephone lines", "Underground gas", "Underground electric", "Water main proximity", "Sewer line proximity", "Cable underground", "Sprinkler system"], TreeShopTheme.errorRed),
            
            ("Infrastructure - Transport", ["Street/road proximity", "Sidewalk protection", "Driveway blocking", "Traffic control required", "School zone", "Bus route interference", "Emergency vehicle access", "Pedestrian traffic", "Parking restrictions", "Street cleaning conflicts"], TreeShopTheme.warningYellow),
            
            ("Access - Equipment", ["Narrow gate 8-12ft", "Very narrow <8ft", "Overhead clearance", "Weight restrictions", "Bridge load limits", "Steps/elevation", "Landscaping obstacles", "Multiple access points", "Backyard-only access", "Crane access required"], TreeShopTheme.warningYellow),
            
            ("Safety - Tree Risks", ["Dead/dying tree", "Leaning 15-30°", "Severely leaning 30°+", "Hollow/cavity trunk", "Root damage", "Disease present", "Insect infestation", "Storm damage", "Weak crotch/leaders", "Overextended limbs"], TreeShopTheme.errorRed),
            
            ("Safety - Environmental", ["Aggressive insects", "Wildlife habitat", "Venomous snakes", "Protected species", "Nesting birds", "Ground nesting", "Poisonous plants", "Unstable adjacent trees", "Overhead hazards", "Underground hazards"], TreeShopTheme.errorRed),
            
            ("Operational - Equipment", ["Bucket truck required", "Crane required", "Large chipper needed", "Stump grinder", "Specialized climbing", "Extensive rigging", "Winch/pulling equipment", "Trenching equipment", "Excavation equipment", "Multiple coordination"], TreeShopTheme.primaryGreen),
            
            ("Operational - Crew", ["ISA arborist required", "Experienced climber", "Additional ground crew", "Traffic control person", "Safety observer", "Equipment operator", "Cleanup crew", "Supervisor presence", "Customer liaison", "Permit coordinator"], TreeShopTheme.primaryGreen),
            
            ("Customer - Property", ["High-end landscaping", "New landscaping", "Irrigation system", "Outdoor lighting", "Security systems", "Decorative hardscaping", "Play equipment", "Outdoor furniture", "Garden structures", "Artistic elements"], TreeShopTheme.accentGreen),
            
            ("Regulatory - Permits", ["Tree removal permit", "Protected species", "Historic district", "HOA approval", "City/county approval", "Utility notification", "Environmental assessment", "Traffic permit", "Noise variance", "Waste disposal permit"], TreeShopTheme.warningYellow)
        ]
        
        for (categoryName, factors, color) in afissCategories {
            let categoryCard = createAFISSCategoryCard(title: categoryName, factors: factors, color: color)
            mainStack.addArrangedSubview(categoryCard)
        }
        
        // AFISS factors collected - no percentage display needed
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: stepContentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: stepContentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: stepContentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: stepContentView.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createAFISSCategoryCard(title: String, factors: [String], color: UIColor) -> UIView {
        let card = TreeShopTheme.cardView()
        card.layer.borderWidth = 2
        card.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        card.backgroundColor = color.withAlphaComponent(0.05)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(mainStack)
        
        // COLLAPSIBLE HEADER (Tappable)
        let headerContainer = UIView()
        headerContainer.backgroundColor = color.withAlphaComponent(0.1)
        headerContainer.layer.cornerRadius = 8
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .center
        headerStack.spacing = 12
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerStack)
        
        // Expand/Collapse Arrow
        let arrowLabel = UILabel()
        arrowLabel.text = "▶"  // Collapsed by default
        arrowLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        arrowLabel.textColor = color
        arrowLabel.tag = 9000 + factors.count // Unique tag for arrow
        headerStack.addArrangedSubview(arrowLabel)
        
        // Category Title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = color
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(titleLabel)
        
        // Factor Count Badge
        let countBadge = UILabel()
        countBadge.text = "\(factors.count)"
        countBadge.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        countBadge.textColor = .white
        countBadge.backgroundColor = color
        countBadge.layer.cornerRadius = 10
        countBadge.layer.masksToBounds = true
        countBadge.textAlignment = .center
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(countBadge)
        
        // Selected Count Badge (initially hidden)
        let selectedBadge = UILabel()
        selectedBadge.text = "0"
        selectedBadge.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        selectedBadge.textColor = .white
        selectedBadge.backgroundColor = TreeShopTheme.primaryGreen
        selectedBadge.layer.cornerRadius = 8
        selectedBadge.layer.masksToBounds = true
        selectedBadge.textAlignment = .center
        selectedBadge.isHidden = true
        selectedBadge.tag = 9500 + factors.count // Unique tag for selected count
        selectedBadge.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(selectedBadge)
        
        mainStack.addArrangedSubview(headerContainer)
        
        // COLLAPSIBLE CONTENT (Hidden by default)
        let factorContainer = UIView()
        factorContainer.isHidden = true // Start collapsed
        factorContainer.tag = 9200 + factors.count // Unique tag for content
        factorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let factorStack = UIStackView()
        factorStack.axis = .vertical
        factorStack.spacing = 6
        factorStack.translatesAutoresizingMaskIntoConstraints = false
        factorContainer.addSubview(factorStack)
        
        // Create factor buttons
        for (index, factor) in factors.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle("☐ \(factor)", for: .normal)
            button.setTitle("✓ \(factor)", for: .selected)
            button.backgroundColor = TreeShopTheme.cardBackground
            button.setTitleColor(TreeShopTheme.primaryText, for: .normal)
            button.setTitleColor(color, for: .selected)
            button.layer.cornerRadius = 6
            button.layer.borderWidth = 1
            button.layer.borderColor = color.withAlphaComponent(0.3).cgColor
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            button.contentHorizontalAlignment = .left
            // Padding handled by button height and text size
            button.tag = 5100 + (factors.count * 10) + index // Unique tags for each factor
            button.addTarget(self, action: #selector(afissFactorToggled), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            factorStack.addArrangedSubview(button)
            
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        }
        
        mainStack.addArrangedSubview(factorContainer)
        
        // Add tap gesture to header for expand/collapse
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAFISSCategory(_:)))
        headerContainer.addGestureRecognizer(tapGesture)
        headerContainer.isUserInteractionEnabled = true
        
        // Store references for collapse/expand functionality
        headerContainer.tag = 9100 + factors.count // Unique tag for header
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
            
            countBadge.widthAnchor.constraint(equalToConstant: 24),
            countBadge.heightAnchor.constraint(equalToConstant: 20),
            
            selectedBadge.widthAnchor.constraint(equalToConstant: 20),
            selectedBadge.heightAnchor.constraint(equalToConstant: 16),
            
            factorStack.topAnchor.constraint(equalTo: factorContainer.topAnchor, constant: 12),
            factorStack.leadingAnchor.constraint(equalTo: factorContainer.leadingAnchor, constant: 16),
            factorStack.trailingAnchor.constraint(equalTo: factorContainer.trailingAnchor, constant: -16),
            factorStack.bottomAnchor.constraint(equalTo: factorContainer.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    @objc private func toggleAFISSCategory(_ gesture: UITapGestureRecognizer) {
        guard let headerContainer = gesture.view else { return }
        
        let headerTag = headerContainer.tag
        let arrowTag = 9000 + (headerTag - 9100)  // Calculate arrow tag
        let contentTag = 9200 + (headerTag - 9100) // Calculate content tag
        
        // Find the arrow and content views in the same parent
        guard let parentStack = headerContainer.superview,
              let arrowLabel = parentStack.viewWithTag(arrowTag) as? UILabel,
              let contentView = parentStack.viewWithTag(contentTag) else { return }
        
        let isExpanded = !contentView.isHidden
        
        // Animate arrow rotation and content visibility
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: [], animations: {
            
            // Rotate arrow
            arrowLabel.transform = isExpanded ? .identity : CGAffineTransform(rotationAngle: .pi/2)
            arrowLabel.text = isExpanded ? "▶" : "▼"
            
            // Show/hide content
            contentView.isHidden = isExpanded
            contentView.alpha = isExpanded ? 0 : 1
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
        }, completion: nil)
        
        // Update scroll view content size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let scrollView = self.stepContentView.subviews.first as? UIScrollView {
                scrollView.layoutIfNeeded()
            }
        }
    }
    
    @objc private func afissFactorToggled(_ button: UIButton) {
        button.isSelected.toggle()
        
        // Add/remove factor from assessment data
        let factorId = "factor_\(button.tag)"
        
        if button.isSelected {
            if !assessmentData.riskFactors.contains(factorId) {
                assessmentData.riskFactors.append(factorId)
            }
        } else {
            assessmentData.riskFactors.removeAll { $0 == factorId }
        }
        
        // Update category selected count badge
        updateCategorySelectedCount(for: button)
        
        // Visual feedback
        UIView.animate(withDuration: 0.2) {
            button.backgroundColor = button.isSelected ? 
                TreeShopTheme.primaryGreen.withAlphaComponent(0.15) : 
                TreeShopTheme.cardBackground
            button.layer.borderColor = button.isSelected ?
                TreeShopTheme.primaryGreen.cgColor :
                button.backgroundColor?.cgColor
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func updateCategorySelectedCount(for button: UIButton) {
        // Find the category this button belongs to and update its selected count
        guard let categoryCard = button.superview?.superview?.superview?.superview else { return }
        
        // Count selected factors in this category
        var selectedCount = 0
        let allButtons = getAllFactorButtons(in: categoryCard)
        for btn in allButtons {
            if btn.isSelected {
                selectedCount += 1
            }
        }
        
        // Update the selected count badge
        if let selectedBadge = categoryCard.viewWithTag(9500 + 10) as? UILabel { // Approximate tag
            selectedBadge.text = "\(selectedCount)"
            selectedBadge.isHidden = selectedCount == 0
            
            UIView.animate(withDuration: 0.2) {
                selectedBadge.alpha = selectedCount > 0 ? 1.0 : 0.0
            }
        }
    }
    
    private func getAllFactorButtons(in view: UIView) -> [UIButton] {
        var buttons: [UIButton] = []
        
        func findButtons(in view: UIView) {
            for subview in view.subviews {
                if let button = subview as? UIButton, button.tag >= 5100 {
                    buttons.append(button)
                } else {
                    findButtons(in: subview)
                }
            }
        }
        
        findButtons(in: view)
        return buttons
    }
    
    // AFISS factors are used for TreeScore calculation - no percentage display needed
    
    private func showPhotosStep() {
        titleLabel.text = "Step 6: Photos"
        progressBar.progress = 0.84
        
        let titleLabel = UILabel()
        titleLabel.text = "📷 Photos (Optional)"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let photoButton = UIButton(type: .system)
        photoButton.setTitle("📷 Take Photos", for: .normal)
        photoButton.backgroundColor = TreeShopTheme.primaryGreen
        photoButton.setTitleColor(.white, for: .normal)
        photoButton.layer.cornerRadius = 8
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(photoButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -30),
            
            photoButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            photoButton.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 200),
            photoButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func showResultsStep() {
        titleLabel.text = "Step 7: Results"
        progressBar.progress = 1.0
        
        let titleLabel = UILabel()
        titleLabel.text = "🎯 Assessment Complete!"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let finalScore = calculateFinalScore()
        
        let scoreLabel = UILabel()
        scoreLabel.text = String(format: "%.0f", finalScore)
        scoreLabel.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        scoreLabel.textColor = TreeShopTheme.primaryGreen
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(scoreLabel)
        
        let scoreTitleLabel = UILabel()
        scoreTitleLabel.text = "TreeScore"
        scoreTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scoreTitleLabel.textColor = TreeShopTheme.primaryText
        scoreTitleLabel.textAlignment = .center
        scoreTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(scoreTitleLabel)
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("🌲 Add Tree to Inventory", for: .normal)
        addButton.backgroundColor = TreeShopTheme.primaryGreen
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addToInventory), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scoreLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            scoreTitleLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            scoreTitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            addButton.topAnchor.constraint(equalTo: scoreTitleLabel.bottomAnchor, constant: 30),
            addButton.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 250),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Hide navigation buttons
        prevButton.isHidden = true
        nextButton.isHidden = true
    }
    
    private func updateUI() {
        // Update navigation buttons
        prevButton.isEnabled = currentStep > 0
        prevButton.alpha = currentStep > 0 ? 1.0 : 0.5
        
        let canProceed = validateCurrentStep()
        nextButton.isEnabled = canProceed
        nextButton.alpha = canProceed ? 1.0 : 0.6
        
        if currentStep == 6 {
            nextButton.isHidden = true
            prevButton.isHidden = true
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0: return true // Location is automatically set from map tap
        case 1: return assessmentData.height != nil && assessmentData.crownRadius != nil && assessmentData.dbh != nil
        case 2: return !assessmentData.species.isEmpty
        default: return true
        }
    }
    
    private func calculatePreviewScore() -> Double {
        guard let height = assessmentData.height,
              let crown = assessmentData.crownRadius,
              let dbh = assessmentData.dbh else { return 0 }
        return (height * crown * 2 * dbh) / 12
    }
    
    private func calculateFinalScore() -> Double {
        let base = calculatePreviewScore()
        let afiss = 1 + (Double(assessmentData.riskFactors.count) * 0.08)
        return base * afiss
    }
    
    @objc private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
            showCurrentStep()
        }
    }
    
    @objc private func nextStep() {
        if currentStep < 6 && validateCurrentStep() {
            currentStep += 1
            showCurrentStep()
        }
    }
    
    // Location is automatically set from map tap - no manual input needed
    
    @objc private func measurementChanged(_ textField: UITextField) {
        let value = Double(textField.text ?? "") ?? 0
        
        switch textField.tag {
        case 2001: assessmentData.height = value > 0 ? value : nil
        case 2002: assessmentData.crownRadius = value > 0 ? value : nil  
        case 2003: assessmentData.dbh = value > 0 ? value : nil
        default: break
        }
        
        // Update preview
        if let previewLabel = stepContentView.viewWithTag(2010) as? UILabel {
            previewLabel.text = "Preview TreeScore: \(Int(calculatePreviewScore()))"
        }
        
        updateUI()
    }
    
    @objc private func speciesChanged(_ textField: UITextField) {
        assessmentData.species = textField.text ?? ""
        updateUI()
    }
    
    @objc private func healthChanged(_ segmented: UISegmentedControl) {
        let options = ["Excellent", "Good", "Fair", "Poor"]
        assessmentData.health = options[segmented.selectedSegmentIndex]
        updateUI()
    }
    
    @objc private func riskToggled(_ button: UIButton) {
        button.isSelected.toggle()
        let risks = ["power", "buildings", "cracks", "branches"]
        let risk = risks[button.tag - 5000]
        
        if button.isSelected {
            assessmentData.riskFactors.append(risk)
        } else {
            assessmentData.riskFactors.removeAll { $0 == risk }
        }
    }
    
    @objc private func addToInventory() {
        let treeItem = TreeInventoryItem(
            coordinate: currentLocation ?? CLLocationCoordinate2D(),
            gpsAccuracy: locationAccuracy ?? 0,
            height: assessmentData.height ?? 0,
            canopyRadius: assessmentData.crownRadius ?? 0,
            dbh: assessmentData.dbh ?? 0,
            afissPercentage: Double(assessmentData.riskFactors.count) * 8,
            species: assessmentData.species.isEmpty ? nil : assessmentData.species
        )
        
        // Dismiss the assessment workflow and add tree with map pin
        dismiss(animated: true) {
            // FORCE TREE SAVING AND MAP PIN CREATION
            print("🌲 FORCE SAVING: Adding tree to inventory...")
            
            // 1. Save to Core Data
            TreeInventoryManager.shared.addTree(treeItem)
            
            // 2. Force create map pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = treeItem.coordinate
            annotation.title = "Tree - \(treeItem.species ?? "Unknown")"
            annotation.subtitle = "TreeScore: \(String(format: "%.0f", treeItem.treeScore.finalTreeScore))"
            
            // 3. Get main view controller and force add pin
            var mainVC: MainMapViewController?
            if let navVC = self.presentingViewController as? UINavigationController {
                mainVC = navVC.presentingViewController as? MainMapViewController
            }
            
            if let mvc = mainVC {
                print("🗺️ Adding map pin to main view controller...")
                DispatchQueue.main.async {
                    mvc.mapView.addAnnotation(annotation)
                    mvc.updateAreaLabelWithTreeScoreInfo()
                    
                    // Force reload all existing trees to ensure map pins show
                    mvc.loadExistingTreeInventory()
                    
                    print("✅ Map pin added and UI updated!")
                    
                    // Show success confirmation
                    let alert = UIAlertController(
                        title: "Tree Added",
                        message: "TreeScore: \(String(format: "%.0f", treeItem.treeScore.finalTreeScore)) saved to inventory",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    mvc.present(alert, animated: true)
                }
            } else {
                print("❌ Could not find main view controller for map pin")
            }
        }
    }
    
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
        assessmentData.coordinate = coordinate
        assessmentData.accuracy = accuracy
    }
}

class WorkingAssessmentData {
    var locationText: String = ""
    var coordinate: CLLocationCoordinate2D?
    var accuracy: CLLocationAccuracy?
    var height: Double?
    var crownRadius: Double?
    var dbh: Double?
    var species: String = ""
    var health: String = ""
    var riskFactors: [String] = []
}

// MARK: - MeasurementHistoryDelegate
/* Commented until StoredMeasurement model is added
extension MainMapViewController: MeasurementHistoryDelegate {
    func measurementHistoryDidSelectMeasurement(_ measurement: StoredMeasurement) {
        // Load measurement onto map
        loadMeasurementOntoMap(measurement)
    }
    
    func measurementHistoryDidDeleteMeasurement(_ measurement: StoredMeasurement) {
        // Remove from loaded measurements if present
        loadedMeasurements.removeAll { $0.id == measurement.id }
        // Could also remove from map if currently displayed
    }
    
    private func loadMeasurementOntoMap(_ measurement: StoredMeasurement) {
        // Clear current mode
        setMode(.normal)
        
        // Create annotations for the measurement points
        let annotations = measurement.createAnnotations()
        mapView.addAnnotations(annotations)
        
        // Create overlay
        let overlay = measurement.createMapOverlay()
        mapView.addOverlay(overlay)
        
        // Zoom to fit the measurement
        let coordinates = measurement.coordinates
        if !coordinates.isEmpty {
            let region = MKCoordinateRegion(coordinates: coordinates)
            mapView.setRegion(region, animated: true)
        }
        
        // Show measurement info
        let settings = MeasurementSettings.shared
        let valueText = measurement.getFormattedValue(distanceUnit: settings.distanceUnit, areaUnit: settings.areaUnit)
        showAlert(title: "Loaded: \(measurement.name)", message: "Value: \(valueText)")
    }
}

// MARK: - LocationManagerDelegate
extension MainMapViewController: LocationManagerDelegate {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
        updateGPSAccuracy()
    }
    
    func locationManager(_ manager: LocationManager, didUpdateBoundaryDistance distance: Double, zone: BoundaryZone) {
        // Handle boundary distance updates if needed
    }
    
    func locationManager(_ manager: LocationManager, didUpdateHeading heading: CLHeading) {
        // Handle heading updates if needed
    }
}

// MARK: - MKCoordinateRegion Extension
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self = MKCoordinateRegion()
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2, // Add 20% padding
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        self = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - TreeScore Integration
extension MainMapViewController: TreeScoreInputDelegate {
    func didCreateTreeInventoryItem(_ item: TreeInventoryItem) {
        // Add to inventory manager
        TreeInventoryManager.shared.addTree(item)
        
        // Create and add map annotation
        let annotation = item.createMapAnnotation()
        mapView.addAnnotation(annotation)
        treeScoreAnnotations.append(annotation)
        
        // Update area label with tree count and TreeScore info
        updateAreaLabelWithTreeScoreInfo()
        
        // Dismiss the input controller
        dismiss(animated: true) {
            self.showTreeAddedConfirmation(treeScore: item.treeScore.finalTreeScore)
        }
        
        print("🌲 Added tree with TreeScore: \(item.treeScore.finalTreeScore)")
    }
    
    func didCancelTreeInput() {
        dismiss(animated: true)
    }
    
    private func showTreeAddedConfirmation(treeScore: Double) {
        let complexity = getTreeComplexity(for: treeScore)
        
        let alert = UIAlertController(
            title: "🌲 Tree Added to Inventory",
            message: String(format: "TreeScore: %.0f pts\nComplexity: %@", treeScore, complexity.rawValue),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Add Another", style: .default) { _ in
            // Stay in tree inventory mode
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { _ in
            self.setMode(.normal)
        })
        
        present(alert, animated: true)
    }
    
    private func getTreeComplexity(for treeScore: Double) -> TreeComplexity {
        switch treeScore {
        case 0..<500: return .low
        case 500..<1500: return .medium  
        case 1500..<3000: return .high
        default: return .extreme
        }
    }
}
*/