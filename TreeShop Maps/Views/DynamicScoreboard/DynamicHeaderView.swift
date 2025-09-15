import UIKit

// MARK: - Dynamic Header View

protocol DynamicHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapOptionsButton()
}

class DynamicHeaderView: UIView {
    
    // MARK: - UI Elements
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let optionsButton = UIButton(type: .system)
    private let statusIndicator = StatusIndicatorView()
    
    // MARK: - Properties
    weak var delegate: DynamicHeaderViewDelegate?
    private var primaryColor: UIColor = TreeShopTheme.primaryGreen
    
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
        
        // Configure back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left.circle.fill"), for: .normal)
        backButton.tintColor = TreeShopTheme.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isHidden = true
        addSubview(backButton)
        
        // Configure title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)
        
        // Configure subtitle label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = TreeShopTheme.secondaryText
        subtitleLabel.numberOfLines = 1
        addSubview(subtitleLabel)
        
        // Configure progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = TreeShopTheme.primaryGreen
        progressView.trackTintColor = TreeShopTheme.buttonBackground
        progressView.layer.cornerRadius = 2
        progressView.layer.masksToBounds = true
        progressView.isHidden = true
        addSubview(progressView)
        
        // Configure options button
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        optionsButton.tintColor = TreeShopTheme.secondaryText
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        addSubview(optionsButton)
        
        // Configure status indicator
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusIndicator)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Back button
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Status indicator
            statusIndicator.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: optionsButton.leadingAnchor, constant: -8),
            
            // Subtitle label
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Progress view
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Options button
            optionsButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            optionsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: 32),
            optionsButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(title: String, subtitle: String, primaryColor: UIColor, progress: Float? = nil, canGoBack: Bool = false) {
        self.primaryColor = primaryColor
        
        // Animate text changes
        UIView.transition(with: titleLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.titleLabel.text = title
        }
        
        UIView.transition(with: subtitleLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.subtitleLabel.text = subtitle
        }
        
        // Update back button visibility
        UIView.animate(withDuration: 0.25) {
            self.backButton.alpha = canGoBack ? 1.0 : 0.0
            self.backButton.isHidden = !canGoBack
        }
        
        // Update progress
        if let progress = progress {
            progressView.isHidden = false
            progressView.setProgress(progress, animated: true)
            progressView.progressTintColor = primaryColor
        } else {
            progressView.isHidden = true
        }
        
        // Update status indicator
        statusIndicator.setStatus(.active, color: primaryColor)
        
        // Update accessibility
        accessibilityLabel = "\(title), \(subtitle)"
        if let progress = progress {
            accessibilityLabel = (accessibilityLabel ?? "") + ", \(Int(progress * 100))% complete"
        }
    }
    
    func showLoadingState() {
        statusIndicator.setStatus(.loading, color: primaryColor)
        
        UIView.animate(withDuration: 0.25) {
            self.titleLabel.alpha = 0.6
            self.subtitleLabel.alpha = 0.6
        }
    }
    
    func hideLoadingState() {
        statusIndicator.setStatus(.active, color: primaryColor)
        
        UIView.animate(withDuration: 0.25) {
            self.titleLabel.alpha = 1.0
            self.subtitleLabel.alpha = 1.0
        }
    }
    
    func showError(message: String) {
        statusIndicator.setStatus(.error, color: TreeShopTheme.errorRed)
        
        // Temporarily show error message
        let originalSubtitle = subtitleLabel.text
        subtitleLabel.text = message
        subtitleLabel.textColor = TreeShopTheme.errorRed
        
        // Revert after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.subtitleLabel.text = originalSubtitle
            self.subtitleLabel.textColor = TreeShopTheme.secondaryText
            self.statusIndicator.setStatus(.active, color: self.primaryColor)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        delegate?.didTapBackButton()
    }
    
    @objc private func optionsButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        delegate?.didTapOptionsButton()
    }
}

// MARK: - Status Indicator View

class StatusIndicatorView: UIView {
    
    enum Status {
        case active
        case loading
        case error
        case success
    }
    
    private let indicatorLayer = CALayer()
    private let pulseLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.addSublayer(indicatorLayer)
        layer.addSublayer(pulseLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        indicatorLayer.frame = bounds
        indicatorLayer.cornerRadius = bounds.width / 2
        
        pulseLayer.frame = bounds.insetBy(dx: -2, dy: -2)
        let pulsePath = UIBezierPath(ovalIn: pulseLayer.bounds)
        pulseLayer.path = pulsePath.cgPath
    }
    
    func setStatus(_ status: Status, color: UIColor) {
        indicatorLayer.backgroundColor = color.cgColor
        
        switch status {
        case .active:
            stopAllAnimations()
            
        case .loading:
            startLoadingAnimation(color: color)
            
        case .error:
            stopAllAnimations()
            startErrorAnimation()
            
        case .success:
            stopAllAnimations()
            startSuccessAnimation(color: color)
        }
    }
    
    private func startLoadingAnimation(color: UIColor) {
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 1.0
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        pulseLayer.fillColor = color.withAlphaComponent(0.3).cgColor
        pulseLayer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func startErrorAnimation() {
        let shakeAnimation = CABasicAnimation(keyPath: "position.x")
        shakeAnimation.fromValue = indicatorLayer.position.x - 2
        shakeAnimation.toValue = indicatorLayer.position.x + 2
        shakeAnimation.duration = 0.1
        shakeAnimation.autoreverses = true
        shakeAnimation.repeatCount = 3
        
        indicatorLayer.add(shakeAnimation, forKey: "shake")
    }
    
    private func startSuccessAnimation(color: UIColor) {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.3
        scaleAnimation.duration = 0.2
        scaleAnimation.autoreverses = true
        
        indicatorLayer.add(scaleAnimation, forKey: "success")
    }
    
    private func stopAllAnimations() {
        indicatorLayer.removeAllAnimations()
        pulseLayer.removeAllAnimations()
        pulseLayer.fillColor = UIColor.clear.cgColor
    }
}