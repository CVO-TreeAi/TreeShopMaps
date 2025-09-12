import UIKit
import MapKit
import CoreLocation

protocol TreeScoreInputDelegate: AnyObject {
    func didCreateTreeInventoryItem(_ item: TreeInventoryItem)
    func didCancelTreeInput()
}

/// Field-optimized TreeScore input for GPS inventory control
class TreeScoreInputViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TreeScoreInputDelegate?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    var prefilledServicePackage: ServicePackage?
    
    // MARK: - UI Elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerView: UIView!
    private var titleLabel: UILabel!
    private var locationLabel: UILabel!
    private var accuracyLabel: UILabel!
    
    // Tree Measurement Inputs
    private var measurementsCard: UIView!
    private var heightSlider: UISlider!
    private var heightLabel: UILabel!
    private var canopySlider: UISlider!
    private var canopyLabel: UILabel!
    private var dbhSlider: UISlider!
    private var dbhLabel: UILabel!
    private var afissSlider: UISlider!
    private var afissLabel: UILabel!
    
    // Additional Info Inputs
    private var speciesTextField: UITextField!
    private var healthSegmentedControl: UISegmentedControl!
    private var servicePackageSelector: UISegmentedControl!
    private var notesTextField: UITextField!
    
    // TreeScore Results Display
    private var resultsCard: UIView!
    private var treeScoreLabel: UILabel!
    private var formulaLabel: UILabel!
    private var estimatedTimeLabel: UILabel!
    private var estimatedCostLabel: UILabel!
    private var complexityIndicator: UIView!
    
    // Action Buttons
    private var calculateButton: UIButton!
    private var saveButton: UIButton!
    private var cancelButton: UIButton!
    
    // Current calculation
    private var currentTreeScore: TreeScoreResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateLocationDisplay()
        
        // Set default values for quick field use
        setDefaultValues()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        // Scroll View
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        setupHeaderView()
        setupMeasurementsCard()
        setupAdditionalInfoSection()
        setupResultsCard()
        setupActionButtons()
    }
    
    private func setupHeaderView() {
        headerView = TreeShopTheme.cardView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Add Tree to Inventory"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        locationLabel = UILabel()
        locationLabel.text = "📍 Getting location..."
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationLabel.textColor = TreeShopTheme.secondaryText
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(locationLabel)
        
        accuracyLabel = UILabel()
        accuracyLabel.text = "🎯 GPS accuracy: Unknown"
        accuracyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        accuracyLabel.textColor = TreeShopTheme.tertiaryText
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(accuracyLabel)
    }
    
    private func setupMeasurementsCard() {
        measurementsCard = TreeShopTheme.cardView()
        measurementsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(measurementsCard)
        
        let titleLabel = UILabel()
        titleLabel.text = "Tree Measurements"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        measurementsCard.addSubview(titleLabel)
        
        // Height Slider
        let heightStack = createSliderStack(
            title: "Height (feet)",
            min: 1, max: 200, value: 40,
            slider: &heightSlider,
            label: &heightLabel
        )
        measurementsCard.addSubview(heightStack)
        
        // Canopy Radius Slider
        let canopyStack = createSliderStack(
            title: "Canopy Radius (feet)",
            min: 1, max: 150, value: 15,
            slider: &canopySlider,
            label: &canopyLabel
        )
        measurementsCard.addSubview(canopyStack)
        
        // DBH Slider
        let dbhStack = createSliderStack(
            title: "DBH (inches)",
            min: 1, max: 120, value: 24,
            slider: &dbhSlider,
            label: &dbhLabel
        )
        measurementsCard.addSubview(dbhStack)
        
        // AFISS Percentage Slider
        let afissStack = createSliderStack(
            title: "AFISS Impact (%)",
            min: 0, max: 100, value: 25,
            slider: &afissSlider,
            label: &afissLabel
        )
        measurementsCard.addSubview(afissStack)
        
        // Layout stacks
        titleLabel.topAnchor.constraint(equalTo: measurementsCard.topAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16).isActive = true
        
        heightStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16).isActive = true
        canopyStack.topAnchor.constraint(equalTo: heightStack.bottomAnchor, constant: 16).isActive = true
        dbhStack.topAnchor.constraint(equalTo: canopyStack.bottomAnchor, constant: 16).isActive = true
        afissStack.topAnchor.constraint(equalTo: dbhStack.bottomAnchor, constant: 16).isActive = true
        afissStack.bottomAnchor.constraint(equalTo: measurementsCard.bottomAnchor, constant: -16).isActive = true
        
        [heightStack, canopyStack, dbhStack, afissStack].forEach { stack in
            stack.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16).isActive = true
            stack.trailingAnchor.constraint(equalTo: measurementsCard.trailingAnchor, constant: -16).isActive = true
        }
    }
    
    private func createSliderStack(title: String, min: Float, max: Float, value: Float, slider: inout UISlider!, label: inout UILabel!) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = TreeShopTheme.primaryText
        
        label = UILabel()
        label.text = String(format: "%.1f", value)
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = TreeShopTheme.primaryGreen
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        
        slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        slider.tintColor = TreeShopTheme.primaryGreen
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, label])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        return mainStack
    }
    
    private func setupAdditionalInfoSection() {
        let infoCard = TreeShopTheme.cardView()
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCard)
        
        let titleLabel = UILabel()
        titleLabel.text = "Additional Information"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(titleLabel)
        
        // Species Text Field
        speciesTextField = UITextField()
        speciesTextField.placeholder = "Tree species (optional)"
        speciesTextField.backgroundColor = TreeShopTheme.buttonBackground
        speciesTextField.textColor = TreeShopTheme.primaryText
        speciesTextField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        speciesTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        speciesTextField.leftViewMode = .always
        speciesTextField.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(speciesTextField)
        
        // Health Status Segmented Control
        let healthLabel = UILabel()
        healthLabel.text = "Health Status"
        healthLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        healthLabel.textColor = TreeShopTheme.primaryText
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(healthLabel)
        
        healthSegmentedControl = UISegmentedControl(items: ["Healthy", "Fair", "Poor"])
        healthSegmentedControl.selectedSegmentIndex = 0
        healthSegmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        healthSegmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        healthSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(healthSegmentedControl)
        
        // Service Package Selector
        let packageLabel = UILabel()
        packageLabel.text = "Service Package"
        packageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        packageLabel.textColor = TreeShopTheme.primaryText
        packageLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(packageLabel)
        
        let packageItems = ServicePackage.allCases.map { $0.rawValue }
        servicePackageSelector = UISegmentedControl(items: packageItems)
        servicePackageSelector.selectedSegmentIndex = prefilledServicePackage?.hash ?? 1 // Default to Medium
        servicePackageSelector.backgroundColor = TreeShopTheme.buttonBackground
        servicePackageSelector.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        servicePackageSelector.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(servicePackageSelector)
        
        // Notes Text Field
        notesTextField = UITextField()
        notesTextField.placeholder = "Notes (optional)"
        notesTextField.backgroundColor = TreeShopTheme.buttonBackground
        notesTextField.textColor = TreeShopTheme.primaryText
        notesTextField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        notesTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        notesTextField.leftViewMode = .always
        notesTextField.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(notesTextField)
        
        // Layout constraints
        titleLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        
        speciesTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16).isActive = true
        speciesTextField.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        speciesTextField.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16).isActive = true
        speciesTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        healthLabel.topAnchor.constraint(equalTo: speciesTextField.bottomAnchor, constant: 16).isActive = true
        healthLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        
        healthSegmentedControl.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 8).isActive = true
        healthSegmentedControl.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        healthSegmentedControl.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16).isActive = true
        
        packageLabel.topAnchor.constraint(equalTo: healthSegmentedControl.bottomAnchor, constant: 16).isActive = true
        packageLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        
        servicePackageSelector.topAnchor.constraint(equalTo: packageLabel.bottomAnchor, constant: 8).isActive = true
        servicePackageSelector.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        servicePackageSelector.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16).isActive = true
        
        notesTextField.topAnchor.constraint(equalTo: servicePackageSelector.bottomAnchor, constant: 16).isActive = true
        notesTextField.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16).isActive = true
        notesTextField.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16).isActive = true
        notesTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        notesTextField.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16).isActive = true
        
        // Store reference to info card for constraints
        infoCard.topAnchor.constraint(equalTo: measurementsCard.bottomAnchor, constant: 16).isActive = true
        infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
    }
    
    private func setupResultsCard() {
        resultsCard = TreeShopTheme.cardView()
        resultsCard.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.isHidden = true
        contentView.addSubview(resultsCard)
        
        let titleLabel = UILabel()
        titleLabel.text = "TreeScore Results"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(titleLabel)
        
        treeScoreLabel = UILabel()
        treeScoreLabel.text = "0 pts"
        treeScoreLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        treeScoreLabel.textColor = TreeShopTheme.primaryGreen
        treeScoreLabel.textAlignment = .center
        treeScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(treeScoreLabel)
        
        complexityIndicator = UIView()
        complexityIndicator.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        complexityIndicator.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(complexityIndicator)
        
        let complexityLabel = UILabel()
        complexityLabel.text = "Complexity"
        complexityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        complexityLabel.textColor = TreeShopTheme.primaryText
        complexityLabel.textAlignment = .center
        complexityLabel.translatesAutoresizingMaskIntoConstraints = false
        complexityIndicator.addSubview(complexityLabel)
        
        formulaLabel = UILabel()
        formulaLabel.text = ""
        formulaLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        formulaLabel.textColor = TreeShopTheme.tertiaryText
        formulaLabel.numberOfLines = 2
        formulaLabel.textAlignment = .center
        formulaLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(formulaLabel)
        
        estimatedTimeLabel = UILabel()
        estimatedTimeLabel.text = ""
        estimatedTimeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        estimatedTimeLabel.textColor = TreeShopTheme.secondaryText
        estimatedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(estimatedTimeLabel)
        
        estimatedCostLabel = UILabel()
        estimatedCostLabel.text = ""
        estimatedCostLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        estimatedCostLabel.textColor = TreeShopTheme.primaryGreen
        estimatedCostLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(estimatedCostLabel)
        
        // Layout constraints for results card
        titleLabel.topAnchor.constraint(equalTo: resultsCard.topAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16).isActive = true
        
        treeScoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16).isActive = true
        treeScoreLabel.centerXAnchor.constraint(equalTo: resultsCard.centerXAnchor).isActive = true
        
        complexityIndicator.topAnchor.constraint(equalTo: treeScoreLabel.bottomAnchor, constant: 8).isActive = true
        complexityIndicator.centerXAnchor.constraint(equalTo: resultsCard.centerXAnchor).isActive = true
        complexityIndicator.widthAnchor.constraint(equalToConstant: 100).isActive = true
        complexityIndicator.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        complexityLabel.centerXAnchor.constraint(equalTo: complexityIndicator.centerXAnchor).isActive = true
        complexityLabel.centerYAnchor.constraint(equalTo: complexityIndicator.centerYAnchor).isActive = true
        
        formulaLabel.topAnchor.constraint(equalTo: complexityIndicator.bottomAnchor, constant: 12).isActive = true
        formulaLabel.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16).isActive = true
        formulaLabel.trailingAnchor.constraint(equalTo: resultsCard.trailingAnchor, constant: -16).isActive = true
        
        estimatedTimeLabel.topAnchor.constraint(equalTo: formulaLabel.bottomAnchor, constant: 12).isActive = true
        estimatedTimeLabel.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16).isActive = true
        
        estimatedCostLabel.topAnchor.constraint(equalTo: estimatedTimeLabel.bottomAnchor, constant: 8).isActive = true
        estimatedCostLabel.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16).isActive = true
        estimatedCostLabel.bottomAnchor.constraint(equalTo: resultsCard.bottomAnchor, constant: -16).isActive = true
    }
    
    private func setupActionButtons() {
        calculateButton = TreeShopTheme.styledButton(title: "Calculate TreeScore")
        calculateButton.backgroundColor = TreeShopTheme.primaryGreen
        calculateButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(calculateButton)
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        cancelButton = TreeShopTheme.styledButton(title: "Cancel")
        cancelButton.backgroundColor = TreeShopTheme.errorRed
        
        saveButton = TreeShopTheme.styledButton(title: "Save to Inventory")
        saveButton.backgroundColor = TreeShopTheme.successGreen
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            accuracyLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            accuracyLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            accuracyLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Measurements Card
            measurementsCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            measurementsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            measurementsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Calculate Button
            calculateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            calculateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            calculateButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Results Card (will be positioned dynamically)
            resultsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resultsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Button Stack
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // We'll set these constraints dynamically
        updateLayoutConstraints()
    }
    
    private func updateLayoutConstraints() {
        if resultsCard.isHidden {
            // Position calculate button after info card
            calculateButton.topAnchor.constraint(equalTo: contentView.subviews[contentView.subviews.count - 3].bottomAnchor, constant: 24).isActive = true
        } else {
            // Position calculate button after measurements, results after calculate button
            resultsCard.topAnchor.constraint(equalTo: calculateButton.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    private func setupActions() {
        calculateButton.addTarget(self, action: #selector(calculateButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let value = slider.value
        
        switch slider {
        case heightSlider:
            heightLabel.text = String(format: "%.1f", value)
        case canopySlider:
            canopyLabel.text = String(format: "%.1f", value)
        case dbhSlider:
            dbhLabel.text = String(format: "%.1f", value)
        case afissSlider:
            afissLabel.text = String(format: "%.0f", value)
        default:
            break
        }
        
        // Auto-calculate if we have valid inputs
        if value > 0 {
            calculateTreeScore()
        }
    }
    
    @objc private func calculateButtonTapped() {
        calculateTreeScore()
    }
    
    @objc private func saveButtonTapped() {
        guard let location = currentLocation,
              let accuracy = locationAccuracy,
              let treeScore = currentTreeScore else { return }
        
        let selectedPackage = ServicePackage.allCases[servicePackageSelector.selectedSegmentIndex]
        let healthStatus = ["Healthy", "Fair", "Poor"][healthSegmentedControl.selectedSegmentIndex]
        
        let treeItem = TreeInventoryItem(
            coordinate: location,
            gpsAccuracy: accuracy,
            height: Double(heightSlider.value),
            canopyRadius: Double(canopySlider.value),
            dbh: Double(dbhSlider.value),
            afissPercentage: Double(afissSlider.value),
            species: speciesTextField.text?.isEmpty == false ? speciesTextField.text : nil,
            healthStatus: healthStatus,
            notes: notesTextField.text?.isEmpty == false ? notesTextField.text : nil,
            servicePackage: selectedPackage,
            crewPpH: 150.0 // Default PpH - could be configured
        )
        
        delegate?.didCreateTreeInventoryItem(treeItem)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelTreeInput()
    }
    
    // MARK: - TreeScore Calculation
    private func calculateTreeScore() {
        let height = Double(heightSlider.value)
        let canopyRadius = Double(canopySlider.value)
        let dbh = Double(dbhSlider.value)
        let afiss = Double(afissSlider.value)
        
        currentTreeScore = TreeScoreCalculator.calculateTreeScore(
            height: height,
            canopyRadius: canopyRadius,
            dbh: dbh,
            afissPercentage: afiss,
            gpsAccuracy: locationAccuracy
        )
        
        updateResultsDisplay()
    }
    
    private func updateResultsDisplay() {
        guard let treeScore = currentTreeScore else { return }
        
        resultsCard.isHidden = false
        
        treeScoreLabel.text = String(format: "%.0f pts", treeScore.finalTreeScore)
        formulaLabel.text = treeScore.formula
        
        // Determine complexity level and color
        let complexity: TreeComplexity
        switch treeScore.finalTreeScore {
        case 0..<500:
            complexity = .low
        case 500..<1500:
            complexity = .medium
        case 1500..<3000:
            complexity = .high
        default:
            complexity = .extreme
        }
        
        complexityIndicator.backgroundColor = complexity.color
        if let complexityLabel = complexityIndicator.subviews.first as? UILabel {
            complexityLabel.text = complexity.rawValue
        }
        
        // Calculate estimates
        let selectedPackage = ServicePackage.allCases[servicePackageSelector.selectedSegmentIndex]
        let estimatedHours = TreeScoreCalculator.convertTreeScoreToTime(treeScore: treeScore.finalTreeScore, crewPpH: 150.0)
        let estimatedCost = TreeScoreCalculator.calculateEstimatedBilling(
            treeScore: treeScore.finalTreeScore,
            servicePackage: selectedPackage,
            crewPpH: 150.0
        )
        
        estimatedTimeLabel.text = "⏱ Estimated Time: \(String(format: "%.1f hours", estimatedHours))"
        estimatedCostLabel.text = "💰 Estimated Cost: $\(String(format: "%.0f", estimatedCost))"
        
        // Enable save button
        saveButton.isEnabled = true
        saveButton.alpha = 1.0
        
        // Update layout
        view.layoutIfNeeded()
    }
    
    private func setDefaultValues() {
        // Set reasonable defaults for quick field entry
        heightSlider.value = 40
        canopySlider.value = 15  
        dbhSlider.value = 24
        afissSlider.value = 25
        
        // Update labels
        heightLabel.text = "40.0"
        canopyLabel.text = "15.0"
        dbhLabel.text = "24.0"
        afissLabel.text = "25"
    }
    
    private func updateLocationDisplay() {
        guard let location = currentLocation else {
            locationLabel.text = "📍 Location not available"
            accuracyLabel.text = "🎯 GPS accuracy: Unknown"
            return
        }
        
        locationLabel.text = String(format: "📍 %.6f, %.6f", location.latitude, location.longitude)
        
        if let accuracy = locationAccuracy {
            let accuracyText: String
            let accuracyColor: UIColor
            
            if accuracy < 5 {
                accuracyText = "🎯 GPS accuracy: Excellent (±\(String(format: "%.1f", accuracy))m)"
                accuracyColor = TreeShopTheme.successGreen
            } else if accuracy < 15 {
                accuracyText = "🎯 GPS accuracy: Good (±\(String(format: "%.1f", accuracy))m)"
                accuracyColor = TreeShopTheme.warningYellow
            } else {
                accuracyText = "🎯 GPS accuracy: Fair (±\(String(format: "%.1f", accuracy))m)"
                accuracyColor = TreeShopTheme.errorRed
            }
            
            accuracyLabel.text = accuracyText
            accuracyLabel.textColor = accuracyColor
        }
    }
    
    // MARK: - Public Methods
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
        updateLocationDisplay()
    }
    
    func setPrefilledServicePackage(_ package: ServicePackage) {
        prefilledServicePackage = package
        if let index = ServicePackage.allCases.firstIndex(of: package) {
            servicePackageSelector?.selectedSegmentIndex = index
        }
    }
}