import UIKit
import CoreLocation
import AVFoundation

class StumpTrackingViewController: UIViewController {
    
    // MARK: - Properties
    var treeStump: TreeStump!
    var property: Property?
    var originalTree: TreeMark? // Optional link to original tree
    
    // MARK: - UI Elements
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // Stump Information
    @IBOutlet weak var stumpTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var getLocationButton: UIButton!
    
    // Photo Documentation (Before/After)
    @IBOutlet weak var beforePhotoButton: UIButton!
    @IBOutlet weak var afterPhotoButton: UIButton!
    @IBOutlet weak var beforePhotoImageView: UIImageView!
    @IBOutlet weak var afterPhotoImageView: UIImageView!
    
    // Completion Tracking
    @IBOutlet weak var completionDatePicker: UIDatePicker!
    @IBOutlet weak var verifiedByTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Photo Management
    private var currentPhotoCapture: StumpPhotoType?
    private let imagePickerController = UIImagePickerController()
    private let locationManager = LocationManager.shared
    
    enum StumpPhotoType {
        case before
        case after
        
        var displayName: String {
            switch self {
            case .before: return "Before Photo"
            case .after: return "After Photo"
            }
        }
        
        var instructions: String {
            switch self {
            case .before:
                return "Take photo of stump before grinding/removal work begins"
            case .after:
                return "Take photo after grinding/removal work is completed"
            }
        }
    }
    
    enum StumpStatus: String, CaseIterable {
        case identified = "Identified"
        case scheduled = "Scheduled"
        case inProgress = "In Progress"
        case completed = "Completed"
        case verified = "Verified"
        
        var color: UIColor {
            switch self {
            case .identified: return .systemBlue
            case .scheduled: return .systemOrange
            case .inProgress: return .systemYellow
            case .completed: return .systemGreen
            case .verified: return .systemPurple
            }
        }
    }
    
    enum StumpType: String, CaseIterable {
        case standing = "Standing"
        case ground = "Ground"
        
        var description: String {
            switch self {
            case .standing: return "Standing stump requiring grinding"
            case .ground: return "Ground stump requiring cleanup"
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
        loadStumpData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Stump Tracking"
        
        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        // Configure segmented controls
        stumpTypeSegmentedControl.removeAllSegments()
        StumpType.allCases.enumerated().forEach { index, type in
            stumpTypeSegmentedControl.insertSegment(withTitle: type.rawValue, at: index, animated: false)
        }
        stumpTypeSegmentedControl.selectedSegmentIndex = 0
        
        statusSegmentedControl.removeAllSegments()
        StumpStatus.allCases.enumerated().forEach { index, status in
            statusSegmentedControl.insertSegment(withTitle: status.rawValue, at: index, animated: false)
        }
        statusSegmentedControl.selectedSegmentIndex = 0
        
        // Configure photo buttons and image views
        configurePhotoButton(beforePhotoButton, type: .before)
        configurePhotoButton(afterPhotoButton, type: .after)
        
        [beforePhotoImageView, afterPhotoImageView].forEach { imageView in
            imageView?.contentMode = .scaleAspectFill
            imageView?.clipsToBounds = true
            imageView?.layer.cornerRadius = 8
            imageView?.backgroundColor = UIColor.systemGray6
        }
        
        // Configure completion date picker
        completionDatePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            completionDatePicker.preferredDatePickerStyle = .compact
        }
        completionDatePicker.date = Date()
        
        // Notes text view
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        
        // Location button
        getLocationButton.setTitle("📍 Get Current Location", for: .normal)
        getLocationButton.backgroundColor = UIColor.systemBlue
        getLocationButton.setTitleColor(.white, for: .normal)
        getLocationButton.layer.cornerRadius = 8
        
        updateSaveButtonState()
    }
    
