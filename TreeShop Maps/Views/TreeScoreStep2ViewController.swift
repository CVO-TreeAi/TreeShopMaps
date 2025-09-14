import UIKit
import CoreLocation

protocol TreeScoreStep2Delegate: AnyObject {
    func didCompleteStep2(afissPercentage: Double, healthStatus: String, servicePackage: ServicePackage, notes: String?)
    func didGoBackToStep1()
}

/// Screen 2: AFISS Assessment & Additional Information
class TreeScoreStep2ViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TreeScoreStep2Delegate?
    var treeData: (height: Double, canopyRadius: Double, dbh: Double, species: String?)?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    var prefilledServicePackage: ServicePackage?
    
    // MARK: - UI Elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerView: UIView!
    private var titleLabel: UILabel!
    private var progressLabel: UILabel!
    
    // AFISS Assessment Card
    private var afissCard: UIView!
    private var afissSlider: UISlider!
    private var afissLabel: UILabel!
    
    // Additional Info Card
    private var infoCard: UIView!
    private var healthSegmentedControl: UISegmentedControl!
    private var servicePackageSelector: UISegmentedControl!
    private var notesTextField: UITextField!
    
    // Action buttons
    private var calculateButton: UIButton!
    private var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setDefaultValues()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        // Navigation
        title = "AFISS Assessment"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "← Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Scroll View
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        setupHeaderView()
        setupAFISSCard()
        setupAdditionalInfoCard()
        setupActionButtons()
    }
    
    private func setupHeaderView() {
        headerView = TreeShopTheme.cardView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Step 2: AFISS Assessment"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Assess factors impacting service complexity"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        progressLabel = UILabel()
        progressLabel.text = "Step 2 of 3"
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        progressLabel.textColor = TreeShopTheme.primaryGreen
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)
        
        // Show current tree data summary
        if let data = treeData {
            let summaryLabel = UILabel()
            let speciesText = data.species ?? "Unknown species"
            summaryLabel.text = String(format: "🌲 %@ • %.1f ft tall • %.1f ft canopy • %.1f in DBH", 
                                     speciesText, data.height, data.canopyRadius, data.dbh)
            summaryLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            summaryLabel.textColor = TreeShopTheme.tertiaryText
            summaryLabel.numberOfLines = 2
            summaryLabel.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(summaryLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                
                progressLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
                progressLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                
                summaryLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
                summaryLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                summaryLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                summaryLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
            ])
        } else {
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                
                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                
                progressLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
                progressLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                progressLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
            ])
        }
    }
    
    private func setupAFISSCard() {
        afissCard = TreeShopTheme.cardView()
        afissCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(afissCard)
        
        let cardTitle = UILabel()
        cardTitle.text = "⚡ AFISS Impact Assessment"
        cardTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        cardTitle.textColor = TreeShopTheme.primaryText
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        afissCard.addSubview(cardTitle)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Assess Factors Impacting Service Systems - considers location risks, access difficulty, overhead hazards, and environmental factors"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = TreeShopTheme.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        afissCard.addSubview(descriptionLabel)
        
        // AFISS Slider with enhanced UI
        let sliderContainer = UIView()
        sliderContainer.translatesAutoresizingMaskIntoConstraints = false
        afissCard.addSubview(sliderContainer)
        
        let sliderTitleStack = UIStackView()
        sliderTitleStack.axis = .horizontal
        sliderTitleStack.distribution = .fill
        sliderTitleStack.translatesAutoresizingMaskIntoConstraints = false
        
        let sliderTitle = UILabel()
        sliderTitle.text = "Impact Percentage"
        sliderTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        sliderTitle.textColor = TreeShopTheme.primaryText
        
        afissLabel = UILabel()
        afissLabel.text = "25%"
        afissLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        afissLabel.textColor = TreeShopTheme.primaryGreen
        afissLabel.textAlignment = .right
        afissLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        sliderTitleStack.addArrangedSubview(sliderTitle)
        sliderTitleStack.addArrangedSubview(afissLabel)
        sliderContainer.addSubview(sliderTitleStack)
        
        afissSlider = UISlider()
        afissSlider.minimumValue = 0
        afissSlider.maximumValue = 100
        afissSlider.value = 25
        afissSlider.tintColor = TreeShopTheme.primaryGreen
        afissSlider.addTarget(self, action: #selector(afissSliderChanged(_:)), for: .valueChanged)
        afissSlider.translatesAutoresizingMaskIntoConstraints = false
        sliderContainer.addSubview(afissSlider)
        
        // AFISS severity indicator
        let severityIndicator = createSeverityIndicator()
        sliderContainer.addSubview(severityIndicator)
        
        // Help button for AFISS info
        let helpButton = UIButton(type: .system)
        helpButton.setTitle("ℹ️ AFISS Help", for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        helpButton.addTarget(self, action: #selector(showAFISSHelp), for: .touchUpInside)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        afissCard.addSubview(helpButton)
        
        // Layout AFISS card
        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: afissCard.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: afissCard.leadingAnchor, constant: 16),
            
            descriptionLabel.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: afissCard.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: afissCard.trailingAnchor, constant: -16),
            
            sliderContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            sliderContainer.leadingAnchor.constraint(equalTo: afissCard.leadingAnchor, constant: 16),
            sliderContainer.trailingAnchor.constraint(equalTo: afissCard.trailingAnchor, constant: -16),
            
            sliderTitleStack.topAnchor.constraint(equalTo: sliderContainer.topAnchor),
            sliderTitleStack.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            sliderTitleStack.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            afissSlider.topAnchor.constraint(equalTo: sliderTitleStack.bottomAnchor, constant: 8),
            afissSlider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            afissSlider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            severityIndicator.topAnchor.constraint(equalTo: afissSlider.bottomAnchor, constant: 8),
            severityIndicator.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            severityIndicator.bottomAnchor.constraint(equalTo: sliderContainer.bottomAnchor),
            
            helpButton.topAnchor.constraint(equalTo: sliderContainer.bottomAnchor, constant: 12),
            helpButton.leadingAnchor.constraint(equalTo: afissCard.leadingAnchor, constant: 16),
            helpButton.bottomAnchor.constraint(equalTo: afissCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func createSeverityIndicator() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let severityLabel = UILabel()
        severityLabel.text = "Moderate Impact"
        severityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        severityLabel.textColor = TreeShopTheme.warningYellow
        severityLabel.textAlignment = .center
        severityLabel.tag = 100 // For easy access to update
        severityLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(severityLabel)
        
        NSLayoutConstraint.activate([
            severityLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            severityLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    private func setupAdditionalInfoCard() {
        infoCard = TreeShopTheme.cardView()
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCard)
        
        let cardTitle = UILabel()
        cardTitle.text = "📋 Additional Information"
        cardTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        cardTitle.textColor = TreeShopTheme.primaryText
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(cardTitle)
        
        // Health Status
        let healthLabel = UILabel()
        healthLabel.text = "Tree Health Status"
        healthLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        healthLabel.textColor = TreeShopTheme.primaryText
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(healthLabel)
        
        healthSegmentedControl = UISegmentedControl(items: ["🟢 Healthy", "🟡 Fair", "🔴 Poor"])
        healthSegmentedControl.selectedSegmentIndex = 0
        healthSegmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        healthSegmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        healthSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(healthSegmentedControl)
        
        // Service Package
        let packageLabel = UILabel()
        packageLabel.text = "Service Package"
        packageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        packageLabel.textColor = TreeShopTheme.primaryText
        packageLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(packageLabel)
        
        let packageItems = ServicePackage.allCases.map { $0.rawValue }
        servicePackageSelector = UISegmentedControl(items: packageItems)
        servicePackageSelector.selectedSegmentIndex = prefilledServicePackage?.hash ?? 1
        servicePackageSelector.backgroundColor = TreeShopTheme.buttonBackground
        servicePackageSelector.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        servicePackageSelector.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(servicePackageSelector)
        
        // Notes
        let notesLabel = UILabel()
        notesLabel.text = "Additional Notes"
        notesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        notesLabel.textColor = TreeShopTheme.primaryText
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(notesLabel)
        
        notesTextField = UITextField()
        notesTextField.placeholder = "Special conditions, access notes..."
        notesTextField.backgroundColor = TreeShopTheme.buttonBackground
        notesTextField.textColor = TreeShopTheme.primaryText
        notesTextField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        notesTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        notesTextField.leftViewMode = .always
        notesTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        notesTextField.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(notesTextField)
        
        // Layout additional info card
        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            
            healthLabel.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 16),
            healthLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            
            healthSegmentedControl.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 8),
            healthSegmentedControl.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            healthSegmentedControl.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            healthSegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            packageLabel.topAnchor.constraint(equalTo: healthSegmentedControl.bottomAnchor, constant: 16),
            packageLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            
            servicePackageSelector.topAnchor.constraint(equalTo: packageLabel.bottomAnchor, constant: 8),
            servicePackageSelector.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            servicePackageSelector.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            servicePackageSelector.heightAnchor.constraint(equalToConstant: 36),
            
            notesLabel.topAnchor.constraint(equalTo: servicePackageSelector.bottomAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            
            notesTextField.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextField.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            notesTextField.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            notesTextField.heightAnchor.constraint(equalToConstant: 50),
            notesTextField.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActionButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        backButton = TreeShopTheme.styledButton(title: "← Back")
        backButton.backgroundColor = TreeShopTheme.secondaryGray
        
        calculateButton = TreeShopTheme.styledButton(title: "Calculate TreeScore →")
        calculateButton.backgroundColor = TreeShopTheme.primaryGreen
        calculateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        buttonStack.addArrangedSubview(backButton)
        buttonStack.addArrangedSubview(calculateButton)
        
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
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
            
            // AFISS Card
            afissCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            afissCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            afissCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Info Card
            infoCard.topAnchor.constraint(equalTo: afissCard.bottomAnchor, constant: 16),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        calculateButton.addTarget(self, action: #selector(calculateButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func afissSliderChanged(_ slider: UISlider) {
        let value = Int(slider.value)
        afissLabel.text = "\(value)%"
        
        // Update severity indicator
        if let severityIndicator = afissCard.viewWithTag(100) as? UILabel {
            let (severity, color) = getAFISSSeverity(for: value)
            severityIndicator.text = severity
            severityIndicator.textColor = color
        }
    }
    
    @objc private func calculateButtonTapped() {
        let healthStatus = ["Healthy", "Fair", "Poor"][healthSegmentedControl.selectedSegmentIndex]
        let selectedPackage = ServicePackage.allCases[servicePackageSelector.selectedSegmentIndex]
        let notes = notesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : notesTextField.text
        
        delegate?.didCompleteStep2(
            afissPercentage: Double(afissSlider.value),
            healthStatus: healthStatus,
            servicePackage: selectedPackage,
            notes: notes
        )
    }
    
    @objc private func backButtonTapped() {
        delegate?.didGoBackToStep1()
    }
    
    @objc private func showAFISSHelp() {
        let alert = UIAlertController(
            title: "AFISS Assessment Guide",
            message: """
            AFISS (Assess Factors Impacting Service Systems) considers:
            
            • Power lines & overhead hazards
            • Property access & equipment clearance  
            • Terrain difficulty & slope
            • Proximity to structures
            • Environmental restrictions
            • Municipal regulations
            
            0-25%: Low impact, standard access
            26-50%: Moderate complexity
            51-75%: High difficulty conditions  
            76-100%: Extreme hazard/access challenges
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func setDefaultValues() {
        afissSlider.value = 25
        afissLabel.text = "25%"
        
        if let severityIndicator = afissCard.viewWithTag(100) as? UILabel {
            let (severity, color) = getAFISSSeverity(for: 25)
            severityIndicator.text = severity
            severityIndicator.textColor = color
        }
    }
    
    private func getAFISSSeverity(for percentage: Int) -> (String, UIColor) {
        switch percentage {
        case 0..<26:
            return ("Low Impact", TreeShopTheme.successGreen)
        case 26..<51:
            return ("Moderate Impact", TreeShopTheme.warningYellow)
        case 51..<76:
            return ("High Impact", UIColor.orange)
        default:
            return ("Extreme Impact", TreeShopTheme.errorRed)
        }
    }
    
    // MARK: - Public Methods
    func setTreeData(_ data: (height: Double, canopyRadius: Double, dbh: Double, species: String?)) {
        treeData = data
    }
    
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
    }
    
    func setPrefilledServicePackage(_ package: ServicePackage) {
        prefilledServicePackage = package
        if let index = ServicePackage.allCases.firstIndex(of: package) {
            servicePackageSelector?.selectedSegmentIndex = index
        }
    }
}