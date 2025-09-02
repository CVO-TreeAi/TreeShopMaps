import UIKit
import MapKit
import CoreData
import CoreLocation

class MainMapViewController: UIViewController {
    
    // MARK: - UI Elements
    private var mapView: MKMapView!
    private var searchBar: UISearchBar!
    private var searchResultsTableView: UITableView!
    private var searchContainerView: UIView!
    private var toolbar: UIToolbar!
    private var bottomToolsView: UIView!
    private var currentModeLabel: UILabel!
    private var areaLabel: UILabel!
    private var perimeterLabel: UILabel!
    
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
    
    // MARK: - Mode Management
    enum AppMode {
        case normal
        case drawing
        case measuring
    }
    private var currentMode: AppMode = .normal
    
    // MARK: - Drawing Properties
    private var drawingMarkers: [MKPointAnnotation] = []
    private var currentPolygon: MKPolygon?
    private var workZonePolygons: [MKPolygon] = []
    
    // MARK: - Measuring Properties
    private var measuringMarkers: [MKPointAnnotation] = []
    private var measuringLine: MKPolyline?
    
    // MARK: - Professional Measurement Features
    private var undoStack: [[MKPointAnnotation]] = []
    private var redoStack: [[MKPointAnnotation]] = []
    private var currentMeasurementValue: Double = 0
    private var currentPerimeterValue: Double = 0
    // private var loadedMeasurements: [StoredMeasurement] = []
    
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
        setupBottomToolsView()
        // REMOVE ALL EXISTING TOOLBARS
        view.subviews.forEach { subview in
            if subview is UIToolbar {
                subview.removeFromSuperview()
            }
        }
        setupForcedCleanToolbar()
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
        bottomToolsView = UIView()
        bottomToolsView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolsView.backgroundColor = TreeShopTheme.cardBackground
        bottomToolsView.layer.cornerRadius = TreeShopTheme.cornerRadius
        bottomToolsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        view.addSubview(bottomToolsView)
        view.bringSubviewToFront(bottomToolsView)
        
        // Current mode label
        currentModeLabel = UILabel()
        currentModeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentModeLabel.text = "Ready"
        currentModeLabel.textColor = TreeShopTheme.primaryText
        currentModeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        bottomToolsView.addSubview(currentModeLabel)
        
        // Area label
        areaLabel = UILabel()
        areaLabel.translatesAutoresizingMaskIntoConstraints = false
        areaLabel.text = "0.00 acres"
        areaLabel.textColor = TreeShopTheme.primaryText
        areaLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        bottomToolsView.addSubview(areaLabel)
        
        // Perimeter label
        perimeterLabel = UILabel()
        perimeterLabel.translatesAutoresizingMaskIntoConstraints = false
        perimeterLabel.text = ""
        perimeterLabel.textColor = TreeShopTheme.accentGreen
        perimeterLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        perimeterLabel.isHidden = true
        bottomToolsView.addSubview(perimeterLabel)
        
        // Package selector - REMOVED
        // let packages = ServicePackage.allCases.map { $0.rawValue }
        // packageSelector = UISegmentedControl(items: packages)
        // packageSelector.translatesAutoresizingMaskIntoConstraints = false
        // packageSelector.selectedSegmentIndex = 1 // Medium by default
        // packageSelector.addTarget(self, action: #selector(packageChanged(_:)), for: .valueChanged)
        // 
        // if #available(iOS 13.0, *) {
        //     packageSelector.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        //     packageSelector.backgroundColor = TreeShopTheme.buttonBackground
        //     let normalTextAttributes: [NSAttributedString.Key: Any] = [
        //         .foregroundColor: TreeShopTheme.secondaryText
        //     ]
        //     let selectedTextAttributes: [NSAttributedString.Key: Any] = [
        //         .foregroundColor: UIColor.white
        //     ]
        //     packageSelector.setTitleTextAttributes(normalTextAttributes, for: .normal)
        //     packageSelector.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        // }
        // 
        // bottomToolsView.addSubview(packageSelector)
        
