import UIKit
import CoreLocation
import AVFoundation

/// Professional 7-Step Tree Assessment Workflow - Based on TreeAI SaaS System
class TreeAssessmentWorkflowViewController: UIViewController {
    
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
    
    // Assessment Data
    private var assessmentData = AssessmentData()
    
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
    
    // Step View Controllers
    private var stepViewControllers: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAssessmentWorkflow()
    }
    
    private func setupAssessmentWorkflow() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        setupScrollView()
        setupHeaderCard()
        setupMainCard()
        setupNavigationButtons()
        setupStepViewControllers()
        
        // Initialize with Step 1
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
        
        // Title Section
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(titleContainer)
        
        let iconLabel = UILabel()
        iconLabel.text = "🌲"
        iconLabel.font = UIFont.systemFont(ofSize: 32)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(iconLabel)
        
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleStack)
        
        let mainTitle = UILabel()
        mainTitle.text = "TreeShop Professional Assessment"
        mainTitle.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        mainTitle.textColor = TreeShopTheme.primaryText
        titleStack.addArrangedSubview(mainTitle)
        
        let subtitle = UILabel()
        subtitle.text = "Advanced field data collection & TreeScore calculation"
        subtitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitle.textColor = TreeShopTheme.secondaryText
        titleStack.addArrangedSubview(subtitle)
        
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
        titleContainer.addSubview(stepBadge)
        
        // Progress Section
        let progressContainer = UIView()
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(progressContainer)
        
        // Step Name and Progress
        let progressInfo = UIStackView()
        progressInfo.axis = .horizontal
        progressInfo.distribution = .equalSpacing
        progressInfo.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(progressInfo)
        
        stepLabel = UILabel()
        stepLabel.text = "Location"
        stepLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        stepLabel.textColor = TreeShopTheme.primaryText
        
        progressLabel = UILabel()
        progressLabel.text = "14%"
        progressLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        progressLabel.textColor = TreeShopTheme.primaryGreen
        
        progressInfo.addArrangedSubview(stepLabel)
        progressInfo.addArrangedSubview(progressLabel)
        
        // Progress Bar
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.progressTintColor = TreeShopTheme.primaryGreen
        progressBar.trackTintColor = TreeShopTheme.buttonBackground
        progressBar.layer.cornerRadius = 2
        progressBar.layer.masksToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(progressBar)
        
        // Breadcrumbs
        stepBreadcrumbs = UIStackView()
        stepBreadcrumbs.axis = .horizontal
        stepBreadcrumbs.distribution = .equalSpacing
        stepBreadcrumbs.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(stepBreadcrumbs)
        
        // Create breadcrumb labels
        for (_, title, _) in steps {
            let breadcrumb = UILabel()
            breadcrumb.text = title
            breadcrumb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            breadcrumb.textColor = TreeShopTheme.tertiaryText
            breadcrumb.textAlignment = .center
            stepBreadcrumbs.addArrangedSubview(breadcrumb)
        }
        
        // Layout Header Card
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleContainer.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            titleContainer.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            titleContainer.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            
            iconLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor),
            
            titleStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleStack.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleStack.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            
            stepBadge.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            stepBadge.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),
            stepBadge.widthAnchor.constraint(equalToConstant: 80),
            stepBadge.heightAnchor.constraint(equalToConstant: 28),
            
            progressContainer.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 20),
            progressContainer.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            progressContainer.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            progressContainer.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20),
            
            progressInfo.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            progressInfo.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressInfo.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            
            progressBar.topAnchor.constraint(equalTo: progressInfo.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            
            stepBreadcrumbs.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 12),
            stepBreadcrumbs.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            stepBreadcrumbs.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            stepBreadcrumbs.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor)
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
            stepContentView.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -32)
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
    
    private func setupStepViewControllers() {
        stepViewControllers = [
            LocationStepViewController(assessmentData: assessmentData, currentLocation: currentLocation),
            MeasurementsStepViewController(assessmentData: assessmentData),
            SpeciesStepViewController(assessmentData: assessmentData),
            HealthStepViewController(assessmentData: assessmentData),
            AFISSStepViewController(assessmentData: assessmentData),
            PhotosStepViewController(assessmentData: assessmentData),
            ResultsStepViewController(assessmentData: assessmentData, delegate: delegate)
        ]
    }
    
    // MARK: - Step Navigation
    private func showStep(_ stepIndex: Int) {
        guard stepIndex >= 0 && stepIndex < steps.count else { return }
        
        currentStepIndex = stepIndex
        let (_, stepName, progress) = steps[stepIndex]
        
        // Update header
        stepLabel.text = stepName
        progressLabel.text = "\(progress)%"
        progressBar.setProgress(Float(progress) / 100.0, animated: true)
        
        // Update breadcrumbs
        for (index, breadcrumb) in stepBreadcrumbs.arrangedSubviews.enumerated() {
            if let label = breadcrumb as? UILabel {
                label.textColor = index <= stepIndex ? TreeShopTheme.primaryGreen : TreeShopTheme.tertiaryText
                label.font = UIFont.systemFont(ofSize: 11, weight: index <= stepIndex ? .semibold : .medium)
            }
        }
        
        // Update step badge
        if let stepBadge = headerCard.subviews.first(where: { $0 is UILabel && ($0 as! UILabel).text?.contains("Step") == true }) as? UILabel {
            stepBadge.text = "Step \(stepIndex + 1) of \(steps.count)"
        }
        
        // Show step content
        showStepContent(stepIndex)
        
        // Update navigation buttons
        updateNavigationButtons()
        
        // Animate transition
        animateStepTransition()
    }
    
    private func showStepContent(_ stepIndex: Int) {
        // Remove current step view controller
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        // Add new step view controller
        let stepViewController = stepViewControllers[stepIndex]
        addChild(stepViewController)
        stepContentView.addSubview(stepViewController.view)
        stepViewController.view.frame = stepContentView.bounds
        stepViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stepViewController.didMove(toParent: self)
    }
    
    private func updateNavigationButtons() {
        // Previous button
        prevButton.isEnabled = currentStepIndex > 0
        prevButton.alpha = currentStepIndex > 0 ? 1.0 : 0.5
        
        // Next button
        let isLastStep = currentStepIndex == steps.count - 1
        nextButton.setTitle(isLastStep ? "Complete Assessment" : "Next →", for: .normal)
        nextButton.backgroundColor = isLastStep ? TreeShopTheme.successGreen : TreeShopTheme.primaryGreen
        
        // Hide navigation buttons on results step
        navigationButtons.isHidden = isLastStep
    }
    
    private func animateStepTransition() {
        UIView.animate(withDuration: 0.3, animations: {
            self.stepContentView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.stepContentView.alpha = 1.0
            }
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
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
            } else {
                // Complete assessment
                completeAssessment()
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        let stepVC = stepViewControllers[currentStepIndex]
        
        if let validatable = stepVC as? StepValidatable {
            return validatable.validateStep()
        }
        
        return true
    }
    
    private func completeAssessment() {
        // Create tree inventory item from assessment data
        let treeItem = assessmentData.createTreeInventoryItem(
            location: currentLocation ?? CLLocationCoordinate2D(),
            accuracy: locationAccuracy ?? 0
        )
        
        delegate?.didCreateTreeInventoryItem(treeItem)
    }
    
    // MARK: - Public Methods
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
        assessmentData.coordinate = coordinate
        assessmentData.accuracy = accuracy
    }
    
    func setPrefilledServicePackage(_ package: ServicePackage) {
        prefilledServicePackage = package
        assessmentData.prefilledPackage = package
    }
}

