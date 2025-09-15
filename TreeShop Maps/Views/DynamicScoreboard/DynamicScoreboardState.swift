import UIKit
import MapKit

/// Dynamic Scoreboard State Management
enum ScoreboardState {
    case defaultView
    case areaDrawing(areaData: AreaDrawingData)
    case treeSelected(tree: TreeInventoryItem)
    case measurement(measurementData: MeasurementData)
    case packageSelection
}

struct AreaDrawingData {
    let area: Double
    let perimeter: Double
    let pointCount: Int
    let package: ServicePackage
    let estimatedCost: Double
}

struct MeasurementData {
    let distance: Double
    let coordinates: CLLocationCoordinate2D
    let accuracy: Double
    let type: String
}

/// Dynamic Scoreboard Controller
class DynamicScoreboardViewController: UIViewController {
    
    // MARK: - Properties
    private var currentState: ScoreboardState = .defaultView
    private var stateHistory: [ScoreboardState] = []
    
    // UI Components
    private var mainContainer: UIView!
    private var headerContainer: UIView!
    private var widgetGrid: UIStackView!
    private var actionBar: UIView!
    
    // Blur Effects
    private var backgroundBlur: UIVisualEffectView!
    private var headerBlur: UIVisualEffectView!
    
    // Data Source
    weak var dataProvider: ScoreboardDataProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDynamicScoreboard()
        transitionToState(.defaultView)
    }
    
    // MARK: - Setup
    private func setupDynamicScoreboard() {
        view.backgroundColor = .clear
        
        // Background blur effect
        backgroundBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        backgroundBlur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundBlur)
        
        // Main container with elevation
        mainContainer = UIView()
        mainContainer.backgroundColor = TreeShopTheme.cardBackground.withAlphaComponent(0.95)
        mainContainer.layer.cornerRadius = 20
        mainContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        mainContainer.layer.shadowColor = UIColor.black.cgColor
        mainContainer.layer.shadowOpacity = 0.4
        mainContainer.layer.shadowOffset = CGSize(width: 0, height: -4)
        mainContainer.layer.shadowRadius = 12
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        setupHeader()
        setupWidgetGrid()
        setupActionBar()
        setupConstraints()
    }
    
    private func setupHeader() {
        headerContainer = UIView()
        headerContainer.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        headerContainer.layer.cornerRadius = 16
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(headerContainer)
    }
    
    private func setupWidgetGrid() {
        widgetGrid = UIStackView()
        widgetGrid.axis = .horizontal
        widgetGrid.distribution = .fillEqually
        widgetGrid.spacing = 12
        widgetGrid.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(widgetGrid)
    }
    
    private func setupActionBar() {
        actionBar = UIView()
        actionBar.backgroundColor = TreeShopTheme.buttonBackground.withAlphaComponent(0.8)
        actionBar.layer.cornerRadius = 12
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(actionBar)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            headerContainer.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 12),
            headerContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 12),
            headerContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -12),
            headerContainer.heightAnchor.constraint(equalToConstant: 44),
            
            widgetGrid.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            widgetGrid.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 12),
            widgetGrid.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -12),
            widgetGrid.heightAnchor.constraint(equalToConstant: 80),
            
            actionBar.topAnchor.constraint(equalTo: widgetGrid.bottomAnchor, constant: 16),
            actionBar.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 12),
            actionBar.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -12),
            actionBar.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -12),
            actionBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - State Transitions
    func transitionToState(_ newState: ScoreboardState, animated: Bool = true) {
        stateHistory.append(currentState)
        currentState = newState
        
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
                self.updateUI()
            }
        } else {
            updateUI()
        }
    }
    
    private func updateUI() {
        clearCurrentWidgets()
        
        switch currentState {
        case .defaultView:
            setupDefaultWidgets()
        case .areaDrawing(let areaData):
            setupAreaDrawingWidgets(areaData)
        case .treeSelected(let tree):
            setupTreeSelectedWidgets(tree)
        case .measurement(let measurementData):
            setupMeasurementWidgets(measurementData)
        case .packageSelection:
            setupPackageSelectionWidgets()
        }
        
        updateHeader()
        updateActionBar()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func clearCurrentWidgets() {
        widgetGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        headerContainer.subviews.forEach { $0.removeFromSuperview() }
        actionBar.subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Widget Configurations
    private func setupDefaultWidgets() {
        let areaWidget = createWidget(title: "Area", value: "0.12 ac", icon: "🏞️", color: TreeShopTheme.primaryGreen)
        let treeWidget = createWidget(title: "Trees", value: "3", icon: "🌳", color: TreeShopTheme.accentGreen)
        let gpsWidget = createWidget(title: "GPS", value: "±2.1m", icon: "📍", color: TreeShopTheme.successGreen)
        
        widgetGrid.addArrangedSubview(areaWidget)
        widgetGrid.addArrangedSubview(treeWidget)
        widgetGrid.addArrangedSubview(gpsWidget)
    }
    
    private func setupAreaDrawingWidgets(_ data: AreaDrawingData) {
        let areaWidget = createWidget(title: "Area", value: String(format: "%.2f ac", data.area), icon: "📐", color: TreeShopTheme.primaryGreen)
        let packageWidget = createWidget(title: "Package", value: data.package.rawValue, icon: "📦", color: data.package.color)
        let costWidget = createWidget(title: "Est. Cost", value: String(format: "$%.0f", data.estimatedCost), icon: "💰", color: TreeShopTheme.successGreen)
        
        widgetGrid.addArrangedSubview(areaWidget)
        widgetGrid.addArrangedSubview(packageWidget)
        widgetGrid.addArrangedSubview(costWidget)
    }
    
    private func setupTreeSelectedWidgets(_ tree: TreeInventoryItem) {
        let heightWidget = createWidget(title: "Height", value: String(format: "%.0f ft", tree.height), icon: "📏", color: TreeShopTheme.primaryGreen)
        let scoreWidget = createWidget(title: "TreeScore", value: String(format: "%.0f", tree.treeScore.finalTreeScore), icon: "⚡", color: TreeShopTheme.warningYellow)
        let healthWidget = createWidget(title: "Health", value: "Good", icon: "💚", color: TreeShopTheme.successGreen)
        
        widgetGrid.addArrangedSubview(heightWidget)
        widgetGrid.addArrangedSubview(scoreWidget)
        widgetGrid.addArrangedSubview(healthWidget)
    }
    
    private func setupMeasurementWidgets(_ data: MeasurementData) {
        let distanceWidget = createWidget(title: "Distance", value: String(format: "%.1f ft", data.distance), icon: "📐", color: TreeShopTheme.primaryGreen)
        let accuracyWidget = createWidget(title: "Accuracy", value: String(format: "±%.1fm", data.accuracy), icon: "🎯", color: TreeShopTheme.successGreen)
        let coordWidget = createWidget(title: "Location", value: "GPS", icon: "📍", color: TreeShopTheme.accentGreen)
        
        widgetGrid.addArrangedSubview(distanceWidget)
        widgetGrid.addArrangedSubview(accuracyWidget)
        widgetGrid.addArrangedSubview(coordWidget)
    }
    
    private func setupPackageSelectionWidgets() {
        let smallWidget = createPackageWidget("Small", package: .small)
        let mediumWidget = createPackageWidget("Medium", package: .medium)
        let largeWidget = createPackageWidget("Large", package: .large)
        
        widgetGrid.addArrangedSubview(smallWidget)
        widgetGrid.addArrangedSubview(mediumWidget)
        widgetGrid.addArrangedSubview(largeWidget)
    }
    
    // MARK: - Widget Creation
    private func createWidget(title: String, value: String, icon: String, color: UIColor) -> UIView {
        let widget = UIView()
        widget.backgroundColor = TreeShopTheme.cardBackground.withAlphaComponent(0.9)
        widget.layer.cornerRadius = 12
        widget.layer.borderWidth = 1
        widget.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        widget.layer.shadowColor = UIColor.black.cgColor
        widget.layer.shadowOpacity = 0.2
        widget.layer.shadowOffset = CGSize(width: 0, height: 2)
        widget.layer.shadowRadius = 4
        widget.translatesAutoresizingMaskIntoConstraints = false
        
        // Blur background
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        widget.addSubview(blur)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        widget.addSubview(stack)
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        stack.addArrangedSubview(iconLabel)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = color
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        valueLabel.textAlignment = .center
        stack.addArrangedSubview(valueLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = TreeShopTheme.secondaryText
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: widget.topAnchor),
            blur.leadingAnchor.constraint(equalTo: widget.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: widget.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: widget.bottomAnchor),
            
            stack.centerXAnchor.constraint(equalTo: widget.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: widget.centerYAnchor)
        ])
        
        return widget
    }
    
    private func createPackageWidget(_ title: String, package: ServicePackage) -> UIView {
        let widget = createWidget(title: title, value: package.rawValue, icon: "📦", color: package.color)
        
        // Add tap gesture for package selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(packageWidgetTapped(_:)))
        widget.addGestureRecognizer(tapGesture)
        widget.isUserInteractionEnabled = true
        widget.tag = package.hashValue
        
        return widget
    }
    
    @objc private func packageWidgetTapped(_ gesture: UITapGestureRecognizer) {
        guard let widget = gesture.view else { return }
        
        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            widget.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                widget.transform = .identity
            }
        }
        
        // Package selection logic
        let packages = [ServicePackage.small, .medium, .large, .xLarge, .max]
        if let selectedPackage = packages.first(where: { $0.hashValue == widget.tag }) {
            NotificationCenter.default.post(name: .packageSelected, object: selectedPackage)
        }
    }
    
    private func updateHeader() {
        headerContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .center
        headerStack.spacing = 16
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerStack)
        
        // Context title
        let titleLabel = UILabel()
        titleLabel.textColor = TreeShopTheme.primaryText
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        switch currentState {
        case .defaultView:
            titleLabel.text = "TreeShop Scoreboard"
        case .areaDrawing:
            titleLabel.text = "Area Drawing Details"
        case .treeSelected(let tree):
            titleLabel.text = "Tree #\(tree.id.uuidString.prefix(4)) Details"
        case .measurement:
            titleLabel.text = "Measurement Data"
        case .packageSelection:
            titleLabel.text = "Select Package"
        }
        
        headerStack.addArrangedSubview(titleLabel)
        
        let spacer = UIView()
        headerStack.addArrangedSubview(spacer)
        
        // Back button (if history exists)
        if !stateHistory.isEmpty {
            let backButton = UIButton(type: .system)
            backButton.setTitle("← Back", for: .normal)
            backButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
            backButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            headerStack.addArrangedSubview(backButton)
        }
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8)
        ])
    }
    
    private func updateActionBar() {
        actionBar.subviews.forEach { $0.removeFromSuperview() }
        
        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 12
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionBar.addSubview(actionStack)
        
        // Context-specific actions
        switch currentState {
        case .defaultView:
            actionStack.addArrangedSubview(createActionButton("Area", action: #selector(startAreaDrawing)))
            actionStack.addArrangedSubview(createActionButton("Tree", action: #selector(startTreeAssessment)))
            actionStack.addArrangedSubview(createActionButton("Measure", action: #selector(startMeasurement)))
            actionStack.addArrangedSubview(createActionButton("More", action: #selector(showMoreMenu)))
            
        case .areaDrawing:
            actionStack.addArrangedSubview(createActionButton("Save", action: #selector(saveDrawing)))
            actionStack.addArrangedSubview(createActionButton("Package", action: #selector(selectPackage)))
            actionStack.addArrangedSubview(createActionButton("Export", action: #selector(exportDrawing)))
            actionStack.addArrangedSubview(createActionButton("Clear", action: #selector(clearDrawing)))
            
        case .treeSelected:
            actionStack.addArrangedSubview(createActionButton("Assess", action: #selector(assessTree)))
            actionStack.addArrangedSubview(createActionButton("Photo", action: #selector(photoTree)))
            actionStack.addArrangedSubview(createActionButton("Export", action: #selector(exportTree)))
            actionStack.addArrangedSubview(createActionButton("Remove", action: #selector(removeTree)))
            
        case .measurement:
            actionStack.addArrangedSubview(createActionButton("Save", action: #selector(saveMeasurement)))
            actionStack.addArrangedSubview(createActionButton("Units", action: #selector(toggleUnits)))
            actionStack.addArrangedSubview(createActionButton("Export", action: #selector(exportMeasurement)))
            actionStack.addArrangedSubview(createActionButton("Clear", action: #selector(clearMeasurement)))
            
        case .packageSelection:
            actionStack.addArrangedSubview(createActionButton("Confirm", action: #selector(confirmPackage)))
            actionStack.addArrangedSubview(createActionButton("Cancel", action: #selector(cancelPackage)))
        }
        
        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: actionBar.topAnchor, constant: 8),
            actionStack.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor, constant: 12),
            actionStack.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor, constant: -12),
            actionStack.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor, constant: -8)
        ])
    }
    
    private func createActionButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.1)
        button.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = TreeShopTheme.primaryGreen.withAlphaComponent(0.3).cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    @objc private func goBack() {
        guard let previousState = stateHistory.popLast() else { return }
        currentState = previousState
        updateUI()
    }
}

// MARK: - Action Methods (Placeholders)
extension DynamicScoreboardViewController {
    @objc private func startAreaDrawing() { NotificationCenter.default.post(name: .startAreaDrawing, object: nil) }
    @objc private func startTreeAssessment() { NotificationCenter.default.post(name: .startTreeAssessment, object: nil) }
    @objc private func startMeasurement() { NotificationCenter.default.post(name: .startMeasurement, object: nil) }
    @objc private func showMoreMenu() { NotificationCenter.default.post(name: .showMoreMenu, object: nil) }
    @objc private func saveDrawing() { NotificationCenter.default.post(name: .saveDrawing, object: nil) }
    @objc private func selectPackage() { transitionToState(.packageSelection) }
    @objc private func exportDrawing() { NotificationCenter.default.post(name: .exportDrawing, object: nil) }
    @objc private func clearDrawing() { NotificationCenter.default.post(name: .clearDrawing, object: nil) }
    @objc private func assessTree() { NotificationCenter.default.post(name: .assessTree, object: nil) }
    @objc private func photoTree() { NotificationCenter.default.post(name: .photoTree, object: nil) }
    @objc private func exportTree() { NotificationCenter.default.post(name: .exportTree, object: nil) }
    @objc private func removeTree() { NotificationCenter.default.post(name: .removeTree, object: nil) }
    @objc private func saveMeasurement() { NotificationCenter.default.post(name: .saveMeasurement, object: nil) }
    @objc private func toggleUnits() { NotificationCenter.default.post(name: .toggleUnits, object: nil) }
    @objc private func exportMeasurement() { NotificationCenter.default.post(name: .exportMeasurement, object: nil) }
    @objc private func clearMeasurement() { NotificationCenter.default.post(name: .clearMeasurement, object: nil) }
    @objc private func confirmPackage() { NotificationCenter.default.post(name: .confirmPackage, object: nil) }
    @objc private func cancelPackage() { goBack() }
}

// MARK: - Notification Names
extension Notification.Name {
    static let packageSelected = Notification.Name("packageSelected")
    static let startAreaDrawing = Notification.Name("startAreaDrawing")
    static let startTreeAssessment = Notification.Name("startTreeAssessment")
    static let startMeasurement = Notification.Name("startMeasurement")
    static let showMoreMenu = Notification.Name("showMoreMenu")
    static let saveDrawing = Notification.Name("saveDrawing")
    static let exportDrawing = Notification.Name("exportDrawing")
    static let clearDrawing = Notification.Name("clearDrawing")
    static let assessTree = Notification.Name("assessTree")
    static let photoTree = Notification.Name("photoTree")
    static let exportTree = Notification.Name("exportTree")
    static let removeTree = Notification.Name("removeTree")
    static let saveMeasurement = Notification.Name("saveMeasurement")
    static let toggleUnits = Notification.Name("toggleUnits")
    static let exportMeasurement = Notification.Name("exportMeasurement")
    static let clearMeasurement = Notification.Name("clearMeasurement")
    static let confirmPackage = Notification.Name("confirmPackage")
}

// MARK: - Data Provider Protocol
protocol ScoreboardDataProvider: AnyObject {
    func getCurrentAreaData() -> AreaDrawingData?
    func getCurrentTreeData() -> TreeInventoryItem?
    func getCurrentMeasurementData() -> MeasurementData?
    func getTreeInventoryCount() -> Int
    func getTotalTreeScore() -> Double
}