import UIKit
import CoreLocation

/// PROFESSIONAL 7-STEP TREE ASSESSMENT WORKFLOW - ALL-IN-ONE IMPLEMENTATION
/// Based on TreeAI SaaS system - converted to Swift with dark mode
class TreeScoreInputViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TreeScoreInputDelegate?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    var prefilledServicePackage: ServicePackage?
    
    // Assessment Steps
    private let steps = [
        ("location", "Location", 14),
        ("measurements", "Measurements", 28),
        ("species", "Species", 42),
        ("health", "Health", 56),
        ("afiss", "AFISS", 70),
        ("photos", "Photos", 84),
        ("results", "Results", 100)
    ]
    
    private var currentStepIndex = 0
    private var assessmentData = ProfessionalAssessmentData()
    
    // UI Elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerCard: UIView!
    private var progressBar: UIProgressView!
    private var stepLabel: UILabel!
    private var progressLabel: UILabel!
    private var stepBreadcrumbs: UIStackView!
    
    private var mainCard: UIView!
    private var stepContentView: UIView!
    
    private var navigationButtons: UIStackView!
    private var prevButton: UIButton!
    private var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfessionalAssessment()
    }
    
    private func setupProfessionalAssessment() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        setupScrollView()
        setupHeaderCard()
        setupMainCard()
        setupNavigationButtons()
        
        // Initialize assessment data
        assessmentData.coordinate = currentLocation
        assessmentData.accuracy = locationAccuracy
        
        // Show first step
        showStep(0)
    }
    
    // MARK: - UI Setup
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHeaderCard() {
        headerCard = TreeShopTheme.cardView()
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerCard)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "🌲 TreeShop Professional Assessment"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(titleLabel)
        
        let subtitle = UILabel()
        subtitle.text = "Advanced field data collection & TreeScore calculation"
        subtitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitle.textColor = TreeShopTheme.secondaryText
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(subtitle)
        
        // Step info
        let stepInfo = UIStackView()
        stepInfo.axis = .horizontal
        stepInfo.distribution = .equalSpacing
        stepInfo.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(stepInfo)
        
        stepLabel = UILabel()
        stepLabel.text = "Location"
        stepLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        stepLabel.textColor = TreeShopTheme.primaryText
        
        progressLabel = UILabel()
        progressLabel.text = "14%"
        progressLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textColor = TreeShopTheme.primaryGreen
        
        stepInfo.addArrangedSubview(stepLabel)
        stepInfo.addArrangedSubview(progressLabel)
        
        // Progress Bar
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.progressTintColor = TreeShopTheme.primaryGreen
        progressBar.trackTintColor = TreeShopTheme.buttonBackground
        progressBar.layer.cornerRadius = 2
        progressBar.layer.masksToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(progressBar)
        
        // Step Badge
        let stepBadge = UILabel()
        stepBadge.text = "Step 1 of 7"
        stepBadge.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        stepBadge.textColor = TreeShopTheme.primaryGreen
        stepBadge.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        stepBadge.layer.cornerRadius = 8
        stepBadge.layer.masksToBounds = true
        stepBadge.textAlignment = .center
        stepBadge.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(stepBadge)
        
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            
            subtitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitle.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            
            stepBadge.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            stepBadge.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            stepBadge.widthAnchor.constraint(equalToConstant: 80),
            stepBadge.heightAnchor.constraint(equalToConstant: 28),
            
            stepInfo.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 20),
            stepInfo.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            stepInfo.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            
            progressBar.topAnchor.constraint(equalTo: stepInfo.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            progressBar.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupMainCard() {
        mainCard = TreeShopTheme.cardView()
        mainCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainCard)
        
        stepContentView = UIView()
        stepContentView.translatesAutoresizingMaskIntoConstraints = false
        mainCard.addSubview(stepContentView)
        
        NSLayoutConstraint.activate([
            mainCard.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 16),
            mainCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stepContentView.topAnchor.constraint(equalTo: mainCard.topAnchor, constant: 32),
            stepContentView.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 32),
            stepContentView.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -32),
            stepContentView.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -32),
            stepContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }
    
    private func setupNavigationButtons() {
        navigationButtons = UIStackView()
        navigationButtons.axis = .horizontal
        navigationButtons.distribution = .fillEqually
        navigationButtons.spacing = 16
        navigationButtons.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(navigationButtons)
        
        prevButton = TreeShopTheme.styledButton(title: "← Previous")
        prevButton.backgroundColor = TreeShopTheme.secondaryGray
        prevButton.isEnabled = false
        prevButton.alpha = 0.5
        prevButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        
        nextButton = TreeShopTheme.styledButton(title: "Next →")
        nextButton.backgroundColor = TreeShopTheme.primaryGreen
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        navigationButtons.addArrangedSubview(prevButton)
        navigationButtons.addArrangedSubview(nextButton)
        
        NSLayoutConstraint.activate([
            navigationButtons.topAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: 24),
            navigationButtons.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            navigationButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            navigationButtons.heightAnchor.constraint(equalToConstant: 56),
            navigationButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Step Navigation
    private func showStep(_ stepIndex: Int) {
        guard stepIndex >= 0 && stepIndex < steps.count else { return }
        
        currentStepIndex = stepIndex
        let (stepId, stepName, progress) = steps[stepIndex]
        
        // Update header
        stepLabel.text = stepName
        progressLabel.text = "\(progress)%"
        progressBar.setProgress(Float(progress) / 100.0, animated: true)
        
        // Update step badge
        if let stepBadge = headerCard.subviews.compactMap({ $0 as? UILabel }).first(where: { $0.text?.contains("Step") == true }) {
            stepBadge.text = "Step \(stepIndex + 1) of \(steps.count)"
        }
        
        // Clear previous content
        stepContentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Show step content
        showStepContent(stepId)
        
        // Update navigation buttons
        updateNavigationButtons()
        
        // Animate transition
        UIView.animate(withDuration: 0.3) {
            self.stepContentView.alpha = 1.0
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func showStepContent(_ stepId: String) {
        switch stepId {
        case "location":
            showLocationStep()
        case "measurements":
            showMeasurementsStep()
        case "species":
            showSpeciesStep()
        case "health":
            showHealthStep()
        case "afiss":
            showAFISSStep()
        case "photos":
            showPhotosStep()
        case "results":
            showResultsStep()
        default:
            break
        }
    }
    
    private func showLocationStep() {
        let titleLabel = UILabel()
        titleLabel.text = "📍 Tree Location"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Where is this tree located?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(subtitleLabel)
        
        let locationTextField = UITextField()
        locationTextField.placeholder = "Enter address or location description"
        locationTextField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        locationTextField.textAlignment = .center
        locationTextField.backgroundColor = TreeShopTheme.buttonBackground
        locationTextField.textColor = TreeShopTheme.primaryText
        locationTextField.layer.cornerRadius = 12
        locationTextField.layer.borderWidth = 2
        locationTextField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        locationTextField.text = assessmentData.locationText
        locationTextField.tag = 1001
        locationTextField.addTarget(self, action: #selector(locationTextChanged), for: .editingChanged)
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(locationTextField)
        
        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        locationTextField.leftView = paddingView
        locationTextField.leftViewMode = .always
        locationTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        locationTextField.rightViewMode = .always
        
        let useGPSButton = UIButton(type: .system)
        useGPSButton.setTitle("📍 Use Current GPS Location", for: .normal)
        useGPSButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        useGPSButton.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        useGPSButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        useGPSButton.layer.cornerRadius = 8
        useGPSButton.layer.borderWidth = 1
        useGPSButton.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        useGPSButton.addTarget(self, action: #selector(useGPSLocation), for: .touchUpInside)
        useGPSButton.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(useGPSButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            locationTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            locationTextField.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            locationTextField.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            locationTextField.leadingAnchor.constraint(greaterThanOrEqualTo: stepContentView.leadingAnchor),
            locationTextField.trailingAnchor.constraint(lessThanOrEqualTo: stepContentView.trailingAnchor),
            locationTextField.heightAnchor.constraint(equalToConstant: 56),
            
            useGPSButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 20),
            useGPSButton.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            useGPSButton.widthAnchor.constraint(equalToConstant: 240),
            useGPSButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Pre-fill GPS location if available
        if assessmentData.locationText.isEmpty, let location = currentLocation {
            locationTextField.text = String(format: "GPS: %.6f, %.6f", location.latitude, location.longitude)
            assessmentData.locationText = locationTextField.text ?? ""
        }
    }
    
    private func showMeasurementsStep() {
        let titleLabel = UILabel()
        titleLabel.text = "📏 Tree Measurements"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Precise measurements for TreeScore calculation"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(subtitleLabel)
        
        // Create measurement inputs
        let measurementStack = UIStackView()
        measurementStack.axis = .vertical
        measurementStack.spacing = 20
        measurementStack.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(measurementStack)
        
        let heightField = createLargeMeasurementInput(title: "Height (feet)", placeholder: "40", tag: 2001)
        let crownField = createLargeMeasurementInput(title: "Crown Radius (feet)", placeholder: "12", tag: 2002)
        let dbhField = createLargeMeasurementInput(title: "DBH (inches)", placeholder: "18", tag: 2003)
        
        measurementStack.addArrangedSubview(heightField)
        measurementStack.addArrangedSubview(crownField)
        measurementStack.addArrangedSubview(dbhField)
        
        // Preview score
        let previewLabel = UILabel()
        previewLabel.text = "Preview TreeScore: \(Int(calculatePreviewScore()))"
        previewLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        previewLabel.textColor = TreeShopTheme.primaryGreen
        previewLabel.textAlignment = .center
        previewLabel.tag = 2010
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(previewLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            measurementStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            measurementStack.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            measurementStack.widthAnchor.constraint(lessThanOrEqualToConstant: 350),
            
            previewLabel.topAnchor.constraint(equalTo: measurementStack.bottomAnchor, constant: 20),
            previewLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor)
        ])
    }
    
    private func createLargeMeasurementInput(title: String, placeholder: String, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.backgroundColor = TreeShopTheme.buttonBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        textField.tag = tag
        textField.addTarget(self, action: #selector(measurementChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)
        
        // Set existing values
        switch tag {
        case 2001: textField.text = assessmentData.height != nil ? String(format: "%.1f", assessmentData.height!) : ""
        case 2002: textField.text = assessmentData.crownRadius != nil ? String(format: "%.1f", assessmentData.crownRadius!) : ""
        case 2003: textField.text = assessmentData.dbh != nil ? String(format: "%.1f", assessmentData.dbh!) : ""
        default: break
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 140),
            textField.heightAnchor.constraint(equalToConstant: 72),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func showSpeciesStep() {
        let titleLabel = UILabel()
        titleLabel.text = "🌳 Species Selection"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let textField = UITextField()
        textField.placeholder = "Enter tree species (Oak, Pine, Maple...)"
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textAlignment = .center
        textField.backgroundColor = TreeShopTheme.buttonBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.layer.cornerRadius = 12
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
            textField.widthAnchor.constraint(equalToConstant: 300),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func showHealthStep() {
        let titleLabel = UILabel()
        titleLabel.text = "💚 Health Assessment"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let healthOptions = ["Excellent", "Good", "Fair", "Poor", "Critical"]
        let segmentedControl = UISegmentedControl(items: healthOptions)
        segmentedControl.selectedSegmentIndex = assessmentData.health.isEmpty ? 1 : (healthOptions.firstIndex(of: assessmentData.health) ?? 1)
        segmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        segmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        segmentedControl.tag = 4001
        segmentedControl.addTarget(self, action: #selector(healthChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(segmentedControl)
        
        // Set default if empty
        if assessmentData.health.isEmpty {
            assessmentData.health = "Good"
        }
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -30),
            
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            segmentedControl.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 350),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func showAFISSStep() {
        let titleLabel = UILabel()
        titleLabel.text = "⚡ AFISS Risk Assessment"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select applicable risk factors"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(subtitleLabel)
        
        let riskStack = UIStackView()
        riskStack.axis = .vertical
        riskStack.spacing = 12
        riskStack.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(riskStack)
        
        let risks = ["Power lines nearby", "Near buildings", "Cracked trunk", "Dead branches", "Access issues"]
        
        for (index, risk) in risks.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle("☐ \(risk)", for: .normal)
            button.setTitle("✓ \(risk)", for: .selected)
            button.setTitleColor(TreeShopTheme.primaryText, for: .normal)
            button.setTitleColor(TreeShopTheme.primaryGreen, for: .selected)
            button.backgroundColor = TreeShopTheme.buttonBackground
            button.layer.cornerRadius = 8
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            button.tag = 5000 + index
            button.addTarget(self, action: #selector(riskToggled), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Set existing state
            let riskIds = ["power-lines", "buildings", "cracks", "dead-branches", "access"]
            button.isSelected = assessmentData.riskFactors.contains(riskIds[index])
            
            riskStack.addArrangedSubview(button)
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            riskStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            riskStack.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            riskStack.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func showPhotosStep() {
        let titleLabel = UILabel()
        titleLabel.text = "📷 Photo Documentation"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Optional - Take up to 3 photos"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(subtitleLabel)
        
        let photoButton = UIButton(type: .system)
        photoButton.setTitle("📷 Take Photos (Optional)", for: .normal)
        photoButton.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        photoButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        photoButton.layer.cornerRadius = 8
        photoButton.layer.borderWidth = 1
        photoButton.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(photoButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: stepContentView.centerYAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            photoButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            photoButton.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 240),
            photoButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func showResultsStep() {
        let titleLabel = UILabel()
        titleLabel.text = "🎯 Assessment Complete!"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentView.addSubview(titleLabel)
        
        // Calculate final TreeScore
        let finalScore = calculateFinalTreeScore()
        
        // Score Display
        let scoreCard = TreeShopTheme.cardView()
        scoreCard.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        scoreCard.layer.borderWidth = 2
        scoreCard.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        scoreCard.translatesAutoresizingMaskIntoConstraints = false
        
        let scoreLabel = UILabel()
        scoreLabel.text = String(format: "%.0f", finalScore)
        scoreLabel.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        scoreLabel.textColor = TreeShopTheme.primaryGreen
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreCard.addSubview(scoreLabel)
        
        let scoreTitleLabel = UILabel()
        scoreTitleLabel.text = "TreeScore"
        scoreTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        scoreTitleLabel.textColor = TreeShopTheme.primaryText
        scoreTitleLabel.textAlignment = .center
        scoreTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreCard.addSubview(scoreTitleLabel)
        
        let complexityLabel = UILabel()
        let complexity = finalScore < 500 ? "Low Complexity" : finalScore < 1500 ? "Medium Complexity" : "High Complexity"
        complexityLabel.text = complexity
        complexityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        complexityLabel.textColor = TreeShopTheme.secondaryText
        complexityLabel.textAlignment = .center
        complexityLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreCard.addSubview(complexityLabel)
        
        stepContentView.addSubview(scoreCard)
        
        // Add to Inventory Button
        let addButton = TreeShopTheme.styledButton(title: "🌲 Add Tree to Inventory")
        addButton.backgroundColor = TreeShopTheme.primaryGreen
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        addButton.addTarget(self, action: #selector(addToInventory), for: .touchUpInside)
        stepContentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            
            scoreCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scoreCard.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            scoreCard.widthAnchor.constraint(equalToConstant: 280),
            
            scoreLabel.topAnchor.constraint(equalTo: scoreCard.topAnchor, constant: 32),
            scoreLabel.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            
            scoreTitleLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            scoreTitleLabel.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            
            complexityLabel.topAnchor.constraint(equalTo: scoreTitleLabel.bottomAnchor, constant: 4),
            complexityLabel.centerXAnchor.constraint(equalTo: scoreCard.centerXAnchor),
            complexityLabel.bottomAnchor.constraint(equalTo: scoreCard.bottomAnchor, constant: -32),
            
            addButton.topAnchor.constraint(equalTo: scoreCard.bottomAnchor, constant: 30),
            addButton.centerXAnchor.constraint(equalTo: stepContentView.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 280),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Hide navigation buttons for results step
        navigationButtons.isHidden = true
    }
    
    private func updateNavigationButtons() {
        // Previous button
        prevButton.isEnabled = currentStepIndex > 0
        prevButton.alpha = currentStepIndex > 0 ? 1.0 : 0.5
        
        // Next button
        let isLastStep = currentStepIndex == steps.count - 1
        nextButton.setTitle(isLastStep ? "Complete Assessment" : "Next →", for: .normal)
        nextButton.backgroundColor = isLastStep ? TreeShopTheme.successGreen : TreeShopTheme.primaryGreen
        nextButton.isEnabled = validateCurrentStep()
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.6
        
        // Hide navigation buttons on results step
        navigationButtons.isHidden = isLastStep
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStepIndex {
        case 0: return !assessmentData.locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return assessmentData.height != nil && assessmentData.crownRadius != nil && assessmentData.dbh != nil
        case 2: return !assessmentData.species.isEmpty
        case 3: return !assessmentData.health.isEmpty
        default: return true
        }
    }
    
    private func calculatePreviewScore() -> Double {
        guard let height = assessmentData.height,
              let crownRadius = assessmentData.crownRadius,
              let dbh = assessmentData.dbh else { return 0 }
        
        return (height * crownRadius * 2 * dbh) / 12
    }
    
    private func calculateFinalTreeScore() -> Double {
        let baseScore = calculatePreviewScore()
        let afissMultiplier = 1 + (Double(assessmentData.riskFactors.count) * 0.08)
        return baseScore * afissMultiplier
    }
    
    // MARK: - Actions
    @objc private func previousButtonTapped() {
        if currentStepIndex > 0 {
            showStep(currentStepIndex - 1)
        }
    }
    
    @objc private func nextButtonTapped() {
        if validateCurrentStep() {
            if currentStepIndex < steps.count - 1 {
                showStep(currentStepIndex + 1)
            }
        }
    }
    
    @objc private func locationTextChanged(_ textField: UITextField) {
        assessmentData.locationText = textField.text ?? ""
        updateNavigationButtons()
    }
    
    @objc private func useGPSLocation() {
        if let location = currentLocation,
           let textField = stepContentView.viewWithTag(1001) as? UITextField {
            let locationString = String(format: "GPS: %.6f, %.6f", location.latitude, location.longitude)
            textField.text = locationString
            assessmentData.locationText = locationString
            updateNavigationButtons()
        }
    }
    
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
        
        updateNavigationButtons()
    }
    
    @objc private func speciesChanged(_ textField: UITextField) {
        assessmentData.species = textField.text ?? ""
        updateNavigationButtons()
    }
    
    @objc private func healthChanged(_ segmentedControl: UISegmentedControl) {
        let healthOptions = ["Excellent", "Good", "Fair", "Poor", "Critical"]
        assessmentData.health = healthOptions[segmentedControl.selectedSegmentIndex]
        updateNavigationButtons()
    }
    
    @objc private func riskToggled(_ button: UIButton) {
        button.isSelected.toggle()
        let riskIds = ["power-lines", "buildings", "cracks", "dead-branches", "access"]
        let index = button.tag - 5000
        let riskId = riskIds[index]
        
        if button.isSelected {
            if !assessmentData.riskFactors.contains(riskId) {
                assessmentData.riskFactors.append(riskId)
            }
        } else {
            assessmentData.riskFactors.removeAll { $0 == riskId }
        }
    }
    
    @objc private func addToInventory() {
        let treeItem = TreeInventoryItem(
            coordinate: currentLocation ?? CLLocationCoordinate2D(),
            gpsAccuracy: locationAccuracy ?? 0,
            height: assessmentData.height ?? 0,
            canopyRadius: assessmentData.crownRadius ?? 0,
            dbh: assessmentData.dbh ?? 0,
            afissPercentage: min(100.0, Double(assessmentData.riskFactors.count) * 8.0),
            species: assessmentData.species.isEmpty ? nil : assessmentData.species,
            healthStatus: assessmentData.health,
            notes: createNotes(),
            servicePackage: prefilledServicePackage ?? .medium,
            crewPpH: 150.0
        )
        
        delegate?.didCreateTreeInventoryItem(treeItem)
    }
    
    private func createNotes() -> String? {
        var notes: [String] = []
        
        if !assessmentData.locationText.isEmpty {
            notes.append("Location: \(assessmentData.locationText)")
        }
        
        if !assessmentData.riskFactors.isEmpty {
            notes.append("AFISS: \(assessmentData.riskFactors.joined(separator: ", "))")
        }
        
        return notes.isEmpty ? nil : notes.joined(separator: " | ")
    }
    
    // MARK: - Public Methods (maintain compatibility)
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
        assessmentData.coordinate = coordinate
        assessmentData.accuracy = accuracy
    }
    
    func setPrefilledServicePackage(_ package: ServicePackage) {
        prefilledServicePackage = package
    }
}

// MARK: - Professional Assessment Data Model
class ProfessionalAssessmentData {
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