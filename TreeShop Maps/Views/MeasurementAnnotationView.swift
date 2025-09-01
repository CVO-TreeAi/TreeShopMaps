import UIKit
import MapKit

// MARK: - Measurement Label Annotation
class MeasurementLabelAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    let measurementValue: String
    let measurementType: MeasurementType
    let isPerimeterLabel: Bool
    
    init(coordinate: CLLocationCoordinate2D,
         measurementValue: String,
         measurementType: MeasurementType,
         isPerimeterLabel: Bool = false) {
        self.coordinate = coordinate
        self.measurementValue = measurementValue
        self.measurementType = measurementType
        self.isPerimeterLabel = isPerimeterLabel
        super.init()
        
        if isPerimeterLabel {
            self.title = "Perimeter"
            self.subtitle = measurementValue
        } else {
            self.title = measurementType == .distance ? "Distance" : "Area"
            self.subtitle = measurementValue
        }
    }
}

// MARK: - Custom Annotation View for Measurement Labels
class MeasurementLabelAnnotationView: MKAnnotationView {
    
    private let containerView = UIView()
    private let backgroundView = UIView()
    private let valueLabel = UILabel()
    private let iconImageView = UIImageView()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        // Configure main properties
        backgroundColor = UIColor.clear
        canShowCallout = false
        centerOffset = CGPoint(x: 0, y: 0)
        
        // Setup container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Setup background view
        backgroundView.backgroundColor = TreeShopTheme.cardBackground.withAlphaComponent(0.95)
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowOpacity = 0.3
        backgroundView.layer.shadowRadius = 4
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(backgroundView)
        
        // Setup icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = TreeShopTheme.primaryGreen
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Setup value label
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = TreeShopTheme.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(valueLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            valueLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        valueLabel.text = nil
        iconImageView.image = nil
    }
    
    func configure(with annotation: MeasurementLabelAnnotation) {
        valueLabel.text = annotation.measurementValue
        
        if annotation.isPerimeterLabel {
            iconImageView.image = UIImage(systemName: "ruler.fill")
            backgroundView.layer.borderColor = TreeShopTheme.accentGreen.cgColor
            iconImageView.tintColor = TreeShopTheme.accentGreen
        } else {
            iconImageView.image = UIImage(systemName: annotation.measurementType.systemImageName)
            backgroundView.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
            iconImageView.tintColor = TreeShopTheme.primaryGreen
        }
    }
}

// MARK: - GPS Accuracy Indicator View
class GPSAccuracyIndicatorView: UIView {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let accuracyLabel = UILabel()
    private let coordinateLabel = UILabel()
    
    private var accuracy: CLLocationAccuracy = 0
    private var coordinate: CLLocationCoordinate2D?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = TreeShopTheme.cardBackground.withAlphaComponent(0.95)
        layer.cornerRadius = TreeShopTheme.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, y: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Icon
        iconImageView.image = UIImage(systemName: "location.fill")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = TreeShopTheme.primaryGreen
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Accuracy label
        accuracyLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        accuracyLabel.textColor = TreeShopTheme.primaryText
        accuracyLabel.textAlignment = .left
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(accuracyLabel)
        
        // Coordinate label
        coordinateLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        coordinateLabel.textColor = TreeShopTheme.secondaryText
        coordinateLabel.textAlignment = .left
        coordinateLabel.numberOfLines = 2
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(coordinateLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            accuracyLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            accuracyLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            accuracyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            coordinateLabel.topAnchor.constraint(equalTo: accuracyLabel.bottomAnchor, constant: 4),
            coordinateLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            coordinateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            coordinateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func updateAccuracy(_ accuracy: CLLocationAccuracy, coordinate: CLLocationCoordinate2D? = nil) {
        self.accuracy = accuracy
        self.coordinate = coordinate
        
        let accuracyColor: UIColor
        let accuracyText: String
        
        if accuracy < 0 {
            accuracyText = "GPS: No Signal"
            accuracyColor = TreeShopTheme.errorRed
            iconImageView.tintColor = TreeShopTheme.errorRed
        } else if accuracy <= 5 {
            accuracyText = "GPS: Excellent (±\(Int(accuracy))m)"
            accuracyColor = TreeShopTheme.successGreen
            iconImageView.tintColor = TreeShopTheme.successGreen
        } else if accuracy <= 10 {
            accuracyText = "GPS: Good (±\(Int(accuracy))m)"
            accuracyColor = TreeShopTheme.primaryGreen
            iconImageView.tintColor = TreeShopTheme.primaryGreen
        } else if accuracy <= 20 {
            accuracyText = "GPS: Fair (±\(Int(accuracy))m)"
            accuracyColor = TreeShopTheme.warningYellow
            iconImageView.tintColor = TreeShopTheme.warningYellow
        } else {
            accuracyText = "GPS: Poor (±\(Int(accuracy))m)"
            accuracyColor = TreeShopTheme.errorRed
            iconImageView.tintColor = TreeShopTheme.errorRed
        }
        
        accuracyLabel.text = accuracyText
        accuracyLabel.textColor = accuracyColor
        
        // Update coordinate display if enabled and available
        if MeasurementSettings.shared.showCoordinates, let coord = coordinate {
            coordinateLabel.text = String(format: "%.6f°, %.6f°", coord.latitude, coord.longitude)
            coordinateLabel.isHidden = false
        } else {
            coordinateLabel.isHidden = true
        }
    }
}

// MARK: - Crosshair View for Precise Placement
class CrosshairView: UIView {
    
