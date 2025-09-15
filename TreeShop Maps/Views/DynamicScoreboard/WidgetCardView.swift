import UIKit

// MARK: - Widget Card View with Blur Materials & Elevation

class WidgetCardView: UIView {
    
    // MARK: - UI Elements
    private let blurEffectView: UIVisualEffectView
    private let vibrancyEffectView: UIVisualEffectView
    private let contentView: UIView
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let valueLabel: UILabel
    private let subtitleLabel: UILabel
    private let trendView: TrendIndicatorView
    private let actionButton: UIButton
    
    // MARK: - Properties
    private var widgetData: WidgetData?
    private var tapAction: (() -> Void)?
    
    // MARK: - Card Styles
    enum CardStyle {
        case primary      // Large prominent card
        case secondary    // Medium card
        case compact      // Small card
        case metric       // Data-focused card
        
        var size: CGSize {
            switch self {
            case .primary: return CGSize(width: 180, height: 120)
            case .secondary: return CGSize(width: 140, height: 100)
            case .compact: return CGSize(width: 100, height: 80)
            case .metric: return CGSize(width: 120, height: 90)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .primary: return 16
            case .secondary: return 14
            case .compact: return 12
            case .metric: return 14
            }
        }
        
        var shadowOpacity: Float {
            switch self {
            case .primary: return 0.4
            case .secondary: return 0.3
            case .compact: return 0.25
            case .metric: return 0.3
            }
        }
    }
    
    private let cardStyle: CardStyle
    
    // MARK: - Initialization
    
    init(style: CardStyle = .secondary) {
        self.cardStyle = style
        
        // Create blur effect
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        // Create vibrancy effect for text
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)
        self.vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        
        // Initialize UI elements
        self.contentView = UIView()
        self.iconImageView = UIImageView()
        self.titleLabel = UILabel()
        self.valueLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.trendView = TrendIndicatorView()
        self.actionButton = UIButton(type: .system)
        
        super.init(frame: .zero)
        
        setupUI()
        setupLayout()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure container
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = cardStyle.cornerRadius
        layer.masksToBounds = false
        
        // Setup elevation/shadow
        setupElevation()
        
        // Configure blur background
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = cardStyle.cornerRadius
        blurEffectView.layer.masksToBounds = true
        addSubview(blurEffectView)
        
        // Configure vibrancy container
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        // Configure content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        vibrancyEffectView.contentView.addSubview(contentView)
        
        // Configure icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = TreeShopTheme.primaryGreen
        contentView.addSubview(iconImageView)
        
        // Configure title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: cardStyle == .compact ? 10 : 12, weight: .medium)
        titleLabel.textColor = TreeShopTheme.secondaryText
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        // Configure value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.monospacedDigitSystemFont(
            ofSize: cardStyle == .primary ? 24 : (cardStyle == .compact ? 16 : 20), 
            weight: .bold
        )
        valueLabel.textColor = TreeShopTheme.primaryText
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        contentView.addSubview(valueLabel)
        
        // Configure subtitle label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: cardStyle == .compact ? 8 : 10, weight: .regular)
        subtitleLabel.textColor = TreeShopTheme.tertiaryText
        subtitleLabel.numberOfLines = 1
        contentView.addSubview(subtitleLabel)
        
        // Configure trend indicator
        trendView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trendView)
        
        // Configure action button (hidden by default)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        contentView.addSubview(actionButton)
    }
    
    private func setupElevation() {
        // Create sophisticated shadow for depth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = cardStyle.shadowOpacity
        layer.shadowRadius = 8
        
        // Create subtle border for definition
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Blur effect fills container
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Vibrancy fills blur effect
            vibrancyEffectView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
            vibrancyEffectView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor),
            vibrancyEffectView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor),
            vibrancyEffectView.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor),
            
            // Content view with padding
            contentView.topAnchor.constraint(equalTo: vibrancyEffectView.contentView.topAnchor, constant: 12),
            contentView.leadingAnchor.constraint(equalTo: vibrancyEffectView.contentView.leadingAnchor, constant: 12),
            contentView.trailingAnchor.constraint(equalTo: vibrancyEffectView.contentView.trailingAnchor, constant: -12),
            contentView.bottomAnchor.constraint(equalTo: vibrancyEffectView.contentView.bottomAnchor, constant: -12),
            
            // Icon positioning
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: cardStyle == .compact ? 16 : 20),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),
            
            // Title positioning
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trendView.leadingAnchor, constant: -4),
            
            // Trend indicator
            trendView.topAnchor.constraint(equalTo: contentView.topAnchor),
            trendView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            trendView.widthAnchor.constraint(equalToConstant: cardStyle == .compact ? 40 : 50),
            trendView.heightAnchor.constraint(equalToConstant: cardStyle == .compact ? 16 : 20),
            
            // Value label (main content)
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: cardStyle == .compact ? 2 : 4),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Subtitle positioning
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        
        // Set intrinsic size
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: cardStyle.size.width),
            heightAnchor.constraint(equalToConstant: cardStyle.size.height)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    // MARK: - Public Methods
    
    func configure(with data: WidgetData) {
        self.widgetData = data
        self.tapAction = data.action
        
        // Update content
        if let iconName = data.icon {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
        
        titleLabel.text = data.title
        valueLabel.text = data.value
        valueLabel.textColor = data.color
        subtitleLabel.text = data.subtitle
        subtitleLabel.isHidden = data.subtitle == nil
        
        // Configure trend
        if let trend = data.trend {
            trendView.configure(with: trend)
            trendView.isHidden = false
        } else {
            trendView.isHidden = true
        }
        
        // Update accessibility
        accessibilityLabel = "\(data.title): \(data.value)"
        if let subtitle = data.subtitle {
            accessibilityLabel = (accessibilityLabel ?? "") + ", \(subtitle)"
        }
    }
    
    func startPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    func stopPulseAnimation() {
        layer.removeAnimation(forKey: "pulse")
    }
    
    func highlightWithColor(_ color: UIColor) {
        UIView.animate(withDuration: 0.3, animations: {
            self.layer.borderColor = color.cgColor
            self.layer.borderWidth = 2.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0) {
                self.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
                self.layer.borderWidth = 0.5
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        // Execute action
        tapAction?()
    }
}

// MARK: - Trend Indicator View

class TrendIndicatorView: UIView {
    private let iconImageView = UIImageView()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
        
        // Configure label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        valueLabel.textAlignment = .right
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 14),
            iconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            valueLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 2),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with trend: WidgetTrend) {
        iconImageView.image = UIImage(systemName: trend.icon)
        iconImageView.tintColor = trend.color
        valueLabel.text = trend.text
        valueLabel.textColor = trend.color
        isHidden = false
    }
}

// MARK: - Widget Collection Layout

class WidgetCollectionLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    private func setupLayout() {
        scrollDirection = .vertical
        minimumInteritemSpacing = 12
        minimumLineSpacing = 12
        sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        // Add subtle staggered animation support
        attributes?.enumerated().forEach { index, attribute in
            let delay = Double(index) * 0.05
            attribute.alpha = 1.0
        }
        
        return attributes
    }
}