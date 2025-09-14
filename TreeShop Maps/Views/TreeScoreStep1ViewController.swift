import UIKit
import CoreLocation

protocol TreeScoreStep1Delegate: AnyObject {
    func didCompleteStep1(height: Double, canopyRadius: Double, dbh: Double, species: String?)
    func didCancelStep1()
}

/// Screen 1: Basic Tree Measurements & Species Entry
class TreeScoreStep1ViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: TreeScoreStep1Delegate?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    
    // MARK: - UI Elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerView: UIView!
    private var titleLabel: UILabel!
    private var locationLabel: UILabel!
    private var accuracyLabel: UILabel!
    
    // Measurement inputs
    private var measurementsCard: UIView!
    private var heightSlider: UISlider!
    private var heightLabel: UILabel!
    private var canopySlider: UISlider!
    private var canopyLabel: UILabel!
    private var dbhSlider: UISlider!
    private var dbhLabel: UILabel!
    
    // Species input
    private var speciesCard: UIView!
    private var speciesTextField: UITextField!
    
    // Action buttons
    private var nextButton: UIButton!
    private var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateLocationDisplay()
        setDefaultValues()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        
        // Navigation
        title = "Tree Measurements"
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
        setupMeasurementsCard()
        setupSpeciesCard()
        setupActionButtons()
    }
    
    private func setupHeaderView() {
        headerView = TreeShopTheme.cardView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Step 1: Basic Measurements"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Enter the tree's physical measurements"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        locationLabel = UILabel()
        locationLabel.text = "📍 Getting location..."
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        locationLabel.textColor = TreeShopTheme.secondaryText
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(locationLabel)
        
        accuracyLabel = UILabel()
        accuracyLabel.text = "🎯 GPS accuracy: Unknown"
        accuracyLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        accuracyLabel.textColor = TreeShopTheme.tertiaryText
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(accuracyLabel)
        
        // Layout header elements
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            locationLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            accuracyLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            accuracyLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            accuracyLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupMeasurementsCard() {
        measurementsCard = TreeShopTheme.cardView()
        measurementsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(measurementsCard)
        
        let cardTitle = UILabel()
        cardTitle.text = "🌲 Tree Dimensions"
        cardTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        cardTitle.textColor = TreeShopTheme.primaryText
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        measurementsCard.addSubview(cardTitle)
        
        // Height Slider
        let heightStack = createSliderStack(
            title: "Height (feet)",
            subtitle: "Tree height from ground to top",
            min: 1, max: 200, value: 40,
            slider: &heightSlider,
            label: &heightLabel
        )
        measurementsCard.addSubview(heightStack)
        
        // Canopy Radius Slider
        let canopyStack = createSliderStack(
            title: "Canopy Radius (feet)",
            subtitle: "From trunk to edge of canopy",
            min: 1, max: 150, value: 15,
            slider: &canopySlider,
            label: &canopyLabel
        )
        measurementsCard.addSubview(canopyStack)
        
        // DBH Slider
        let dbhStack = createSliderStack(
            title: "DBH (inches)",
            subtitle: "Diameter at breast height (4.5 ft)",
            min: 1, max: 120, value: 24,
            slider: &dbhSlider,
            label: &dbhLabel
        )
        measurementsCard.addSubview(dbhStack)
        
        // Layout card elements
        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: measurementsCard.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16),
            
            heightStack.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 20),
            heightStack.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16),
            heightStack.trailingAnchor.constraint(equalTo: measurementsCard.trailingAnchor, constant: -16),
            
            canopyStack.topAnchor.constraint(equalTo: heightStack.bottomAnchor, constant: 24),
            canopyStack.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16),
            canopyStack.trailingAnchor.constraint(equalTo: measurementsCard.trailingAnchor, constant: -16),
            
            dbhStack.topAnchor.constraint(equalTo: canopyStack.bottomAnchor, constant: 24),
            dbhStack.leadingAnchor.constraint(equalTo: measurementsCard.leadingAnchor, constant: 16),
            dbhStack.trailingAnchor.constraint(equalTo: measurementsCard.trailingAnchor, constant: -16),
            dbhStack.bottomAnchor.constraint(equalTo: measurementsCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupSpeciesCard() {
        speciesCard = TreeShopTheme.cardView()
        speciesCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(speciesCard)
        
        let cardTitle = UILabel()
        cardTitle.text = "🌿 Species Information"
        cardTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        cardTitle.textColor = TreeShopTheme.primaryText
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        speciesCard.addSubview(cardTitle)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Optional - helps with accuracy"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        speciesCard.addSubview(subtitleLabel)
        
        speciesTextField = UITextField()
        speciesTextField.placeholder = "e.g. Oak, Pine, Maple..."
        speciesTextField.backgroundColor = TreeShopTheme.buttonBackground
        speciesTextField.textColor = TreeShopTheme.primaryText
        speciesTextField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        speciesTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        speciesTextField.leftViewMode = .always
        speciesTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        speciesTextField.translatesAutoresizingMaskIntoConstraints = false
        speciesCard.addSubview(speciesTextField)
        
        // Layout species card
        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: speciesCard.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: speciesCard.leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: speciesCard.leadingAnchor, constant: 16),
            
            speciesTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            speciesTextField.leadingAnchor.constraint(equalTo: speciesCard.leadingAnchor, constant: 16),
            speciesTextField.trailingAnchor.constraint(equalTo: speciesCard.trailingAnchor, constant: -16),
            speciesTextField.heightAnchor.constraint(equalToConstant: 50),
            speciesTextField.bottomAnchor.constraint(equalTo: speciesCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActionButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        cancelButton = TreeShopTheme.styledButton(title: "Cancel")
        cancelButton.backgroundColor = TreeShopTheme.errorRed
        
        nextButton = TreeShopTheme.styledButton(title: "Next: AFISS Assessment →")
        nextButton.backgroundColor = TreeShopTheme.primaryGreen
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(nextButton)
        
        // Store reference for constraints
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createSliderStack(title: String, subtitle: String, min: Float, max: Float, value: Float, slider: inout UISlider!, label: inout UILabel!) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = TreeShopTheme.tertiaryText
        
        label = UILabel()
        label.text = String(format: "%.1f", value)
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
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
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, subtitleLabel, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        return mainStack
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
            
            // Measurements Card
            measurementsCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            measurementsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            measurementsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Species Card
            speciesCard.topAnchor.constraint(equalTo: measurementsCard.bottomAnchor, constant: 16),
            speciesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            speciesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
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
        default:
            break
        }
    }
    
    @objc private func nextButtonTapped() {
        delegate?.didCompleteStep1(
            height: Double(heightSlider.value),
            canopyRadius: Double(canopySlider.value),
            dbh: Double(dbhSlider.value),
            species: speciesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : speciesTextField.text
        )
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelStep1()
    }
    
    // MARK: - Helper Methods
    private func setDefaultValues() {
        heightSlider.value = 40
        canopySlider.value = 15  
        dbhSlider.value = 24
        
        heightLabel.text = "40.0"
        canopyLabel.text = "15.0"
        dbhLabel.text = "24.0"
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
}