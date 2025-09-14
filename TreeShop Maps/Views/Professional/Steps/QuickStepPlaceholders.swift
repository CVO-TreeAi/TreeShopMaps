import UIKit
import AVFoundation

// MARK: - Quick Placeholder Implementations for Testing

/// Step 3: Species Selection
class SpeciesStepViewController: UIViewController, StepValidatable {
    private let assessmentData: AssessmentData
    
    init(assessmentData: AssessmentData) {
        self.assessmentData = assessmentData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQuickSpeciesStep()
    }
    
    private func setupQuickSpeciesStep() {
        view.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "🌳 Species Selection\n\nQuick-select buttons and custom input\n(Professional grid layout being implemented)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = TreeShopTheme.primaryText
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let textField = UITextField()
        textField.placeholder = "Enter species (Oak, Pine, Maple...)"
        textField.textAlignment = .center
        textField.backgroundColor = TreeShopTheme.buttonBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.layer.cornerRadius = 8
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(speciesChanged), for: .editingChanged)
        view.addSubview(textField)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 280),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func speciesChanged(_ textField: UITextField) {
        assessmentData.species = textField.text ?? ""
    }
    
    func validateStep() -> Bool {
        return !assessmentData.species.isEmpty
    }
}

/// Step 4: Health Assessment
class HealthStepViewController: UIViewController, StepValidatable {
    private let assessmentData: AssessmentData
    
    init(assessmentData: AssessmentData) {
        self.assessmentData = assessmentData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQuickHealthStep()
    }
    
    private func setupQuickHealthStep() {
        view.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "💚 Health Assessment\n\nVisual health indicators with color coding\n(Professional health matrix being implemented)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = TreeShopTheme.primaryText
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let healthOptions = ["Excellent", "Good", "Fair", "Poor", "Critical"]
        let segmentedControl = UISegmentedControl(items: healthOptions)
        segmentedControl.selectedSegmentIndex = 1 // Default to Good
        segmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        segmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(healthChanged), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Set default
        assessmentData.health = "Good"
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 320),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func healthChanged(_ segmentedControl: UISegmentedControl) {
        let healthOptions = ["Excellent", "Good", "Fair", "Poor", "Critical"]
        assessmentData.health = healthOptions[segmentedControl.selectedSegmentIndex]
    }
    
    func validateStep() -> Bool {
        return !assessmentData.health.isEmpty
    }
}

/// Step 5: AFISS Risk Assessment
class AFISSStepViewController: UIViewController, StepValidatable {
    private let assessmentData: AssessmentData
    
    init(assessmentData: AssessmentData) {
        self.assessmentData = assessmentData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQuickAFISSStep()
    }
    