        // Constraints
        NSLayoutConstraint.activate([
            bottomToolsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolsView.heightAnchor.constraint(equalToConstant: 80),  // Reduced height since no package selector
            
            currentModeLabel.topAnchor.constraint(equalTo: bottomToolsView.topAnchor, constant: 16),
            currentModeLabel.leadingAnchor.constraint(equalTo: bottomToolsView.leadingAnchor, constant: 20),
            
            areaLabel.topAnchor.constraint(equalTo: currentModeLabel.bottomAnchor, constant: 8),
            areaLabel.leadingAnchor.constraint(equalTo: bottomToolsView.leadingAnchor, constant: 20),
            
            perimeterLabel.topAnchor.constraint(equalTo: areaLabel.bottomAnchor, constant: 4),
            perimeterLabel.leadingAnchor.constraint(equalTo: bottomToolsView.leadingAnchor, constant: 20)
            
            // Removed package selector constraints
            // packageSelector.leadingAnchor.constraint(equalTo: bottomToolsView.leadingAnchor, constant: 20),
            // packageSelector.trailingAnchor.constraint(equalTo: bottomToolsView.trailingAnchor, constant: -20),
            // packageSelector.bottomAnchor.constraint(equalTo: bottomToolsView.bottomAnchor, constant: -20),
            // packageSelector.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupForcedCleanToolbar() {
        toolbar?.removeFromSuperview()
        toolbar = nil
        
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = TreeShopTheme.cardBackground
        TreeShopTheme.applyToolbarTheme(to: toolbar)
        
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
        
        // Start with just 2 buttons - more appear when drawing
        toolbar.setItems([flexSpace, drawBtn, flexSpace, moreBtn, flexSpace], animated: false)
        
        view.addSubview(toolbar)
        view.bringSubviewToFront(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomToolsView.topAnchor, constant: -8),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func updateToolbarForMode(_ mode: AppMode) {
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
        
        if mode == .normal {
            // Normal mode: Just Draw and More
            toolbar.setItems([flexSpace, drawBtn, flexSpace, moreBtn, flexSpace], animated: true)
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
            
            toolbar.setItems([drawBtn, flexSpace, undoBtn, flexSpace, clearBtn, flexSpace, moreBtn], animated: true)
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
        localSearchCompleter.resultTypes = [.address, .pointOfInterest]
        localSearchCompleter.region = mapView.region
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
            updateToolbarForMode(.normal)
            
        case .drawing:
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.textColor = TreeShopTheme.primaryGreen
            mapView.addGestureRecognizer(drawingTapGesture)
            updateToolbarForMode(.drawing)
            
        case .measuring:
            currentModeLabel.text = "Drawing Mode - Tap to add points"
            currentModeLabel.textColor = TreeShopTheme.primaryGreen
            areaLabel.text = "0 ft"
            mapView.addGestureRecognizer(drawingTapGesture)
            updateToolbarForMode(.drawing)
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
    
    @objc private func handleDrawingTap(_ gesture: UITapGestureRecognizer) {
        switch currentMode {
        case .drawing:
            handleDrawingModeTap(gesture)
        case .measuring:
            handleMeasuringModeTap(gesture)
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
        case .normal:
            // Clear search location if in normal mode
            clearSearchLocation()
            break
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
        showAlert(title: "Units", message: "Currently using feet and acres.")
    }
    
    @objc private func showMoreMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // History action
        alertController.addAction(UIAlertAction(title: "View History", style: .default) { [weak self] _ in
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
            popover.barButtonItem = toolbar.items?.last // More button
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
                localSearchCompleter.queryFragment = searchText
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
        
        DispatchQueue.main.async {
            // Only show results if search bar is active and has text
            if !self.searchResults.isEmpty && 
               !self.searchBar.text!.isEmpty && 
               self.searchBar.isFirstResponder {
                self.showSearchResults()
            } else {
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
            
            // Use a simple green color for areas
            renderer.fillColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.4)
            renderer.strokeColor = TreeShopTheme.primaryGreen
            renderer.lineWidth = 3
            renderer.lineDashPattern = nil // Solid line
            renderer.lineJoin = .round
            renderer.lineCap = .round
            
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
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Tree functionality removed - no longer handling callout taps
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
           touch.view?.isDescendant(of: toolbar) == true ||
           touch.view?.isDescendant(of: bottomToolsView) == true {
            return false
        }
        return true
    }
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
*/