// MARK: - Assessment Data Model
class AssessmentData {
    // Location
    var locationText: String = ""
    var coordinate: CLLocationCoordinate2D?
    var accuracy: CLLocationAccuracy?
    
    // Measurements
    var height: Double?
    var crownRadius: Double?
    var dbh: Double?
    
    // Species
    var species: String = ""
    
    // Health
    var health: String = ""
    
    // AFISS
    var riskFactors: [String] = []
    
    // Photos
    var photos: [UIImage] = []
    
    // System
    var prefilledPackage: ServicePackage?
    
    func createTreeInventoryItem(location: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) -> TreeInventoryItem {
        return TreeInventoryItem(
            coordinate: location,
            gpsAccuracy: accuracy,
            height: height ?? 0,
            canopyRadius: crownRadius ?? 0,
            dbh: dbh ?? 0,
            afissPercentage: calculateAFISSPercentage(),
            species: species.isEmpty ? nil : species,
            healthStatus: health,
            notes: createNotesFromAssessment(),
            servicePackage: prefilledPackage ?? .medium,
            crewPpH: 150.0
        )
    }
    
    private func calculateAFISSPercentage() -> Double {
        // Calculate AFISS percentage based on selected risk factors
        return min(100.0, Double(riskFactors.count) * 8.0) // Each factor adds ~8%
    }
    
    private func createNotesFromAssessment() -> String? {
        var notes: [String] = []
        
        if !locationText.isEmpty {
            notes.append("Location: \(locationText)")
        }
        
        if !riskFactors.isEmpty {
            notes.append("AFISS Factors: \(riskFactors.joined(separator: ", "))")
        }
        
        if photos.count > 0 {
            notes.append("Photos: \(photos.count) attached")
        }
        
        return notes.isEmpty ? nil : notes.joined(separator: " | ")
    }
}

// MARK: - Step Validation Protocol
protocol StepValidatable {
    func validateStep() -> Bool
}