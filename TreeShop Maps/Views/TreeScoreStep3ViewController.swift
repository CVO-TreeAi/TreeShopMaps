import UIKit
import CoreLocation

protocol TreeScoreStep3Delegate: AnyObject {
    func didAddTreeToInventory(_ item: TreeInventoryItem)
    func didGoBackToStep2()
    func didCancelTreeInput()
}

/// Screen 3: TreeScore Results & Add Tree to Inventory
class TreeScoreStep3ViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TreeScoreStep3Delegate?
    
    // Tree data from previous steps
    var treeData: (height: Double, canopyRadius: Double, dbh: Double, species: String?)?
    var assessmentData: (afissPercentage: Double, healthStatus: String, servicePackage: ServicePackage, notes: String?)?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    
    // Calculated TreeScore
    private var currentTreeScore: TreeScoreResult?
    
    // MARK: - UI Elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerView: UIView!
    private var titleLabel: UILabel!
    
    // TreeScore Results Display
    private var resultsCard: UIView!
    private var treeScoreLabel: UILabel!
    private var complexityIndicator: UIView!
    private var formulaLabel: UILabel!
    private var estimatedTimeLabel: UILabel!
    private var estimatedCostLabel: UILabel!
    
    // Summary Card
    private var summaryCard: UIView!
    
    // Action buttons
    private var addToInventoryButton: UIButton!
    private var recalculateButton: UIButton!
    private var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calculateTreeScore()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        // Navigation
        title = "TreeScore Results"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "← Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
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
        setupResultsCard()
        setupSummaryCard()
        setupActionButtons()
    }
    
    private func setupHeaderView() {
        headerView = TreeShopTheme.cardView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Step 3: TreeScore Calculated"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Review results and add to inventory"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        let progressLabel = UILabel()
        progressLabel.text = "Step 3 of 3 ✅"
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        progressLabel.textColor = TreeShopTheme.primaryGreen
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)
        
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
    
    private func setupResultsCard() {
        resultsCard = TreeShopTheme.cardView()
        resultsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resultsCard)
        
        // Main TreeScore Display
        let scoreContainer = UIView()
        scoreContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(scoreContainer)
        
        let scoreTitle = UILabel()
        scoreTitle.text = "🌲 TreeScore"
        scoreTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scoreTitle.textColor = TreeShopTheme.primaryText
        scoreTitle.textAlignment = .center
        scoreTitle.translatesAutoresizingMaskIntoConstraints = false
        scoreContainer.addSubview(scoreTitle)
        
        treeScoreLabel = UILabel()
        treeScoreLabel.text = "0 pts"
        treeScoreLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        treeScoreLabel.textColor = TreeShopTheme.primaryGreen
        treeScoreLabel.textAlignment = .center
        treeScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreContainer.addSubview(treeScoreLabel)
        
        // Complexity Indicator
        complexityIndicator = UIView()
        complexityIndicator.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        complexityIndicator.translatesAutoresizingMaskIntoConstraints = false
        scoreContainer.addSubview(complexityIndicator)
        
        let complexityLabel = UILabel()
        complexityLabel.text = "Complexity"
        complexityLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        complexityLabel.textColor = TreeShopTheme.primaryText
        complexityLabel.textAlignment = .center
        complexityLabel.tag = 200 // For easy updates
        complexityLabel.translatesAutoresizingMaskIntoConstraints = false
        complexityIndicator.addSubview(complexityLabel)
        
        // Formula Display
        formulaLabel = UILabel()
        formulaLabel.text = "Formula calculation..."
        formulaLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        formulaLabel.textColor = TreeShopTheme.tertiaryText
        formulaLabel.numberOfLines = 3
        formulaLabel.textAlignment = .center
        formulaLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(formulaLabel)
        
        // Estimates Container
        let estimatesContainer = UIView()
        estimatesContainer.backgroundColor = TreeShopTheme.buttonBackground
        estimatesContainer.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        estimatesContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.addSubview(estimatesContainer)
        
        let estimatesTitle = UILabel()
        estimatesTitle.text = "📊 Project Estimates"
        estimatesTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        estimatesTitle.textColor = TreeShopTheme.primaryText
        estimatesTitle.translatesAutoresizingMaskIntoConstraints = false
        estimatesContainer.addSubview(estimatesTitle)
        
        estimatedTimeLabel = UILabel()
        estimatedTimeLabel.text = "⏱ Time: Calculating..."
        estimatedTimeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        estimatedTimeLabel.textColor = TreeShopTheme.secondaryText
        estimatedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        estimatesContainer.addSubview(estimatedTimeLabel)
        
        estimatedCostLabel = UILabel()
        estimatedCostLabel.text = "💰 Cost: Calculating..."
        estimatedCostLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        estimatedCostLabel.textColor = TreeShopTheme.primaryGreen
        estimatedCostLabel.translatesAutoresizingMaskIntoConstraints = false
        estimatesContainer.addSubview(estimatedCostLabel)
        
        // Layout Results Card
        NSLayoutConstraint.activate([
            scoreContainer.topAnchor.constraint(equalTo: resultsCard.topAnchor, constant: 20),
            scoreContainer.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16),
            scoreContainer.trailingAnchor.constraint(equalTo: resultsCard.trailingAnchor, constant: -16),
            
            scoreTitle.topAnchor.constraint(equalTo: scoreContainer.topAnchor),
            scoreTitle.centerXAnchor.constraint(equalTo: scoreContainer.centerXAnchor),
            
            treeScoreLabel.topAnchor.constraint(equalTo: scoreTitle.bottomAnchor, constant: 8),
            treeScoreLabel.centerXAnchor.constraint(equalTo: scoreContainer.centerXAnchor),
            
            complexityIndicator.topAnchor.constraint(equalTo: treeScoreLabel.bottomAnchor, constant: 12),
            complexityIndicator.centerXAnchor.constraint(equalTo: scoreContainer.centerXAnchor),
            complexityIndicator.widthAnchor.constraint(equalToConstant: 120),
            complexityIndicator.heightAnchor.constraint(equalToConstant: 32),
            complexityIndicator.bottomAnchor.constraint(equalTo: scoreContainer.bottomAnchor),
            
            complexityLabel.centerXAnchor.constraint(equalTo: complexityIndicator.centerXAnchor),
            complexityLabel.centerYAnchor.constraint(equalTo: complexityIndicator.centerYAnchor),
            
            formulaLabel.topAnchor.constraint(equalTo: scoreContainer.bottomAnchor, constant: 16),
            formulaLabel.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16),
            formulaLabel.trailingAnchor.constraint(equalTo: resultsCard.trailingAnchor, constant: -16),
            
            estimatesContainer.topAnchor.constraint(equalTo: formulaLabel.bottomAnchor, constant: 16),
            estimatesContainer.leadingAnchor.constraint(equalTo: resultsCard.leadingAnchor, constant: 16),
            estimatesContainer.trailingAnchor.constraint(equalTo: resultsCard.trailingAnchor, constant: -16),
            estimatesContainer.bottomAnchor.constraint(equalTo: resultsCard.bottomAnchor, constant: -16),
            
            estimatesTitle.topAnchor.constraint(equalTo: estimatesContainer.topAnchor, constant: 12),
            estimatesTitle.leadingAnchor.constraint(equalTo: estimatesContainer.leadingAnchor, constant: 12),
            
            estimatedTimeLabel.topAnchor.constraint(equalTo: estimatesTitle.bottomAnchor, constant: 8),
            estimatedTimeLabel.leadingAnchor.constraint(equalTo: estimatesContainer.leadingAnchor, constant: 12),
            
            estimatedCostLabel.topAnchor.constraint(equalTo: estimatedTimeLabel.bottomAnchor, constant: 4),
            estimatedCostLabel.leadingAnchor.constraint(equalTo: estimatesContainer.leadingAnchor, constant: 12),
            estimatedCostLabel.bottomAnchor.constraint(equalTo: estimatesContainer.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupSummaryCard() {
        summaryCard = TreeShopTheme.cardView()
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(summaryCard)
        
        let summaryTitle = UILabel()
        summaryTitle.text = "📋 Tree Summary"
        summaryTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        summaryTitle.textColor = TreeShopTheme.primaryText
        summaryTitle.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(summaryTitle)
        
        // Create summary content
        let summaryStack = createSummaryStack()
        summaryCard.addSubview(summaryStack)
        
        // Location info
        let locationLabel = UILabel()
        if let location = currentLocation {
            locationLabel.text = String(format: "📍 %.6f, %.6f", location.latitude, location.longitude)
        } else {
            locationLabel.text = "📍 Location not available"
        }
        locationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        locationLabel.textColor = TreeShopTheme.tertiaryText
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            summaryTitle.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 16),
            summaryTitle.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            
            summaryStack.topAnchor.constraint(equalTo: summaryTitle.bottomAnchor, constant: 12),
            summaryStack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryStack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            
            locationLabel.topAnchor.constraint(equalTo: summaryStack.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            locationLabel.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func createSummaryStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add summary items
        if let treeData = treeData {
            if let species = treeData.species {
                stack.addArrangedSubview(createSummaryItem(label: "Species:", value: species))
            }
            stack.addArrangedSubview(createSummaryItem(label: "Height:", value: "\(String(format: "%.1f", treeData.height)) ft"))
            stack.addArrangedSubview(createSummaryItem(label: "Canopy Radius:", value: "\(String(format: "%.1f", treeData.canopyRadius)) ft"))
            stack.addArrangedSubview(createSummaryItem(label: "DBH:", value: "\(String(format: "%.1f", treeData.dbh)) in"))
        }
        
        if let assessmentData = assessmentData {
            stack.addArrangedSubview(createSummaryItem(label: "AFISS Impact:", value: "\(String(format: "%.0f", assessmentData.afissPercentage))%"))
            stack.addArrangedSubview(createSummaryItem(label: "Health:", value: assessmentData.healthStatus))
            stack.addArrangedSubview(createSummaryItem(label: "Service Package:", value: assessmentData.servicePackage.rawValue))
            if let notes = assessmentData.notes {
                stack.addArrangedSubview(createSummaryItem(label: "Notes:", value: notes))
            }
        }
        
        return stack
    }
    
    private func createSummaryItem(label: String, value: String) -> UIView {
        let container = UIView()
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = TreeShopTheme.secondaryText
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        valueView.textColor = TreeShopTheme.primaryText
        valueView.numberOfLines = 0
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelView)
        container.addSubview(valueView)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 100),
            
            valueView.topAnchor.constraint(equalTo: container.topAnchor),
            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            valueView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func setupActionButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        // Primary action button
        addToInventoryButton = TreeShopTheme.styledButton(title: "🌲 Add Tree to Inventory")
        addToInventoryButton.backgroundColor = TreeShopTheme.primaryGreen
        addToInventoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        // Secondary actions
        let secondaryStack = UIStackView()
        secondaryStack.axis = .horizontal
        secondaryStack.distribution = .fillEqually
        secondaryStack.spacing = 12
        
        recalculateButton = TreeShopTheme.styledButton(title: "🔄 Recalculate")
        recalculateButton.backgroundColor = TreeShopTheme.secondaryGray
        
        cancelButton = TreeShopTheme.styledButton(title: "Cancel")
        cancelButton.backgroundColor = TreeShopTheme.errorRed
        
        secondaryStack.addArrangedSubview(recalculateButton)
        secondaryStack.addArrangedSubview(cancelButton)
        
        buttonStack.addArrangedSubview(addToInventoryButton)
        buttonStack.addArrangedSubview(secondaryStack)
        
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            addToInventoryButton.heightAnchor.constraint(equalToConstant: 56),
            secondaryStack.heightAnchor.constraint(equalToConstant: 48)
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
            
            // Results Card
            resultsCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            resultsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resultsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Summary Card
            summaryCard.topAnchor.constraint(equalTo: resultsCard.bottomAnchor, constant: 16),
            summaryCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            summaryCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        addToInventoryButton.addTarget(self, action: #selector(addToInventoryButtonTapped), for: .touchUpInside)
        recalculateButton.addTarget(self, action: #selector(recalculateButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func addToInventoryButtonTapped() {
        guard let location = currentLocation,
              let accuracy = locationAccuracy,
              let treeScore = currentTreeScore,
              let treeData = treeData,
              let assessmentData = assessmentData else { return }
        
        let treeItem = TreeInventoryItem(
            coordinate: location,
            gpsAccuracy: accuracy,
            height: treeData.height,
            canopyRadius: treeData.canopyRadius,
            dbh: treeData.dbh,
            afissPercentage: assessmentData.afissPercentage,
            species: treeData.species,
            healthStatus: assessmentData.healthStatus,
            notes: assessmentData.notes,
            servicePackage: assessmentData.servicePackage,
            crewPpH: 150.0
        )
        
        delegate?.didAddTreeToInventory(treeItem)
    }
    
    @objc private func recalculateButtonTapped() {
        calculateTreeScore()
        updateResultsDisplay()
    }
    
    @objc private func backButtonTapped() {
        delegate?.didGoBackToStep2()
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelTreeInput()
    }
    
    // MARK: - TreeScore Calculation
    private func calculateTreeScore() {
        guard let treeData = treeData,
              let assessmentData = assessmentData else { return }
        
        currentTreeScore = TreeScoreCalculator.calculateTreeScore(
            height: treeData.height,
            canopyRadius: treeData.canopyRadius,
            dbh: treeData.dbh,
            afissPercentage: assessmentData.afissPercentage,
            gpsAccuracy: locationAccuracy
        )
        
        updateResultsDisplay()
    }
    
    private func updateResultsDisplay() {
        guard let treeScore = currentTreeScore,
              let assessmentData = assessmentData else { return }
        
        // Update TreeScore display
        treeScoreLabel.text = String(format: "%.0f pts", treeScore.finalTreeScore)
        formulaLabel.text = treeScore.formula
        
        // Update complexity indicator
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
        if let complexityLabel = complexityIndicator.viewWithTag(200) as? UILabel {
            complexityLabel.text = complexity.rawValue
            // Adjust text color for readability
            complexityLabel.textColor = complexity == .low ? TreeShopTheme.primaryText : UIColor.white
        }
        
        // Calculate and display estimates
        let estimatedHours = TreeScoreCalculator.convertTreeScoreToTime(treeScore: treeScore.finalTreeScore, crewPpH: 150.0)
        let estimatedCost = TreeScoreCalculator.calculateEstimatedBilling(
            treeScore: treeScore.finalTreeScore,
            servicePackage: assessmentData.servicePackage,
            crewPpH: 150.0
        )
        
        estimatedTimeLabel.text = String(format: "⏱ Time: %.1f hours", estimatedHours)
        estimatedCostLabel.text = String(format: "💰 Cost: $%.0f", estimatedCost)
        
        view.layoutIfNeeded()
    }
    
    // MARK: - Public Methods
    func setTreeData(_ data: (height: Double, canopyRadius: Double, dbh: Double, species: String?)) {
        treeData = data
    }
    
    func setAssessmentData(_ data: (afissPercentage: Double, healthStatus: String, servicePackage: ServicePackage, notes: String?)) {
        assessmentData = data
    }
    
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
    }
}