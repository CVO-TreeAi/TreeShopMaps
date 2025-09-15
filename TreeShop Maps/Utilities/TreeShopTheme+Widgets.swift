import UIKit

// MARK: - TreeShop Theme Widget Extensions

extension TreeShopTheme {
    
    // MARK: - Widget-Specific Colors
    
    /// Enhanced colors specifically for widget styling
    static let widgetCardBackground = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 0.95)
    static let widgetCardBorder = UIColor.white.withAlphaComponent(0.15)
    static let widgetCardShadow = UIColor.black.withAlphaComponent(0.4)
    
    /// Widget accent colors for different data types
    static let metricBlue = UIColor(red: 64/255, green: 156/255, blue: 255/255, alpha: 1.0)
    static let metricOrange = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1.0)
    static let metricPurple = UIColor(red: 191/255, green: 90/255, blue: 242/255, alpha: 1.0)
    static let metricTeal = UIColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1.0)
    
    /// Status indicator colors
    static let statusActive = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
    static let statusWarning = UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1.0)
    static let statusCritical = UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1.0)
    static let statusInfo = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1.0)
    
    // MARK: - Widget Card Styling
    
    /// Creates a styled widget card with professional blur effects
    static func createWidgetCard(style: WidgetCardStyle = .standard) -> UIView {
        let cardView = UIView()
        
        // Configure blur background
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = style.cornerRadius
        blurView.layer.masksToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(blurView)
        
        // Configure card appearance
        cardView.layer.cornerRadius = style.cornerRadius
        cardView.layer.shadowColor = widgetCardShadow.cgColor
        cardView.layer.shadowOffset = style.shadowOffset
        cardView.layer.shadowOpacity = style.shadowOpacity
        cardView.layer.shadowRadius = style.shadowRadius
        cardView.layer.masksToBounds = false
        
        // Add subtle border
        cardView.layer.borderWidth = 0.5
        cardView.layer.borderColor = widgetCardBorder.cgColor
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
        
        return cardView
    }
    
    // MARK: - Typography for Widgets
    
    static let widgetTitleFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let widgetValueFont = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
    static let widgetSubtitleFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    static let widgetLargeValueFont = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .heavy)
    
    /// Creates consistent text styling for widget labels
    static func styleWidgetLabel(_ label: UILabel, type: WidgetLabelType) {
        switch type {
        case .title:
            label.font = widgetTitleFont
            label.textColor = secondaryText
            
        case .value:
            label.font = widgetValueFont
            label.textColor = primaryText
            
        case .largeValue:
            label.font = widgetLargeValueFont
            label.textColor = primaryGreen
            
        case .subtitle:
            label.font = widgetSubtitleFont
            label.textColor = tertiaryText
        }
        
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
    }
    
    // MARK: - Animation Presets
    
    /// Standard widget appearance animation
    static func animateWidgetAppearance(_ view: UIView, delay: TimeInterval = 0) {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(
            withDuration: 0.6,
            delay: delay,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.3
        ) {
            view.alpha = 1.0
            view.transform = .identity
        }
    }
    
    /// Widget data update animation
    static func animateWidgetDataUpdate(_ view: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            view.alpha = 0.7
            view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            completion()
            
            UIView.animate(withDuration: 0.3) {
                view.alpha = 1.0
                view.transform = .identity
            }
        }
    }
    
    /// Widget highlight animation for user interaction
    static func animateWidgetHighlight(_ view: UIView) {
        let originalBorderColor = view.layer.borderColor
        let originalBorderWidth = view.layer.borderWidth
        
        UIView.animate(withDuration: 0.15, animations: {
            view.layer.borderColor = primaryGreen.cgColor
            view.layer.borderWidth = 2.0
            view.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0.1) {
                view.layer.borderColor = originalBorderColor
                view.layer.borderWidth = originalBorderWidth
                view.transform = .identity
            }
        }
    }
    
    // MARK: - Action Button Styling
    
    static func styleActionButton(_ button: UIButton, style: ActionButtonStyle) {
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        switch style {
        case .primary:
            button.backgroundColor = primaryGreen
            button.setTitleColor(.white, for: .normal)
            button.layer.shadowColor = primaryGreen.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowOpacity = 0.3
            button.layer.shadowRadius = 4
            
        case .secondary:
            button.backgroundColor = buttonBackground
            button.setTitleColor(primaryText, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = widgetCardBorder.cgColor
            
        case .destructive:
            button.backgroundColor = errorRed
            button.setTitleColor(.white, for: .normal)
            button.layer.shadowColor = errorRed.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowOpacity = 0.3
            button.layer.shadowRadius = 4
            
        case .success:
            button.backgroundColor = successGreen
            button.setTitleColor(.white, for: .normal)
            button.layer.shadowColor = successGreen.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowOpacity = 0.3
            button.layer.shadowRadius = 4
        }
    }
    
    // MARK: - Gradient Utilities
    
    /// Creates a subtle gradient for widget backgrounds
    static func createWidgetGradientLayer(colors: [UIColor], cornerRadius: CGFloat) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = cornerRadius
        return gradientLayer
    }
    
    /// Status-based gradient colors
    static func getStatusGradient(for status: WidgetStatus) -> [UIColor] {
        switch status {
        case .normal:
            return [widgetCardBackground, cardBackground]
        case .active:
            return [statusActive.withAlphaComponent(0.1), widgetCardBackground]
        case .warning:
            return [statusWarning.withAlphaComponent(0.1), widgetCardBackground]
        case .critical:
            return [statusCritical.withAlphaComponent(0.1), widgetCardBackground]
        }
    }
}

// MARK: - Supporting Enums

enum WidgetCardStyle {
    case standard
    case compact
    case prominent
    
    var cornerRadius: CGFloat {
        switch self {
        case .standard: return 12
        case .compact: return 10
        case .prominent: return 16
        }
    }
    
    var shadowOffset: CGSize {
        switch self {
        case .standard: return CGSize(width: 0, height: 3)
        case .compact: return CGSize(width: 0, height: 2)
        case .prominent: return CGSize(width: 0, height: 6)
        }
    }
    
    var shadowOpacity: Float {
        switch self {
        case .standard: return 0.3
        case .compact: return 0.25
        case .prominent: return 0.4
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .standard: return 6
        case .compact: return 4
        case .prominent: return 10
        }
    }
}

enum WidgetLabelType {
    case title
    case value
    case largeValue
    case subtitle
}

enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
    case success
}

enum WidgetStatus {
    case normal
    case active
    case warning
    case critical
}

// MARK: - Visual Effect Extensions

extension UIVisualEffectView {
    
    /// Creates a TreeShop-styled blur effect view
    static func treeShopBlurView(style: UIBlurEffect.Style = .systemThinMaterialDark) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Add vibrancy effect for text
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.contentView.addSubview(vibrancyView)
        
        NSLayoutConstraint.activate([
            vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
        ])
        
        return blurView
    }
}

// MARK: - Haptic Feedback Utilities

extension TreeShopTheme {
    
    /// Provides consistent haptic feedback for widget interactions
    static func provideHapticFeedback(for interaction: WidgetInteraction) {
        switch interaction {
        case .tap:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
        case .longPress:
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            
        case .selection:
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
            
        case .success:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
        case .warning:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.warning)
            
        case .error:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        }
    }
}

enum WidgetInteraction {
    case tap
    case longPress
    case selection
    case success
    case warning
    case error
}