    private func configurePhotoButton(_ button: UIButton, type: StumpPhotoType) {
        button.setTitle("📷 \(type.displayName)", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
    }
    
    private func setupImagePicker() {
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .camera
    }
    
    private func loadStumpData() {
        guard let stump = treeStump else { return }
        
        // Load stump type
        if let type = stump.stumpType {
            let types = StumpType.allCases.map { $0.rawValue }
            if let index = types.firstIndex(of: type) {
                stumpTypeSegmentedControl.selectedSegmentIndex = index
            }
        }
        
        // Load status
        if let status = stump.status {
            let statuses = StumpStatus.allCases.map { $0.rawValue }
            if let index = statuses.firstIndex(of: status) {
                statusSegmentedControl.selectedSegmentIndex = index
            }
        }
        
        // Load completion date
        if let completionDate = stump.completionDate {
            completionDatePicker.date = completionDate
        }
        
        // Load verified by
        verifiedByTextField.text = stump.verifiedBy
        
        // Load location
        updateLocationDisplay()
        
        // Load existing photos
        loadExistingPhotos()
        
        updateSaveButtonState()
    }
    
    private func loadExistingPhotos() {
        if let beforeData = treeStump.beforePhotoData {
            beforePhotoImageView.image = UIImage(data: beforeData)
            beforePhotoButton.setTitle("✓ Before Photo", for: .normal)
            beforePhotoButton.backgroundColor = UIColor.systemGreen
        }
        
        if let afterData = treeStump.afterPhotoData {
            afterPhotoImageView.image = UIImage(data: afterData)
            afterPhotoButton.setTitle("✓ After Photo", for: .normal)
            afterPhotoButton.backgroundColor = UIColor.systemGreen
        }
    }
    
    // MARK: - Actions
    @IBAction func getLocationTapped(_ sender: UIButton) {
        guard let location = locationManager.location else {
            showAlert(title: "Location Error", message: "Unable to get current location. Please check location permissions.")
            return
        }
        
        treeStump.latitude = location.coordinate.latitude
        treeStump.longitude = location.coordinate.longitude
        updateLocationDisplay()
        updateSaveButtonState()
        
        print("📍 Stump location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    @IBAction func beforePhotoTapped(_ sender: UIButton) {
        capturePhoto(type: .before)
    }
    
    @IBAction func afterPhotoTapped(_ sender: UIButton) {
        capturePhoto(type: .after)
    }
    
    private func capturePhoto(type: StumpPhotoType) {
        currentPhotoCapture = type
        
        // Show instructions
        let alert = UIAlertController(
            title: type.displayName,
            message: type.instructions,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Error", message: "Camera is not available.")
            return
        }
        
        present(imagePickerController, animated: true)
    }
    
    private func updateLocationDisplay() {
        if treeStump.latitude != 0 && treeStump.longitude != 0 {
            locationLabel.text = "📍 \(String(format: "%.6f", treeStump.latitude)), \(String(format: "%.6f", treeStump.longitude))"
            getLocationButton.setTitle("✓ Location Recorded", for: .normal)
            getLocationButton.backgroundColor = UIColor.systemGreen
        } else {
            locationLabel.text = "📍 Location not recorded"
            getLocationButton.setTitle("📍 Get Current Location", for: .normal)
            getLocationButton.backgroundColor = UIColor.systemBlue
        }
    }
    
    private func updateSaveButtonState() {
        let hasLocation = treeStump.latitude != 0 && treeStump.longitude != 0
        let hasBeforePhoto = treeStump.beforePhotoData != nil
        
        // Before photo and location are minimum requirements
        let canSave = hasLocation && hasBeforePhoto
        
        saveButton.isEnabled = canSave
        navigationItem.rightBarButtonItem?.isEnabled = canSave
        
        if canSave {
            saveButton.backgroundColor = UIColor.systemGreen
            saveButton.setTitle("✓ Save Stump", for: .normal)
        } else {
            saveButton.backgroundColor = UIColor.systemGray
            var missing: [String] = []
            if !hasLocation { missing.append("location") }
            if !hasBeforePhoto { missing.append("before photo") }
            saveButton.setTitle("Missing: \(missing.joined(separator: ", "))", for: .normal)
        }
    }
    
    // MARK: - Save/Cancel
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        saveStumpData()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        saveStumpData()
    }
    
    private func saveStumpData() {
        // Update stump data
        let selectedType = StumpType.allCases[stumpTypeSegmentedControl.selectedSegmentIndex]
        let selectedStatus = StumpStatus.allCases[statusSegmentedControl.selectedSegmentIndex]
        
        treeStump.stumpType = selectedType.rawValue
        treeStump.status = selectedStatus.rawValue
        treeStump.verifiedBy = verifiedByTextField.text
        
        // Set completion date if status is completed or verified
        if selectedStatus == .completed || selectedStatus == .verified {
            treeStump.completionDate = completionDatePicker.date
        }
        
        // Save timestamps
        if treeStump.createdAt == nil {
            treeStump.createdAt = Date()
        }
        
        // Associate with property if available
        if let property = property {
            treeStump.property = property
        }
        
        // Link to original tree if provided
        if let tree = originalTree {
            treeStump.originalTree = tree
            tree.stump = treeStump
        }
        
        // Save to Core Data
        do {
            let context = treeStump.managedObjectContext
            try context?.save()
            
            print("✅ Stump saved successfully")
            
            let alert = UIAlertController(
                title: "Stump Saved",
                message: "Stump tracking updated with \(selectedType.rawValue) type and \(selectedStatus.rawValue) status.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            present(alert, animated: true)
            
        } catch {
            showAlert(title: "Save Error", message: "Failed to save stump data: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension StumpTrackingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
              let photoType = currentPhotoCapture else {
            picker.dismiss(animated: true)
            return
        }
        
        // Compress image
        let compressedData = compressImage(selectedImage, maxSizeKB: 500)
        
        // Save based on type
        switch photoType {
        case .before:
            treeStump.beforePhotoData = compressedData
            beforePhotoImageView.image = selectedImage
            beforePhotoButton.setTitle("✓ Before Photo", for: .normal)
            beforePhotoButton.backgroundColor = UIColor.systemGreen
            
        case .after:
            treeStump.afterPhotoData = compressedData
            afterPhotoImageView.image = selectedImage
            afterPhotoButton.setTitle("✓ After Photo", for: .normal)
            afterPhotoButton.backgroundColor = UIColor.systemGreen
        }
        
        updateSaveButtonState()
        currentPhotoCapture = nil
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentPhotoCapture = nil
        picker.dismiss(animated: true)
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxSize = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compression) {
                imageData = compressedData
            }
        }
        
        return imageData
    }
}