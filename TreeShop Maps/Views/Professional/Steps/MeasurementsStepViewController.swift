import UIKit

/// Step 2: Large Professional Measurement Inputs with Live Preview
class MeasurementsStepViewController: UIViewController, StepValidatable {
    
    private let assessmentData: AssessmentData
    
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var measurementGrid: UIStackView!
    
    private var heightTextField: UITextField!
    private var crownTextField: UITextField!
    private var dbhTextField: UITextField!
    
    private var previewCard: UIView!
    private var previewScoreLabel: UILabel!
    private var validationBadge: UIView!
    
    init(assessmentData: AssessmentData) {
        self.assessmentData = assessmentData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMeasurementsStep()
        updatePreviewAndValidation()
    }
    
    private func setupMeasurementsStep() {
        view.backgroundColor = .clear
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 32
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Title Section
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 8
        titleStack.alignment = .center
        
        titleLabel = UILabel()
        titleLabel.text = "Tree Measurements"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        
        subtitleLabel = UILabel()
        subtitleLabel.text = "Precise measurements for TreeScore calculation"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.textAlignment = .center
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        mainStack.addArrangedSubview(titleStack)
        
        // Measurement Grid
        measurementGrid = createMeasurementGrid()
        mainStack.addArrangedSubview(measurementGrid)
        
        // Preview Card
        previewCard = createPreviewCard()
        previewCard.isHidden = true
        mainStack.addArrangedSubview(previewCard)
        
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
            
            measurementGrid.widthAnchor.constraint(lessThanOrEqualToConstant: 600)
        ])
    }
    
    private func createMeasurementGrid() -> UIStackView {
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 20
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        
        // For larger screens, use horizontal layout
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        if isIpad {
            let horizontalStack = UIStackView()
            horizontalStack.axis = .horizontal
            horizontalStack.distribution = .fillEqually
            horizontalStack.spacing = 20
            
            horizontalStack.addArrangedSubview(createMeasurementInput(
                title: "Height (feet)",
                subtitle: "Ground to top of tree",
                placeholder: "40",
                textField: &heightTextField
            ))
            
            horizontalStack.addArrangedSubview(createMeasurementInput(
                title: "Crown Radius (feet)", 
                subtitle: "Center to edge of canopy",
                placeholder: "12",
                textField: &crownTextField
            ))
            
            horizontalStack.addArrangedSubview(createMeasurementInput(
                title: "DBH (inches)",
                subtitle: "Diameter at 4.5ft height",
                placeholder: "18",
                textField: &dbhTextField
            ))
            
            gridStack.addArrangedSubview(horizontalStack)
        } else {
            // iPhone: Vertical layout
            gridStack.addArrangedSubview(createMeasurementInput(
                title: "Height (feet)",
                subtitle: "Ground to top of tree",
                placeholder: "40",
                textField: &heightTextField
            ))
            
            gridStack.addArrangedSubview(createMeasurementInput(
                title: "Crown Radius (feet)",
                subtitle: "Center to edge of canopy", 
                placeholder: "12",
                textField: &crownTextField
            ))
            
            gridStack.addArrangedSubview(createMeasurementInput(
                title: "DBH (inches)",
                subtitle: "Diameter at 4.5ft height",
                placeholder: "18",
                textField: &dbhTextField
            ))
        }
        
        return gridStack
    }
    
    private func createMeasurementInput(title: String, subtitle: String, placeholder: String, textField: inout UITextField!) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)
        
        // Large Text Field
        textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.backgroundColor = TreeShopTheme.buttonBackground
        textField.textColor = TreeShopTheme.primaryText
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        
        // Add input accessory for done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        textField.addTarget(self, action: #selector(measurementChanged(_:)), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(textField)
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = TreeShopTheme.tertiaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        stack.addArrangedSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            textField.heightAnchor.constraint(equalToConstant: 72),
            textField.widthAnchor.constraint(equalToConstant: 140)
        ])
        
        return container
    }
    
    private func createPreviewCard() -> UIView {
        let card = TreeShopTheme.cardView()
        card.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.05)
        card.layer.borderWidth = 1
        card.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.2).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let iconLabel = UILabel()
        iconLabel.text = "📊"
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        stack.addArrangedSubview(iconLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = "Preview TreeScore"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        stack.addArrangedSubview(titleLabel)
        
        previewScoreLabel = UILabel()
        previewScoreLabel.text = "0"
        previewScoreLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        previewScoreLabel.textColor = TreeShopTheme.primaryGreen
        stack.addArrangedSubview(previewScoreLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Base calculation (before AFISS)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = TreeShopTheme.tertiaryText
        stack.addArrangedSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            
            card.widthAnchor.constraint(equalToConstant: 220)
        ])
        
        return card
    }
    
    private func createValidationBadge() -> UIView {
        let container = UIView()
        container.backgroundColor = TreeShopTheme.successGreen.withAlphaComponent(0.1)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = TreeShopTheme.successGreen.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let iconLabel = UILabel()
        iconLabel.text = "✓"
        iconLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        iconLabel.textColor = TreeShopTheme.successGreen
        stack.addArrangedSubview(iconLabel)
        
        let textLabel = UILabel()
        textLabel.text = "All measurements recorded"
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        textLabel.textColor = TreeShopTheme.successGreen
        stack.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    @objc private func measurementChanged(_ textField: UITextField) {
        // Update assessment data
        if textField == heightTextField {
            assessmentData.height = Double(textField.text ?? "")
        } else if textField == crownTextField {
            assessmentData.crownRadius = Double(textField.text ?? "")
        } else if textField == dbhTextField {
            assessmentData.dbh = Double(textField.text ?? "")
        }
        
        // Visual feedback on text field
        if let text = textField.text, !text.isEmpty, Double(text) != nil {
            UIView.animate(withDuration: 0.2) {
                textField.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
                textField.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.05)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                textField.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
                textField.backgroundColor = TreeShopTheme.buttonBackground
            }
        }
        
        updatePreviewAndValidation()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updatePreviewAndValidation() {
        let isValid = validateStep()
        
        // Update preview score
        if let height = assessmentData.height,
           let crownRadius = assessmentData.crownRadius,
           let dbh = assessmentData.dbh {
            let baseScore = (height * crownRadius * 2 * dbh) / 12
            previewScoreLabel.text = String(format: "%.0f", baseScore)
            
            // Show preview card with animation
            if previewCard.isHidden {
                previewCard.isHidden = false
                previewCard.alpha = 0
                previewCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: [], animations: {
                    self.previewCard.alpha = 1
                    self.previewCard.transform = .identity
                })
            }
        } else {
            // Hide preview card
            if !previewCard.isHidden {
                UIView.animate(withDuration: 0.3) {
                    self.previewCard.alpha = 0
                } completion: { _ in
                    self.previewCard.isHidden = true
                }
            }
        }
        
        // Update validation badge
        UIView.animate(withDuration: 0.3) {
            self.validationBadge.isHidden = !isValid
            self.validationBadge.alpha = isValid ? 1.0 : 0.0
        }
        
        // Haptic feedback when complete
        if isValid && validationBadge.isHidden {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    // MARK: - StepValidatable
    func validateStep() -> Bool {
        return assessmentData.height != nil && 
               assessmentData.crownRadius != nil && 
               assessmentData.dbh != nil &&
               assessmentData.height! > 0 &&
               assessmentData.crownRadius! > 0 &&
               assessmentData.dbh! > 0
    }
}