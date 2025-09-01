import MapKit

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
        
        if isPerimeterLabel {
            self.title = "Perimeter: \(measurementValue)"
        } else {
            self.title = measurementValue
        }
        
        super.init()
    }
}

class MeasurementLabelAnnotationView: MKAnnotationView {
    
    private let labelView = UIView()
    private let valueLabel = UILabel()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        canShowCallout = false
        isDraggable = false
        
        // Setup label background
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.backgroundColor = TreeShopTheme.cardBackground
        labelView.layer.cornerRadius = 8
        labelView.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        labelView.layer.borderWidth = 1
        
        // Add shadow for visibility
        labelView.layer.shadowColor = UIColor.black.cgColor
        labelView.layer.shadowOffset = CGSize(width: 0, height: 2)
        labelView.layer.shadowOpacity = 0.5
        labelView.layer.shadowRadius = 4
        
        addSubview(labelView)
        
        // Setup label text
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        valueLabel.textColor = TreeShopTheme.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        
        labelView.addSubview(valueLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: labelView.topAnchor, constant: 6),
            valueLabel.leadingAnchor.constraint(equalTo: labelView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: labelView.bottomAnchor, constant: -6)
        ])
        
        frame = CGRect(x: 0, y: 0, width: 100, height: 30)
    }
    
    func configure(with annotation: MeasurementLabelAnnotation) {
        valueLabel.text = annotation.measurementValue
        
        // Style differently for perimeter labels
        if annotation.isPerimeterLabel {
            valueLabel.textColor = TreeShopTheme.accentGreen
            labelView.layer.borderColor = TreeShopTheme.accentGreen.cgColor
            valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        } else {
            valueLabel.textColor = TreeShopTheme.primaryText
            labelView.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
            valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        }
        
        // Adjust size based on content
        let textSize = valueLabel.sizeThatFits(CGSize(width: 200, height: 50))
        frame.size = CGSize(width: max(60, textSize.width + 16), height: max(24, textSize.height + 12))
        
        // Center the annotation view on its coordinate
        centerOffset = CGPoint(x: 0, y: -frame.height / 2)
    }
}