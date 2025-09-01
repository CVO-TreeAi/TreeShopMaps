import UIKit

class SimpleBrandedTitleView: UIView {
    
    private let logoImageView = UIImageView()
    private let mapsLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Logo setup
        logoImageView.image = UIImage(named: "TreeShopLogo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoImageView)
        
        // "Maps" label setup
        mapsLabel.text = "Maps"
        mapsLabel.font = UIFont(name: "Futura-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        mapsLabel.textColor = TreeShopTheme.primaryGreen
        mapsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapsLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Logo
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 30),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            
            // Maps label
            mapsLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8),
            mapsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            mapsLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 200, height: 44)
    }
}