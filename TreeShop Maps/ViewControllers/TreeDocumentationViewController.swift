import UIKit
import AVFoundation
import Photos
import CoreLocation

class TreeDocumentationViewController: UIViewController {
    
    // MARK: - Properties
    var treeMark: TreeMark!
    var property: Property?
    
    // MARK: - UI Elements
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // Tree Information Section
    @IBOutlet weak var treeInfoStackView: UIStackView!
    @IBOutlet weak var treeScoreLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    // Measurements Section
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var canopyRadiusTextField: UITextField!
    @IBOutlet weak var dbhTextField: UITextField!
    @IBOutlet weak var speciesTextField: UITextField!
    @IBOutlet weak var conditionSegmentedControl: UISegmentedControl!
    
    // Photo Documentation Section (3 Required Photos)
    @IBOutlet weak var overviewPhotoButton: UIButton!
    @IBOutlet weak var trunkPhotoButton: UIButton!
    @IBOutlet weak var canopyPhotoButton: UIButton!
    
    @IBOutlet weak var overviewPhotoImageView: UIImageView!
    @IBOutlet weak var trunkPhotoImageView: UIImageView!
    @IBOutlet weak var canopyPhotoImageView: UIImageView!
    
    @IBOutlet weak var photoProgressLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Photo Management
    private var currentPhotoType: TreeScoreCalculator.TreePhotoType?
    private let imagePickerController = UIImagePickerController()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
        loadTreeData()
        updatePhotoProgress()
        
        // Add observers for text field changes
        [heightTextField, canopyRadiusTextField, dbhTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(measurementChanged), for: .editingChanged)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Tree Documentation"
        
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
        
        // Configure photo buttons
        configurePhotoButton(overviewPhotoButton, type: .overview)
        configurePhotoButton(trunkPhotoButton, type: .trunk)
        configurePhotoButton(canopyPhotoButton, type: .canopy)
        
        // Configure image views
        [overviewPhotoImageView, trunkPhotoImageView, canopyPhotoImageView].forEach { imageView in
            imageView?.contentMode = .scaleAspectFill
            imageView?.clipsToBounds = true
            imageView?.layer.cornerRadius = 8
            imageView?.backgroundColor = UIColor.systemGray6
        }
        
        // Condition options
        conditionSegmentedControl.removeAllSegments()
        ["Excellent", "Good", "Fair", "Poor", "Hazardous"].enumerated().forEach { index, condition in
            conditionSegmentedControl.insertSegment(withTitle: condition, at: index, animated: false)
        }
        conditionSegmentedControl.selectedSegmentIndex = 1 // Default to "Good"
        