    private let horizontalLine = UIView()
    private let verticalLine = UIView()
    private let centerDot = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false
        
        // Horizontal line
        horizontalLine.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.8)
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalLine)
        
        // Vertical line
        verticalLine.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.8)
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalLine)
        
        // Center dot
        centerDot.backgroundColor = TreeShopTheme.primaryGreen
        centerDot.layer.cornerRadius = 4
        centerDot.layer.borderWidth = 2
        centerDot.layer.borderColor = UIColor.white.cgColor
        centerDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerDot)
        
        // Layout
        NSLayoutConstraint.activate([
            // Horizontal line
            horizontalLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            horizontalLine.widthAnchor.constraint(equalToConstant: 40),
            horizontalLine.heightAnchor.constraint(equalToConstant: 2),
            
            // Vertical line
            verticalLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            verticalLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalLine.widthAnchor.constraint(equalToConstant: 2),
            verticalLine.heightAnchor.constraint(equalToConstant: 40),
            
            // Center dot
            centerDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerDot.widthAnchor.constraint(equalToConstant: 8),
            centerDot.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        // Add pulsing animation
        addPulseAnimation()
    }
    
    private func addPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        centerDot.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    func show() {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
}

// MARK: - Units Toggle Control
class UnitsToggleControl: UIView {
    
    private let distanceSegmentedControl: UISegmentedControl
    private let areaSegmentedControl: UISegmentedControl
    private let titleLabel = UILabel()
    
    var onUnitsChanged: (() -> Void)?
    
    override init(frame: CGRect) {
        // Initialize segmented controls
        distanceSegmentedControl = UISegmentedControl(items: DistanceUnit.allCases.map { $0.abbreviation })
        areaSegmentedControl = UISegmentedControl(items: AreaUnit.allCases.map { $0.abbreviation })
        
        super.init(frame: frame)
        setupView()
        loadCurrentSettings()
    }
    
    required init?(coder: NSCoder) {
        distanceSegmentedControl = UISegmentedControl(items: DistanceUnit.allCases.map { $0.abbreviation })
        areaSegmentedControl = UISegmentedControl(items: AreaUnit.allCases.map { $0.abbreviation })
        
        super.init(coder: coder)
        setupView()
        loadCurrentSettings()
    }
    
    private func setupView() {
        backgroundColor = TreeShopTheme.cardBackground
        layer.cornerRadius = TreeShopTheme.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, y: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        
        // Title
        titleLabel.text = "Measurement Units"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Style segmented controls
        [distanceSegmentedControl, areaSegmentedControl].forEach { control in
            control.translatesAutoresizingMaskIntoConstraints = false
            addSubview(control)
            
            if #available(iOS 13.0, *) {
                control.selectedSegmentTintColor = TreeShopTheme.primaryGreen
                control.backgroundColor = TreeShopTheme.buttonBackground
                control.setTitleTextAttributes([.foregroundColor: TreeShopTheme.secondaryText], for: .normal)
                control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            }
            
            control.addTarget(self, action: #selector(unitsChanged), for: .valueChanged)
        }
        
        // Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            distanceSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            distanceSegmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            distanceSegmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            distanceSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            areaSegmentedControl.topAnchor.constraint(equalTo: distanceSegmentedControl.bottomAnchor, constant: 12),
            areaSegmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            areaSegmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            areaSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            areaSegmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func loadCurrentSettings() {
        let settings = MeasurementSettings.shared
        
        if let distanceIndex = DistanceUnit.allCases.firstIndex(of: settings.distanceUnit) {
            distanceSegmentedControl.selectedSegmentIndex = distanceIndex
        }
        
        if let areaIndex = AreaUnit.allCases.firstIndex(of: settings.areaUnit) {
            areaSegmentedControl.selectedSegmentIndex = areaIndex
        }
    }
    
    @objc private func unitsChanged() {
        let settings = MeasurementSettings.shared
        
        if distanceSegmentedControl.selectedSegmentIndex < DistanceUnit.allCases.count {
            settings.distanceUnit = DistanceUnit.allCases[distanceSegmentedControl.selectedSegmentIndex]
        }
        
        if areaSegmentedControl.selectedSegmentIndex < AreaUnit.allCases.count {
            settings.areaUnit = AreaUnit.allCases[areaSegmentedControl.selectedSegmentIndex]
        }
        
        onUnitsChanged?()
    }
}