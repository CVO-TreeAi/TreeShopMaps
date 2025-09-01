import UIKit

class BrandedNavigationTitleView: UIView {
    
    private let logoImageView = UIImageView()
    private let mapsLabel = UILabel()
    private let containerStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        setupLogoImageView()
        setupMapsLabel()
        setupStackView()
        setupConstraints()
    }
    
    private func setupLogoImageView() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "TreeShopLogo")
        logoImageView.contentMode = .scaleAspectFit
        
        // The TreeShop logo is already colored (blue), so we don't need to tint it
        // Instead, we'll ensure it looks good on both light and dark backgrounds
        logoImageView.backgroundColor = UIColor.clear
        
        // Add a subtle drop shadow to help the logo stand out on any background
        logoImageView.layer.shadowColor = UIColor.black.cgColor
        logoImageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        logoImageView.layer.shadowOpacity = 0.2
        logoImageView.layer.shadowRadius = 2
    }
    
    private func setupMapsLabel() {
        mapsLabel.translatesAutoresizingMaskIntoConstraints = false
        mapsLabel.text = "Maps"
        
        // Use a modern, stylish font that complements the logo
        // Scale font size based on screen size for better responsiveness
        let screenSize = UIScreen.main.bounds.size
        let fontSize: CGFloat = screenSize.width < 375 ? 20 : 22  // Smaller font on smaller devices
        
        if let customFont = UIFont(name: "Futura-Medium", size: fontSize) {
            mapsLabel.font = customFont
        } else if let customFont = UIFont(name: "AvenirNext-Medium", size: fontSize) {
            mapsLabel.font = customFont
        } else if let customFont = UIFont(name: "HelveticaNeue-Medium", size: fontSize) {
            mapsLabel.font = customFont
        } else {
            // Fallback to system font with distinctive characteristics
            mapsLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        }
        
        mapsLabel.textColor = TreeShopTheme.primaryText
        mapsLabel.textAlignment = .left
        mapsLabel.adjustsFontSizeToFitWidth = true
        mapsLabel.minimumScaleFactor = 0.8
        
        // Add subtle text effects for a professional look
        mapsLabel.layer.shadowColor = UIColor.black.cgColor
        mapsLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        mapsLabel.layer.shadowOpacity = 0.3
        mapsLabel.layer.shadowRadius = 2
    }
    
    private func setupStackView() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = 12 // Nice spacing between logo and text
        
        containerStackView.addArrangedSubview(logoImageView)
        containerStackView.addArrangedSubview(mapsLabel)
        
        addSubview(containerStackView)
    }
    
    private func setupConstraints() {
        // Responsive sizing based on screen width
        let screenSize = UIScreen.main.bounds.size
        let logoWidth: CGFloat = screenSize.width < 375 ? 70 : 80  // Smaller logo on smaller devices
        let logoHeight: CGFloat = screenSize.width < 375 ? 28 : 32
        let containerWidth: CGFloat = screenSize.width < 375 ? 125 : 140
        
        NSLayoutConstraint.activate([
            // Stack view fills the container
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Logo constraints - maintain aspect ratio while fitting navigation bar
            logoImageView.widthAnchor.constraint(equalToConstant: logoWidth),
            logoImageView.heightAnchor.constraint(equalToConstant: logoHeight),
            
            // Container view size
            widthAnchor.constraint(equalToConstant: containerWidth),
            heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // Method to update colors for dark mode if needed
    func updateForCurrentTraitCollection() {
        if #available(iOS 13.0, *) {
            mapsLabel.textColor = TreeShopTheme.primaryText
            
            // Update shadow for current interface style
            if traitCollection.userInterfaceStyle == .dark {
                mapsLabel.layer.shadowOpacity = 0.5
                mapsLabel.layer.shadowColor = UIColor.black.cgColor
            } else {
                mapsLabel.layer.shadowOpacity = 0.3
                mapsLabel.layer.shadowColor = UIColor.gray.cgColor
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateForCurrentTraitCollection()
            }
        }
    }
}