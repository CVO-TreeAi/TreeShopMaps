import UIKit

class UnitsToggleControl: UIView {
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let distanceSegmentedControl = UISegmentedControl(items: ["Feet", "Meters", "Yards"])
    private let areaSegmentedControl = UISegmentedControl(items: ["Acres", "Sq Ft", "Hectares", "Sq M"])
    private let closeButton = UIButton(type: .system)
    
    var onUnitsChanged: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        setupCardView()
        setupTitleLabel()
        setupSegmentedControls()
        setupCloseButton()
        setupConstraints()
        loadCurrentSettings()
    }
    
    private func setupCardView() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = TreeShopTheme.cardBackground
        cardView.layer.cornerRadius = TreeShopTheme.cornerRadius
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowRadius = 8
        
        addSubview(cardView)
    }
    
    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Measurement Units"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        
        cardView.addSubview(titleLabel)
    }
    
    private func setupSegmentedControls() {
        // Distance control
        distanceSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        distanceSegmentedControl.addTarget(self, action: #selector(distanceUnitChanged), for: .valueChanged)
        
        if #available(iOS 13.0, *) {
            distanceSegmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
            distanceSegmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        }
        
        cardView.addSubview(distanceSegmentedControl)
        
        // Area control
        areaSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        areaSegmentedControl.addTarget(self, action: #selector(areaUnitChanged), for: .valueChanged)
        
        if #available(iOS 13.0, *) {
            areaSegmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
            areaSegmentedControl.backgroundColor = TreeShopTheme.buttonBackground
        }
        
        cardView.addSubview(areaSegmentedControl)
    }
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Done", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = TreeShopTheme.primaryGreen
        closeButton.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        cardView.addSubview(closeButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Card view
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 280),
            cardView.heightAnchor.constraint(equalToConstant: 200),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Distance control
            distanceSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            distanceSegmentedControl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            distanceSegmentedControl.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            distanceSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Area control
            areaSegmentedControl.topAnchor.constraint(equalTo: distanceSegmentedControl.bottomAnchor, constant: 16),
            areaSegmentedControl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            areaSegmentedControl.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            areaSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: areaSegmentedControl.bottomAnchor, constant: 20),
            closeButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func loadCurrentSettings() {
        let settings = MeasurementSettings.shared
        
        switch settings.distanceUnit {
        case .feet:
            distanceSegmentedControl.selectedSegmentIndex = 0
        case .meters:
            distanceSegmentedControl.selectedSegmentIndex = 1
        case .yards:
            distanceSegmentedControl.selectedSegmentIndex = 2
        }
        
        switch settings.areaUnit {
        case .acres:
            areaSegmentedControl.selectedSegmentIndex = 0
        case .squareFeet:
            areaSegmentedControl.selectedSegmentIndex = 1
        case .hectares:
            areaSegmentedControl.selectedSegmentIndex = 2
        case .squareMeters:
            areaSegmentedControl.selectedSegmentIndex = 3
        }
    }
    
    @objc private func distanceUnitChanged() {
        let settings = MeasurementSettings.shared
        
        switch distanceSegmentedControl.selectedSegmentIndex {
        case 0:
            settings.distanceUnit = .feet
        case 1:
            settings.distanceUnit = .meters
        case 2:
            settings.distanceUnit = .yards
        default:
            break
        }
        
        onUnitsChanged?()
    }
    
    @objc private func areaUnitChanged() {
        let settings = MeasurementSettings.shared
        
        switch areaSegmentedControl.selectedSegmentIndex {
        case 0:
            settings.areaUnit = .acres
        case 1:
            settings.areaUnit = .squareFeet
        case 2:
            settings.areaUnit = .hectares
        case 3:
            settings.areaUnit = .squareMeters
        default:
            break
        }
        
        onUnitsChanged?()
    }
    
    @objc private func closeButtonTapped() {
        removeFromSuperview()
    }
}