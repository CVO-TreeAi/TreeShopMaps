import UIKit
import CoreLocation

class GPSAccuracyIndicatorView: UIView {
    
    private let stackView = UIStackView()
    private let accuracyLabel = UILabel()
    private let statusLabel = UILabel()
    private let coordinateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = TreeShopTheme.cardBackground
        layer.cornerRadius = TreeShopTheme.smallCornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
        
        setupStackView()
        setupLabels()
        setupConstraints()
    }
    
    private func setupStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        
        addSubview(stackView)
    }
    
    private func setupLabels() {
        // Accuracy Label
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        accuracyLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        accuracyLabel.textColor = TreeShopTheme.primaryText
        accuracyLabel.text = "GPS: --"
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        statusLabel.textColor = TreeShopTheme.secondaryText
        statusLabel.text = "Acquiring..."
        
        // Coordinate Label
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        coordinateLabel.textColor = TreeShopTheme.tertiaryText
        coordinateLabel.text = "--°, --°"
        coordinateLabel.numberOfLines = 2
        
        stackView.addArrangedSubview(accuracyLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(coordinateLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func updateAccuracy(_ accuracy: CLLocationAccuracy, coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async { [weak self] in
            if accuracy < 0 {
                self?.accuracyLabel.text = "GPS: Invalid"
                self?.statusLabel.text = "No Signal"
                self?.accuracyLabel.textColor = TreeShopTheme.errorRed
                self?.statusLabel.textColor = TreeShopTheme.errorRed
            } else {
                let accuracyText = String(format: "GPS: ±%.1fm", accuracy)
                self?.accuracyLabel.text = accuracyText
                
                // Color coding based on accuracy
                if accuracy <= 3 {
                    self?.statusLabel.text = "Excellent"
                    self?.accuracyLabel.textColor = TreeShopTheme.successGreen
                    self?.statusLabel.textColor = TreeShopTheme.successGreen
                } else if accuracy <= 10 {
                    self?.statusLabel.text = "Good"
                    self?.accuracyLabel.textColor = TreeShopTheme.primaryGreen
                    self?.statusLabel.textColor = TreeShopTheme.primaryGreen
                } else if accuracy <= 50 {
                    self?.statusLabel.text = "Fair"
                    self?.accuracyLabel.textColor = TreeShopTheme.warningYellow
                    self?.statusLabel.textColor = TreeShopTheme.warningYellow
                } else {
                    self?.statusLabel.text = "Poor"
                    self?.accuracyLabel.textColor = TreeShopTheme.errorRed
                    self?.statusLabel.textColor = TreeShopTheme.errorRed
                }
            }
            
            // Update coordinates
            let latText = String(format: "%.6f°", coordinate.latitude)
            let lonText = String(format: "%.6f°", coordinate.longitude)
            self?.coordinateLabel.text = "\(latText)\n\(lonText)"
        }
    }
}