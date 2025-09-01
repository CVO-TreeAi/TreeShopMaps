import UIKit
import SafariServices

class AboutViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let logoImageView = UIImageView()
    private let appNameLabel = UILabel()
    private let versionLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let websiteButton = UIButton(type: .system)
    private let featuresStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        title = "About"
        
        // Configure close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            target: self,
            action: #selector(dismissViewController)
        )
        
        setupScrollView()
        setupLogoAndTitle()
        setupDescription()
        setupWebsiteButton()
        setupFeatures()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupLogoAndTitle() {
        // Logo
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "TreeShopLogo")
        logoImageView.contentMode = .scaleAspectFit
        contentView.addSubview(logoImageView)
        
        // App Name
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appNameLabel.text = "Maps"
        appNameLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        appNameLabel.textColor = TreeShopTheme.primaryText
        appNameLabel.textAlignment = .center
        contentView.addSubview(appNameLabel)
        
        // Version
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = "Version \(version) (\(build))"
        } else {
            versionLabel.text = "Version 1.0"
        }
        versionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        versionLabel.textColor = TreeShopTheme.secondaryText
        versionLabel.textAlignment = .center
        contentView.addSubview(versionLabel)
    }
    
    private func setupDescription() {
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Professional forestry mapping and measurement tool. Accurately measure areas, distances, and manage forestry data with precision GPS tracking."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = TreeShopTheme.primaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(descriptionLabel)
    }
    
    private func setupWebsiteButton() {
        websiteButton.translatesAutoresizingMaskIntoConstraints = false
        websiteButton.setTitle("Visit treeshop.app", for: .normal)
        websiteButton.setTitleColor(.white, for: .normal)
        websiteButton.backgroundColor = TreeShopTheme.primaryGreen
        websiteButton.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        websiteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        websiteButton.addTarget(self, action: #selector(openWebsite), for: .touchUpInside)
        
        // Add icon to button
        let globe = UIImage(systemName: "globe")
        websiteButton.setImage(globe, for: .normal)
        websiteButton.tintColor = .white
        websiteButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        
        contentView.addSubview(websiteButton)
    }
    
    private func setupFeatures() {
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 16
        featuresStackView.alignment = .fill
        
        let features = [
            "📐 Precise Area & Distance Measurement",
            "🗺️ Professional GPS Mapping",
            "🌲 Forestry-Focused Tools",
            "💾 Measurement History & Export",
            "🎯 High-Accuracy GPS Tracking",
            "📊 Professional Reporting"
        ]
        
        for feature in features {
            let featureCard = createFeatureCard(text: feature)
            featuresStackView.addArrangedSubview(featureCard)
        }
        
        contentView.addSubview(featuresStackView)
    }
    
    private func createFeatureCard(text: String) -> UIView {
        let cardView = TreeShopTheme.cardView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = TreeShopTheme.primaryText
        label.numberOfLines = 0
        
        cardView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        return cardView
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // App name
            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            appNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Version
            versionLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 4),
            versionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Website button
            websiteButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            websiteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            websiteButton.widthAnchor.constraint(equalToConstant: 200),
            websiteButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Features
            featuresStackView.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: 32),
            featuresStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            featuresStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            featuresStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupContent() {
        // Any additional content setup can go here
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    @objc private func openWebsite() {
        guard let url = URL(string: "https://treeshop.app") else { return }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = TreeShopTheme.backgroundColor
        safariVC.preferredControlTintColor = TreeShopTheme.primaryGreen
        
        present(safariVC, animated: true)
    }
}