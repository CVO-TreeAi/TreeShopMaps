import UIKit
import CoreLocation

/// Step 1: Location Input with GPS Integration
class LocationStepViewController: UIViewController, StepValidatable {
    
    private let assessmentData: AssessmentData
    private let currentLocation: CLLocationCoordinate2D?
    
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var locationTextField: UITextField!
    private var useCurrentLocationButton: UIButton!
    private var validationBadge: UIView!
    
    init(assessmentData: AssessmentData, currentLocation: CLLocationCoordinate2D?) {
        self.assessmentData = assessmentData
        self.currentLocation = currentLocation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationStep()
        updateValidationState()
    }
    
    private func setupLocationStep() {
        view.backgroundColor = .clear
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Title Section
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 8
        titleStack.alignment = .center
        
        titleLabel = UILabel()
        titleLabel.text = "Tree Location"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        
        subtitleLabel = UILabel()
        subtitleLabel.text = "Where is this tree located?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        mainStack.addArrangedSubview(titleStack)
        
        // Location Input
        let inputContainer = UIView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        
        locationTextField = UITextField()
        locationTextField.placeholder = "Enter address or location description"
        locationTextField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        locationTextField.textAlignment = .center
        locationTextField.backgroundColor = TreeShopTheme.buttonBackground
        locationTextField.textColor = TreeShopTheme.primaryText
        locationTextField.layer.cornerRadius = 12
        locationTextField.layer.borderWidth = 2
        locationTextField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        locationTextField.leftView = paddingView
        locationTextField.leftViewMode = .always
        locationTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        locationTextField.rightViewMode = .always
        
        locationTextField.addTarget(self, action: #selector(locationTextChanged), for: .editingChanged)
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(locationTextField)
        
        mainStack.addArrangedSubview(inputContainer)
        
        // Current Location Button
        useCurrentLocationButton = UIButton(type: .system)
        useCurrentLocationButton.setTitle("📍 Use Current GPS Location", for: .normal)
        useCurrentLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        useCurrentLocationButton.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        useCurrentLocationButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        useCurrentLocationButton.layer.cornerRadius = 8
        useCurrentLocationButton.layer.borderWidth = 1
        useCurrentLocationButton.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        useCurrentLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        
        mainStack.addArrangedSubview(useCurrentLocationButton)
        
        // Validation Badge
        validationBadge = createValidationBadge()
        validationBadge.isHidden = true
        mainStack.addArrangedSubview(validationBadge)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            inputContainer.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            inputContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            locationTextField.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            locationTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor),
            locationTextField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            locationTextField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            locationTextField.heightAnchor.constraint(equalToConstant: 56),
            
            useCurrentLocationButton.heightAnchor.constraint(equalToConstant: 44),
            useCurrentLocationButton.widthAnchor.constraint(equalToConstant: 240)
        ])
        
        // Pre-fill if location is available
        if let location = currentLocation {
            let locationString = String(format: "%.6f, %.6f", location.latitude, location.longitude)
            locationTextField.text = locationString
            assessmentData.locationText = locationString
            updateValidationState()
        }
    }
    
    private func createValidationBadge() -> UIView {
        let container = UIView()
        container.backgroundColor = TreeShopTheme.successGreen.withAlphaComponent(0.1)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = TreeShopTheme.successGreen.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "✓"
        iconLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        iconLabel.textColor = TreeShopTheme.successGreen
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = "Location recorded"
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        textLabel.textColor = TreeShopTheme.successGreen
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconLabel)
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            textLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 6),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            textLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return container
    }
    
    @objc private func locationTextChanged() {
        let text = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        assessmentData.locationText = text
        updateValidationState()
        
        // Visual feedback
        if !text.isEmpty {
            UIView.animate(withDuration: 0.2) {
                self.locationTextField.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
                self.locationTextField.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.05)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.locationTextField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
                self.locationTextField.backgroundColor = TreeShopTheme.buttonBackground
            }
        }
    }
    
    @objc private func useCurrentLocationTapped() {
        guard let location = currentLocation else {
            showLocationAlert()
            return
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.useCurrentLocationButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.useCurrentLocationButton.transform = .identity
            }
        }
        
        // Set location
        let locationString = String(format: "GPS: %.6f, %.6f", location.latitude, location.longitude)
        locationTextField.text = locationString
        assessmentData.locationText = locationString
        assessmentData.coordinate = location
        
        updateValidationState()
    }
    
    private func updateValidationState() {
        let isValid = validateStep()
        
        UIView.animate(withDuration: 0.3) {
            self.validationBadge.isHidden = !isValid
            self.validationBadge.alpha = isValid ? 1.0 : 0.0
        }
        
        // Update text field appearance
        if isValid {
            locationTextField.layer.borderColor = TreeShopTheme.successGreen.cgColor
            locationTextField.backgroundColor = TreeShopTheme.successGreen.withAlphaComponent(0.05)
        }
    }
    
    private func showLocationAlert() {
        let alert = UIAlertController(
            title: "Location Not Available",
            message: "GPS location is not available. Please enter the location manually or enable location services.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - StepValidatable
    func validateStep() -> Bool {
        let text = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !text.isEmpty
    }
}