        // Initially disable save until all requirements met
        updateSaveButtonState()
    }
    
    private func configurePhotoButton(_ button: UIButton, type: TreeScoreCalculator.TreePhotoType) {
        button.setTitle("📷 \(type.displayName)", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.tag = type.hashValue
    }
    
    private func setupImagePicker() {
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .camera
    }
    
    private func loadTreeData() {
        guard let treeMark = treeMark else { return }
        
        // Load existing measurements
        if treeMark.height > 0 {
            heightTextField.text = String(format: "%.1f", treeMark.height)
        }
        if treeMark.canopyRadius > 0 {
            canopyRadiusTextField.text = String(format: "%.1f", treeMark.canopyRadius)
        }
        if treeMark.dbh > 0 {
            dbhTextField.text = String(format: "%.1f", treeMark.dbh)
        }
        
        speciesTextField.text = treeMark.species
        
        // Load condition
        if let condition = treeMark.healthStatus {
            let conditions = ["Excellent", "Good", "Fair", "Poor", "Hazardous"]
            if let index = conditions.firstIndex(of: condition) {
                conditionSegmentedControl.selectedSegmentIndex = index
            }
        }
        
        // Load existing photos
        loadExistingPhotos()
        
        // Update location
        updateLocationDisplay()
        
        // Update TreeScore
        updateTreeScoreDisplay()
    }
    
    private func loadExistingPhotos() {
        if let overviewData = treeMark.overviewPhotoData {
            overviewPhotoImageView.image = UIImage(data: overviewData)
            overviewPhotoButton.setTitle("✓ \(TreeScoreCalculator.TreePhotoType.overview.displayName)", for: .normal)
            overviewPhotoButton.backgroundColor = UIColor.systemGreen
        }
        
        if let trunkData = treeMark.trunkPhotoData {
            trunkPhotoImageView.image = UIImage(data: trunkData)
            trunkPhotoButton.setTitle("✓ \(TreeScoreCalculator.TreePhotoType.trunk.displayName)", for: .normal)
            trunkPhotoButton.backgroundColor = UIColor.systemGreen
        }
        
        if let canopyData = treeMark.canopyPhotoData {
            canopyPhotoImageView.image = UIImage(data: canopyData)
            canopyPhotoButton.setTitle("✓ \(TreeScoreCalculator.TreePhotoType.canopy.displayName)", for: .normal)
            canopyPhotoButton.backgroundColor = UIColor.systemGreen
        }
    }
    
    // MARK: - Photo Capture Actions
    @IBAction func overviewPhotoTapped(_ sender: UIButton) {
        capturePhoto(type: .overview)
    }
    
    @IBAction func trunkPhotoTapped(_ sender: UIButton) {
        capturePhoto(type: .trunk)
    }
    
    @IBAction func canopyPhotoTapped(_ sender: UIButton) {
        capturePhoto(type: .canopy)
    }
    
    private func capturePhoto(type: TreeScoreCalculator.TreePhotoType) {
        currentPhotoType = type
        
        // Show instructions alert first
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
            showAlert(title: "Camera Error", message: "Camera is not available on this device.")
            return
        }
        
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            present(imagePickerController, animated: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.present(self.imagePickerController, animated: true)
                    } else {
                        self.showAlert(title: "Camera Access", message: "Camera access is required to document trees.")
                    }
                }
            }
        case .denied, .restricted:
            showAlert(title: "Camera Access", message: "Please enable camera access in Settings to document trees.")
        @unknown default:
            break
        }
    }
    
    // MARK: - Data Updates
    @objc private func measurementChanged() {
        updateTreeScoreDisplay()
        updateSaveButtonState()
    }
    
    private func updateTreeScoreDisplay() {
        let height = Double(heightTextField.text ?? "") ?? 0
        let canopyRadius = Double(canopyRadiusTextField.text ?? "") ?? 0
        let dbh = Double(dbhTextField.text ?? "") ?? 0
        
        if height > 0 && canopyRadius > 0 && dbh > 0 {
            let treeScore = TreeScoreCalculator.calculateTreeScore(
                height: height,
                canopyRadius: canopyRadius,
                dbh: dbh,
                afissHazardImpact: 0 // TODO: Add AFISS calculation
            )
            treeScoreLabel.text = "TreeScore: \(String(format: "%.0f", treeScore))"
        } else {
            treeScoreLabel.text = "TreeScore: Not calculated"
        }
    }
    
    private func updateLocationDisplay() {
        if treeMark.latitude != 0 && treeMark.longitude != 0 {
            locationLabel.text = "📍 \(String(format: "%.6f", treeMark.latitude)), \(String(format: "%.6f", treeMark.longitude))"
        } else {
            locationLabel.text = "📍 Location not recorded"
        }
    }
    
    private func updatePhotoProgress() {
        let photoCount = [treeMark.overviewPhotoData, treeMark.trunkPhotoData, treeMark.canopyPhotoData].compactMap { $0 }.count
        photoProgressLabel.text = "\(photoCount)/3 required photos captured"
        
        if photoCount == 3 {
            photoProgressLabel.textColor = UIColor.systemGreen
        } else {
            photoProgressLabel.textColor = UIColor.systemOrange
        }
    }
    
    private func updateSaveButtonState() {
        let hasAllMeasurements = !(heightTextField.text?.isEmpty ?? true) &&
                                !(canopyRadiusTextField.text?.isEmpty ?? true) &&
                                !(dbhTextField.text?.isEmpty ?? true)
        
        let hasAllPhotos = treeMark.overviewPhotoData != nil &&
                          treeMark.trunkPhotoData != nil &&
                          treeMark.canopyPhotoData != nil
        
        let canSave = hasAllMeasurements && hasAllPhotos
        
        saveButton.isEnabled = canSave
        navigationItem.rightBarButtonItem?.isEnabled = canSave
        
        if canSave {
            saveButton.backgroundColor = UIColor.systemGreen
            saveButton.setTitle("✓ Save Tree Documentation", for: .normal)
        } else {
            saveButton.backgroundColor = UIColor.systemGray
            let missingItems = []
            if !hasAllMeasurements { missingItems.append("measurements") }
            if !hasAllPhotos { missingItems.append("photos") }
            saveButton.setTitle("Missing: \(missingItems.joined(separator: ", "))", for: .normal)
        }
    }
    
    // MARK: - Save/Cancel Actions
    @objc private func cancelButtonTapped() {
        let alert = UIAlertController(
            title: "Discard Changes?",
            message: "Any unsaved changes will be lost.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        saveTreeDocumentation()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        saveTreeDocumentation()
    }
    
    private func saveTreeDocumentation() {
        // Validate all required data
        let height = Double(heightTextField.text ?? "") ?? 0
        let canopyRadius = Double(canopyRadiusTextField.text ?? "") ?? 0
        let dbh = Double(dbhTextField.text ?? "") ?? 0
        
        let photos: [String: Data?] = [
            TreeScoreCalculator.TreePhotoType.overview.rawValue: treeMark.overviewPhotoData,
            TreeScoreCalculator.TreePhotoType.trunk.rawValue: treeMark.trunkPhotoData,
            TreeScoreCalculator.TreePhotoType.canopy.rawValue: treeMark.canopyPhotoData
        ]
        
        let validationErrors = TreeScoreCalculator.validateTreeData(
            height: height,
            canopyRadius: canopyRadius,
            dbh: dbh,
            photos: photos
        )
        
        if !validationErrors.isEmpty {
            showAlert(
                title: "Validation Error",
                message: "Please complete all requirements:\n" + validationErrors.joined(separator: "\n")
            )
            return
        }
        
        // Save measurements
        treeMark.height = height
        treeMark.canopyRadius = canopyRadius
        treeMark.dbh = dbh
        treeMark.species = speciesTextField.text
        
        // Save condition
        let conditions = ["Excellent", "Good", "Fair", "Poor", "Hazardous"]
        if conditionSegmentedControl.selectedSegmentIndex >= 0 {
            treeMark.healthStatus = conditions[conditionSegmentedControl.selectedSegmentIndex]
        }
        
        // Calculate and save TreeScore
        let finalTreeScore = TreeScoreCalculator.calculateTreeScore(
            height: height,
            canopyRadius: canopyRadius,
            dbh: dbh,
            afissHazardImpact: 0 // TODO: Add AFISS calculation
        )
        treeMark.treeScore = finalTreeScore
        
        // Update status and timestamps
        treeMark.status = TreeScoreCalculator.TreeStatus.measured.rawValue
        treeMark.dateMarked = Date()
        
        // Save to Core Data
        do {
            let context = treeMark.managedObjectContext
            try context?.save()
            
            // Show success message
            let alert = UIAlertController(
                title: "Tree Documented",
                message: "TreeScore: \(String(format: "%.0f", finalTreeScore))\\nAll photos and measurements saved.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            present(alert, animated: true)
            
        } catch {
            showAlert(title: "Save Error", message: "Failed to save tree documentation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension TreeDocumentationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
              let currentPhotoType = currentPhotoType else {
            picker.dismiss(animated: true)
            return
        }
        
        // Compress image for storage
        let compressedData = compressImage(selectedImage, maxSizeKB: 500)
        
        // Save photo data based on type
        switch currentPhotoType {
        case .overview:
            treeMark.overviewPhotoData = compressedData
            overviewPhotoImageView.image = selectedImage
            overviewPhotoButton.setTitle("✓ \(currentPhotoType.displayName)", for: .normal)
            overviewPhotoButton.backgroundColor = UIColor.systemGreen
            
        case .trunk:
            treeMark.trunkPhotoData = compressedData
            trunkPhotoImageView.image = selectedImage
            trunkPhotoButton.setTitle("✓ \(currentPhotoType.displayName)", for: .normal)
            trunkPhotoButton.backgroundColor = UIColor.systemGreen
            
        case .canopy:
            treeMark.canopyPhotoData = compressedData
            canopyPhotoImageView.image = selectedImage
            canopyPhotoButton.setTitle("✓ \(currentPhotoType.displayName)", for: .normal)
            canopyPhotoButton.backgroundColor = UIColor.systemGreen
        }
        
        // Update UI
        updatePhotoProgress()
        updateSaveButtonState()
        
        // Clear current photo type
        self.currentPhotoType = nil
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentPhotoType = nil
        picker.dismiss(animated: true)
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxSize = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // Compress until under max size
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compression) {
                imageData = compressedData
            }
        }
        
        return imageData
    }
}