    private func setupQuickAFISSStep() {
        view.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "⚡ AFISS Risk Assessment\n\nCategorized risk factors with point values\n(Advanced categorized system being implemented)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = TreeShopTheme.primaryText
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Quick risk factor toggles
        let riskStack = UIStackView()
        riskStack.axis = .vertical
        riskStack.spacing = 12
        riskStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(riskStack)
        
        let quickRisks = ["Power lines nearby", "Near buildings", "Cracked trunk", "Dead branches", "Access issues"]
        
        for (index, risk) in quickRisks.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle("☐ \(risk)", for: .normal)
            button.setTitle("✓ \(risk)", for: .selected)
            button.setTitleColor(TreeShopTheme.primaryText, for: .normal)
            button.setTitleColor(TreeShopTheme.primaryGreen, for: .selected)
            button.backgroundColor = TreeShopTheme.buttonBackground
            button.layer.cornerRadius = 8
            button.tag = index
            button.addTarget(self, action: #selector(riskToggled), for: .touchUpInside)
            riskStack.addArrangedSubview(button)
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            riskStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            riskStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            riskStack.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    @objc private func riskToggled(_ button: UIButton) {
        button.isSelected.toggle()
        let quickRisks = ["power-lines", "buildings", "cracks", "dead-branches", "access"]
        let riskId = quickRisks[button.tag]
        
        if button.isSelected {
            if !assessmentData.riskFactors.contains(riskId) {
                assessmentData.riskFactors.append(riskId)
            }
        } else {
            assessmentData.riskFactors.removeAll { $0 == riskId }
        }
    }
    
    func validateStep() -> Bool {
        return true // AFISS is optional
    }
}

/// Step 6: Photo Documentation
class PhotosStepViewController: UIViewController, StepValidatable {
    private let assessmentData: AssessmentData
    
    init(assessmentData: AssessmentData) {
        self.assessmentData = assessmentData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQuickPhotosStep()
    }
    
    private func setupQuickPhotosStep() {
        view.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "📷 Photo Documentation\n\nNative camera integration (0-3 photos)\n(Professional photo system being implemented)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = TreeShopTheme.primaryText
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let photoButton = UIButton(type: .system)
        photoButton.setTitle("📷 Take Photos (Optional)", for: .normal)
        photoButton.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        photoButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        photoButton.layer.cornerRadius = 8
        photoButton.layer.borderWidth = 1
        photoButton.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(photoButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            photoButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            photoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 240),
            photoButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func validateStep() -> Bool {
        return true // Photos are optional
    }
}

/// Step 7: Results Display  
class ResultsStepViewController: UIViewController {
    private let assessmentData: AssessmentData
    private weak var delegate: TreeScoreInputDelegate?
    
    init(assessmentData: AssessmentData, delegate: TreeScoreInputDelegate?) {
        self.assessmentData = assessmentData
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupResultsStep()
    }
    
    private func setupResultsStep() {
        view.backgroundColor = .clear
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "🎯 Assessment Complete!"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        mainStack.addArrangedSubview(titleLabel)
        
        // TreeScore Display
        let scoreCard = TreeShopTheme.cardView()
        scoreCard.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        scoreCard.layer.borderWidth = 2
        scoreCard.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        scoreCard.translatesAutoresizingMaskIntoConstraints = false
        
        let scoreStack = UIStackView()
        scoreStack.axis = .vertical
        scoreStack.spacing = 8
        scoreStack.alignment = .center
        scoreStack.translatesAutoresizingMaskIntoConstraints = false
        scoreCard.addSubview(scoreStack)
        
        // Calculate TreeScore
        let baseScore = calculateTreeScore()
        
        let scoreLabel = UILabel()
        scoreLabel.text = String(format: "%.0f", baseScore)
        scoreLabel.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        scoreLabel.textColor = TreeShopTheme.primaryGreen
        scoreStack.addArrangedSubview(scoreLabel)
        
        let scoreTitleLabel = UILabel()
        scoreTitleLabel.text = "TreeScore"
        scoreTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        scoreTitleLabel.textColor = TreeShopTheme.primaryText
        scoreStack.addArrangedSubview(scoreTitleLabel)
        
        let complexityLabel = UILabel()
        let complexity = baseScore < 500 ? "Low Complexity" : baseScore < 1500 ? "Medium Complexity" : "High Complexity"
        complexityLabel.text = complexity
        complexityLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        complexityLabel.textColor = TreeShopTheme.secondaryText
        scoreStack.addArrangedSubview(complexityLabel)
        
        mainStack.addArrangedSubview(scoreCard)
        
        // Add to Inventory Button
        let addButton = TreeShopTheme.styledButton(title: "🌲 Add Tree to Inventory")
        addButton.backgroundColor = TreeShopTheme.primaryGreen
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        addButton.addTarget(self, action: #selector(addToInventory), for: .touchUpInside)
        mainStack.addArrangedSubview(addButton)
        
        // Summary
        let summaryLabel = UILabel()
        summaryLabel.text = createSummaryText()
        summaryLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        summaryLabel.textColor = TreeShopTheme.tertiaryText
        summaryLabel.numberOfLines = 0
        summaryLabel.textAlignment = .center
        mainStack.addArrangedSubview(summaryLabel)
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            scoreCard.widthAnchor.constraint(equalToConstant: 280),
            
            scoreStack.topAnchor.constraint(equalTo: scoreCard.topAnchor, constant: 32),
            scoreStack.leadingAnchor.constraint(equalTo: scoreCard.leadingAnchor, constant: 32),
            scoreStack.trailingAnchor.constraint(equalTo: scoreCard.trailingAnchor, constant: -32),
            scoreStack.bottomAnchor.constraint(equalTo: scoreCard.bottomAnchor, constant: -32),
            
            addButton.widthAnchor.constraint(equalToConstant: 280),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func calculateTreeScore() -> Double {
        guard let height = assessmentData.height,
              let crownRadius = assessmentData.crownRadius,
              let dbh = assessmentData.dbh else { return 0 }
        
        let baseScore = (height * crownRadius * 2 * dbh) / 12
        let afissMultiplier = 1 + (Double(assessmentData.riskFactors.count) * 0.08) // 8% per risk factor
        return baseScore * afissMultiplier
    }
    
    private func createSummaryText() -> String {
        var parts: [String] = []
        if let height = assessmentData.height { parts.append("Height: \(String(format: "%.1f", height))ft") }
        if let crown = assessmentData.crownRadius { parts.append("Crown: \(String(format: "%.1f", crown))ft") }
        if let dbh = assessmentData.dbh { parts.append("DBH: \(String(format: "%.1f", dbh))in") }
        if !assessmentData.species.isEmpty { parts.append("Species: \(assessmentData.species)") }
        if !assessmentData.health.isEmpty { parts.append("Health: \(assessmentData.health)") }
        if !assessmentData.riskFactors.isEmpty { parts.append("AFISS: \(assessmentData.riskFactors.count) factors") }
        
        return parts.joined(separator: " • ")
    }
    
    @objc private func addToInventory() {
        let treeItem = assessmentData.createTreeInventoryItem(
            location: assessmentData.coordinate ?? CLLocationCoordinate2D(),
            accuracy: assessmentData.accuracy ?? 0
        )
        
        delegate?.didCreateTreeInventoryItem(treeItem)
    }
}