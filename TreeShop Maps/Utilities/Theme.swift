import UIKit

struct TreeShopTheme {
    // Primary Colors
    static let primaryGreen = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
    static let accentGreen = UIColor(red: 129/255, green: 199/255, blue: 132/255, alpha: 1.0)
    
    // Background Colors
    static let backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1.0)
    static let cardBackground = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
    static let secondaryBackground = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1.0)
    
    // Text Colors
    static let primaryText = UIColor.white
    static let secondaryText = UIColor(white: 0.7, alpha: 1.0)
    static let tertiaryText = UIColor(white: 0.5, alpha: 1.0)
    
    // Button Colors
    static let buttonBackground = UIColor(red: 45/255, green: 45/255, blue: 45/255, alpha: 1.0)
    static let buttonHighlight = UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1.0)
    
    // Status Colors
    static let successGreen = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
    static let warningYellow = UIColor(red: 255/255, green: 193/255, blue: 7/255, alpha: 1.0)
    static let errorRed = UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1.0)
    
    // Service Package Colors (matching your UI)
    static let packageSmall = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 0.6)
    static let packageMedium = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 0.6) // Green for Medium
    static let packageLarge = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 0.6)
    static let packageXLarge = UIColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 0.6)
    static let packageMax = UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 0.7)
    
    // Corner Radius
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    
    // Apply theme to navigation bar
    static func applyNavigationBarTheme(to navigationController: UINavigationController?) {
        guard let navBar = navigationController?.navigationBar else { return }
        
        navBar.barStyle = .black
        navBar.isTranslucent = true
        navBar.barTintColor = backgroundColor
        navBar.tintColor = primaryGreen
        navBar.titleTextAttributes = [
            .foregroundColor: primaryText,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.titleTextAttributes = [
                .foregroundColor: primaryText,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        }
    }
    
    // Apply theme to toolbar
    static func applyToolbarTheme(to toolbar: UIToolbar) {
        toolbar.barStyle = .black
        toolbar.isTranslucent = false
        toolbar.barTintColor = cardBackground
        toolbar.tintColor = primaryGreen
        
        if #available(iOS 15.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = cardBackground
            toolbar.standardAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
        }
    }
    
    // Create styled button
    static func styledButton(title: String, icon: UIImage? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(icon, for: .normal)
        button.backgroundColor = buttonBackground
        button.setTitleColor(primaryText, for: .normal)
        button.layer.cornerRadius = smallCornerRadius
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            config.title = title
            config.image = icon
            button.configuration = config
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        }
        
        return button
    }
    
    // Create card view
    static func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = cardBackground
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
        return view
    }
}