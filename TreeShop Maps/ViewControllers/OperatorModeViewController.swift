import UIKit
import MapKit
import CoreLocation
import CoreData

class OperatorModeViewController: UIViewController {
    
    var property: Property?
    
    private var mapView: MKMapView!
    private var statusView: UIView!
    private var progressLabel: UILabel!
    private var speedLabel: UILabel!
    private var acresLabel: UILabel!
    private var boundaryDistanceLabel: UILabel!
    private var startStopButton: UIButton!
    private var markHazardButton: UIButton!
    private var takePhotoButton: UIButton!
    private var completeZoneButton: UIButton!
    
    private var locationManager: LocationManager!
    private var isTracking = false
    private var currentSession: WorkSession?
    private var sessionStartTime: Date?
    private var coverageOverlay: MKOverlay?
    
    private var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocationManager()
        loadWorkZones()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force landscape orientation using proper API
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .hybrid
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.delegate = self
        view.addSubview(mapView)
        
        setupStatusView()
        setupControlButtons()
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStatusView() {
        statusView = UIView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        statusView.layer.cornerRadius = 12
        view.addSubview(statusView)
        
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusView.widthAnchor.constraint(equalToConstant: 300),
            statusView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        statusView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: statusView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: -16)
        ])
        
        progressLabel = createStatusLabel("Progress: 0%")
        speedLabel = createStatusLabel("Speed: 0 mph")
        acresLabel = createStatusLabel("Acres: 0.00")
        boundaryDistanceLabel = createStatusLabel("Boundary: --")
        
        stackView.addArrangedSubview(progressLabel)
        stackView.addArrangedSubview(speedLabel)
        stackView.addArrangedSubview(acresLabel)
        stackView.addArrangedSubview(boundaryDistanceLabel)
    }
    
    private func createStatusLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }
    
    private func setupControlButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        view.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.widthAnchor.constraint(equalToConstant: 160),
            buttonStackView.heightAnchor.constraint(equalToConstant: 240)
        ])
        
        startStopButton = createControlButton("Start Recording", color: .systemGreen, action: #selector(startStopButtonTapped))
        markHazardButton = createControlButton("Mark Hazard", color: .systemOrange, action: #selector(markHazardButtonTapped))
        takePhotoButton = createControlButton("Take Photo", color: .systemBlue, action: #selector(takePhotoButtonTapped))
        completeZoneButton = createControlButton("Complete Zone", color: .systemPurple, action: #selector(completeZoneButtonTapped))
        
        buttonStackView.addArrangedSubview(startStopButton)
        buttonStackView.addArrangedSubview(markHazardButton)
        buttonStackView.addArrangedSubview(takePhotoButton)
        buttonStackView.addArrangedSubview(completeZoneButton)
        
        let exitButton = UIButton(type: .system)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.setTitle("Exit", for: .normal)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        exitButton.backgroundColor = .systemRed
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.layer.cornerRadius = 25
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        view.addSubview(exitButton)
        
        NSLayoutConstraint.activate([
            exitButton.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exitButton.widthAnchor.constraint(equalToConstant: 100),
            exitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createControlButton(_ title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func setupLocationManager() {
        locationManager = LocationManager.shared
        locationManager.delegate = self
        
        if let location = locationManager.getCurrentLocation() {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 200,
                longitudinalMeters: 200
            )
            mapView.setRegion(region, animated: false)
        }
    }
    
    private func loadWorkZones() {
        guard let workZones = property?.workZones as? Set<WorkZone> else { return }
        
        for zone in workZones {
            if let polygonData = zone.polygonData,
               let polygon = (try? NSKeyedUnarchiver(forReadingFrom: polygonData))?.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? MKPolygon {
                polygon.title = zone.servicePackage
                mapView.addOverlay(polygon)
                
                if !zone.isCompleted {
                    locationManager.setBoundary(polygon)
                }
            }
        }
    }
    
    @objc private func startStopButtonTapped() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    private func startTracking() {
        isTracking = true
        startStopButton.setTitle("Stop Recording", for: .normal)
        startStopButton.backgroundColor = .systemRed
        
        locationManager.startBackgroundTracking()
        
        createNewSession()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    private func stopTracking() {
        isTracking = false
        startStopButton.setTitle("Start Recording", for: .normal)
        startStopButton.backgroundColor = .systemGreen
        
        locationManager.stopTracking()
        updateTimer?.invalidate()
        updateTimer = nil
        
        saveSession()
    }
    
    private func createNewSession() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let property = property else { return }
        
        let context = appDelegate.persistentContainer.viewContext
        
        currentSession = WorkSession(context: context)
        currentSession?.id = UUID()
        currentSession?.startTime = Date()
        currentSession?.operatorName = UIDevice.current.name
        currentSession?.machineID = "Machine-001"
        currentSession?.property = property
        
        sessionStartTime = Date()
    }
    
    private func saveSession() {
        guard let session = currentSession,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        session.endTime = Date()
        
        let breadcrumbPath = locationManager.getBreadcrumbPath()
        if let pathData = try? NSKeyedArchiver.archivedData(withRootObject: breadcrumbPath, requiringSecureCoding: false) {
            session.gpsTrackData = pathData
        }
        
        if let coveragePolygon = locationManager.getCoveragePolygon() {
            let area = calculateArea(for: coveragePolygon)
            session.acresCovered = area
        }
        
        let context = appDelegate.persistentContainer.viewContext
        do {
            try context.save()
        } catch {
            print("Error saving session: \(error)")
        }
        
        currentSession = nil
    }
    
    private func updateStatus() {
        guard let location = locationManager.getCurrentLocation() else { return }
        
        let speed = location.speed * 2.23694
        speedLabel.text = String(format: "Speed: %.1f mph", max(0, speed))
        
        if let coveragePolygon = locationManager.getCoveragePolygon() {
            if let overlay = coverageOverlay {
                mapView.removeOverlay(overlay)
            }
            
            coverageOverlay = coveragePolygon
            mapView.addOverlay(coveragePolygon)
            
            let acres = calculateArea(for: coveragePolygon)
            acresLabel.text = String(format: "Acres: %.2f", acres)
            
            if let totalAcres = calculateTotalWorkZoneArea(), totalAcres > 0 {
                let progress = (acres / totalAcres) * 100
                progressLabel.text = String(format: "Progress: %.1f%%", min(100, progress))
            }
        }
        
        if let boundaryInfo = locationManager.calculateDistanceToBoundary(from: location) {
            boundaryDistanceLabel.text = String(format: "Boundary: %.0f ft", boundaryInfo.distance)
            boundaryDistanceLabel.textColor = boundaryInfo.zone.color
            
            if boundaryInfo.zone == .critical {
                showBoundaryAlert()
            }
        }
    }
    
    private func calculateArea(for polygon: MKPolygon) -> Double {
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
    
    private func calculateTotalWorkZoneArea() -> Double? {
        guard let workZones = property?.workZones as? Set<WorkZone> else { return nil }
        
        return workZones.reduce(0) { total, zone in
            total + (zone.isCompleted ? 0 : zone.acreage)
        }
    }
    
    private func showBoundaryAlert() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layer.borderColor = UIColor.red.cgColor
            self?.view.layer.borderWidth = 8
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.3) {
                self?.view.layer.borderWidth = 0
            }
        }
    }
    
    @objc private func markHazardButtonTapped() {
        guard let location = locationManager.getCurrentLocation() else { return }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Hazard"
        annotation.subtitle = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        mapView.addAnnotation(annotation)
        
        showAlert(title: "Hazard Marked", message: "Location saved")
    }
    
    @objc private func takePhotoButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    @objc private func completeZoneButtonTapped() {
        let alert = UIAlertController(title: "Complete Zone", message: "Mark this zone as completed?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { [weak self] _ in
            self?.completeCurrentZone()
        })
        
        present(alert, animated: true)
    }
    
    private func completeCurrentZone() {
        guard let workZones = property?.workZones as? Set<WorkZone>,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        for zone in workZones {
            if !zone.isCompleted {
                zone.isCompleted = true
                
                let context = appDelegate.persistentContainer.viewContext
                do {
                    try context.save()
                    showAlert(title: "Zone Completed", message: "Zone marked as complete")
                } catch {
                    print("Error completing zone: \(error)")
                }
                break
            }
        }
    }
    
    @objc private func exitButtonTapped() {
        if isTracking {
            stopTracking()
        }
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension OperatorModeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            
            if overlay === coverageOverlay {
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 2
            } else if let packageString = polygon.title,
                      let package = ServicePackage(rawValue: packageString) {
                renderer.fillColor = package.color
                renderer.strokeColor = package.color.withAlphaComponent(1.0)
                renderer.lineWidth = 3
            }
            
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 8
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "Hazard"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        if let markerView = annotationView as? MKMarkerAnnotationView {
            markerView.markerTintColor = .systemOrange
            markerView.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
        }
        
        return annotationView
    }
}

extension OperatorModeViewController: LocationManagerDelegate {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
        
    }
    
    func locationManager(_ manager: LocationManager, didUpdateBoundaryDistance distance: Double, zone: BoundaryZone) {
        
    }
    
    func locationManager(_ manager: LocationManager, didUpdateHeading heading: CLHeading) {
        
    }
}

extension OperatorModeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage,
           let location = locationManager.getCurrentLocation(),
           let session = currentSession,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            
            let context = appDelegate.persistentContainer.viewContext
            
            let photo = SessionPhoto(context: context)
            photo.id = UUID()
            photo.photoData = image.jpegData(compressionQuality: 0.7)
            photo.latitude = location.coordinate.latitude
            photo.longitude = location.coordinate.longitude
            photo.timestamp = Date()
            photo.photoType = "Work Progress"
            photo.session = session
            
            do {
                try context.save()
                showAlert(title: "Photo Saved", message: "Photo has been saved to session")
            } catch {
                print("Error saving photo: \(error)")
            }
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}