import UIKit

// MARK: - Action Bar View

protocol ActionBarViewDelegate: AnyObject {
    func didTapAction(_ action: ScoreboardAction)
}

class ActionBarView: UIView {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let fadeGradientLayer = CAGradientLayer()
    
    // MARK: - Properties
    weak var delegate: ActionBarViewDelegate?
    private var currentActions: [ScoreboardAction] = []
    private var actionButtons: [ActionButton] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.clipsToBounds = false
        addSubview(scrollView)
        
        // Configure stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.alignment = .center
        scrollView.addSubview(stackView)
        
        // Setup fade gradient for scroll indication
        setupFadeGradient()
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Scroll view fills the action bar
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Stack view positioning
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func setupFadeGradient() {
        fadeGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        fadeGradientLayer.locations = [0.0, 0.1, 0.9, 1.0]
        fadeGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fadeGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.mask = fadeGradientLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fadeGradientLayer.frame = bounds
    }
    
    // MARK: - Public Methods
    
    func configure(with actions: [ScoreboardAction]) {
        currentActions = actions
        updateActionButtons()
    }
    
    private func updateActionButtons() {
        // Remove existing buttons
        actionButtons.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        
        // Add new buttons
        for (index, action) in currentActions.enumerated() {
            let button = ActionButton(action: action)
            button.delegate = self
            button.tag = index
            
            stackView.addArrangedSubview(button)
            actionButtons.append(button)
        }
        
        // Animate button appearance
        animateButtonsAppearance()
    }
    
    private func animateButtonsAppearance() {
        actionButtons.enumerated().forEach { index, button in
            button.alpha = 0
            button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(
                withDuration: 0.4,
                delay: Double(index) * 0.1,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5
            ) {
                button.alpha = 1.0
                button.transform = .identity
            }
        }
    }
    
    func highlightAction(withId id: String) {
        if let index = currentActions.firstIndex(where: { $0.id == id }),
           index < actionButtons.count {
            actionButtons[index].highlight()
        }
    }
    
    func resetHighlights() {
        actionButtons.forEach { $0.resetHighlight() }
    }
}

// MARK: - Action Button Delegate

extension ActionBarView: ActionButtonDelegate {
    func didTapActionButton(_ button: ActionButton) {
        guard button.tag < currentActions.count else { return }
        let action = currentActions[button.tag]
        delegate?.didTapAction(action)
    }
}

// MARK: - Action Button

protocol ActionButtonDelegate: AnyObject {
    func didTapActionButton(_ button: ActionButton)
}

class ActionButton: UIButton {
    
    // MARK: - Properties
    weak var delegate: ActionButtonDelegate?
    private let action: ScoreboardAction
    private let blurEffectView: UIVisualEffectView
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    // MARK: - Initialization
    
    init(action: ScoreboardAction) {
        self.action = action
        
        // Create blur background
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: .zero)
        
        setupUI()
        setupLayout()
        configure(with: action)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Configure blur background
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 20
        blurEffectView.layer.masksToBounds = true
        blurEffectView.isUserInteractionEnabled = false
        addSubview(blurEffectView)
        
        // Configure icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        blurEffectView.contentView.addSubview(iconImageView)
        
        // Configure title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        blurEffectView.contentView.addSubview(titleLabel)
        
        // Add target
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Blur background fills button
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Button size
            widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            heightAnchor.constraint(equalToConstant: 40),
            
            // Icon positioning (if present)
            iconImageView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: blurEffectView.contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // Title positioning
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: blurEffectView.contentView.centerYAnchor)
        ])
    }
    
    private func configure(with action: ScoreboardAction) {
        titleLabel.text = action.title
        titleLabel.textColor = action.style.textColor
        
        if let iconName = action.icon {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.tintColor = action.style.textColor
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
            
            // Adjust title constraints when no icon
            titleLabel.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 12).isActive = true
        }
        
        // Apply style-specific appearance
        updateAppearance()
        
        // Accessibility
        accessibilityLabel = action.title
        accessibilityHint = "Button"
    }
    
    private func updateAppearance() {
        // Add colored overlay for different styles
        let overlayColor = action.style.backgroundColor.withAlphaComponent(0.3)
        blurEffectView.backgroundColor = overlayColor
        
        // Add subtle border for primary actions
        if action.style == .primary {
            layer.borderWidth = 1.0
            layer.borderColor = action.style.backgroundColor.withAlphaComponent(0.5).cgColor
            layer.cornerRadius = 20
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func buttonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        delegate?.didTapActionButton(self)
    }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
    
    // MARK: - Animation Methods
    
    func highlight() {
        UIView.animate(withDuration: 0.3, animations: {
            self.layer.borderWidth = 2.0
            self.layer.borderColor = TreeShopTheme.primaryGreen.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0) {
                self.layer.borderWidth = action.style == .primary ? 1.0 : 0.0
                self.layer.borderColor = self.action.style == .primary ? 
                    self.action.style.backgroundColor.withAlphaComponent(0.5).cgColor : 
                    UIColor.clear.cgColor
            }
        }
    }
    
    func resetHighlight() {
        layer.borderWidth = action.style == .primary ? 1.0 : 0.0
        layer.borderColor = action.style == .primary ? 
            action.style.backgroundColor.withAlphaComponent(0.5).cgColor : 
            UIColor.clear.cgColor
    }
    
    func startPulse() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    func stopPulse() {
        layer.removeAnimation(forKey: "pulse")
    }
}