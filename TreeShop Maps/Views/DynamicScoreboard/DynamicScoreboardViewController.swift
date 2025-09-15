import UIKit
import MapKit
import CoreLocation

// MARK: - Dynamic Scoreboard View Controller

class DynamicScoreboardViewController: UIViewController {
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let headerView = DynamicHeaderView()
    private let widgetCollectionView: UICollectionView
    private let actionBarView = ActionBarView()
    
    // MARK: - Properties
    private let scoreboardManager = DynamicScoreboardManager()
    private var currentWidgets: [WidgetData] = []
    private var currentActions: [ScoreboardAction] = []
    
    // Data providers
    weak var mapViewController: MainMapViewController?
    private lazy var dataProvider = TreeShopScoreboardDataProvider(mapViewController: mapViewController)
    
    // Layout constraints for animations
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init() {
        // Setup collection view layout
        let layout = WidgetCollectionLayout()
        self.widgetCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
        
        setupUI()
        setupCollectionView()
        setupDataProvider()
        setupStateObservation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Container view with blur background
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        view.addSubview(containerView)
        
        // Add blur background to container
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurView.layer.masksToBounds = true
        containerView.insertSubview(blurView, at: 0)
        
        // Setup main stack view
        let mainStackView = UIStackView()
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        mainStackView.spacing = 0
        mainStackView.distribution = .fill
        containerView.addSubview(mainStackView)
        
        // Add header view
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self
        mainStackView.addArrangedSubview(headerView)
        
        // Add collection view
        widgetCollectionView.translatesAutoresizingMaskIntoConstraints = false
        widgetCollectionView.backgroundColor = .clear
        widgetCollectionView.showsVerticalScrollIndicator = false
        widgetCollectionView.alwaysBounceVertical = false
        mainStackView.addArrangedSubview(widgetCollectionView)
        
        // Add action bar
        actionBarView.translatesAutoresizingMaskIntoConstraints = false
        actionBarView.delegate = self
        mainStackView.addArrangedSubview(actionBarView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container positioning (25% of screen height)
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Blur view fills container
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Main stack view with padding
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            
            // Header height
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Action bar height
            actionBarView.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        // Set container height constraint (25% of screen)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25)
        containerHeightConstraint.isActive = true
        
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint.isActive = true
    }
    
    private func setupCollectionView() {
        widgetCollectionView.delegate = self
        widgetCollectionView.dataSource = self
        
        // Register cell
        widgetCollectionView.register(WidgetCollectionViewCell.self, forCellWithReuseIdentifier: "WidgetCell")
        
        // Configure layout
        if let layout = widgetCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    private func setupDataProvider() {
        scoreboardManager.dataProvider = dataProvider
    }
    
    private func setupStateObservation() {
        // Observe state changes
        scoreboardManager.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handleStateChange(to: newState)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Management
    
    private func loadInitialState() {
        scoreboardManager.transition(to: .defaultView)
    }
    
    private func handleStateChange(to newState: ScoreboardState) {
        updateHeader()
        refreshWidgets()
        updateActionBar()
        animateLayoutChange()
    }
    
    private func updateHeader() {
        let headerInfo = scoreboardManager.getCurrentHeaderInfo()
        headerView.configure(
            title: headerInfo.title,
            subtitle: headerInfo.subtitle,
            primaryColor: scoreboardManager.primaryColor,
            progress: headerInfo.progress,
            canGoBack: scoreboardManager.canGoBack
        )
    }
    
    private func refreshWidgets() {
        let newWidgets = scoreboardManager.getCurrentWidgets()
        
        // Animate widget changes
        UIView.animate(withDuration: 0.3, animations: {
            self.widgetCollectionView.alpha = 0.7
        }) { _ in
            self.currentWidgets = newWidgets
            self.widgetCollectionView.reloadData()
            
            UIView.animate(withDuration: 0.3) {
                self.widgetCollectionView.alpha = 1.0
            }
        }
    }
    
    private func updateActionBar() {
        currentActions = scoreboardManager.getCurrentActions()
        actionBarView.configure(with: currentActions)
    }
    
    private func animateLayoutChange() {
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Public Interface
    
    func transitionToState(_ state: ScoreboardState) {
        scoreboardManager.transition(to: state)
    }
    
    func updateData() {
        refreshData()
    }
    
    func refreshData() {
        // Trigger data refresh in data provider
        dataProvider.refreshData()
        
        // Update widgets with new data
        refreshWidgets()
    }
    
    // MARK: - Animation Support
    
    func expandToFullHeight() {
        containerHeightConstraint.isActive = false
        let fullHeightConstraint = containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        fullHeightConstraint.isActive = true
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
    
    func collapseToDefaultHeight() {
        view.constraints.forEach { constraint in
            if constraint.firstItem === containerView && constraint.firstAttribute == .height {
                constraint.isActive = false
            }
        }
        
        containerHeightConstraint.isActive = true
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Collection View Delegate & Data Source

extension DynamicScoreboardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentWidgets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WidgetCell", for: indexPath) as! WidgetCollectionViewCell
        let widget = currentWidgets[indexPath.item]
        cell.configure(with: widget)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Dynamic sizing based on content and screen size
        let availableWidth = collectionView.bounds.width - 32 // Account for margins
        let itemsPerRow: CGFloat = availableWidth > 400 ? 3 : 2
        let spacing: CGFloat = 12
        let totalSpacing = (itemsPerRow - 1) * spacing
        let itemWidth = (availableWidth - totalSpacing) / itemsPerRow
        
        return CGSize(width: itemWidth, height: 100)
    }
}

// MARK: - Header View Delegate

extension DynamicScoreboardViewController: DynamicHeaderViewDelegate {
    func didTapBackButton() {
        _ = scoreboardManager.goBack()
    }
    
    func didTapOptionsButton() {
        // Show additional options
    }
}

// MARK: - Action Bar Delegate

extension DynamicScoreboardViewController: ActionBarViewDelegate {
    func didTapAction(_ action: ScoreboardAction) {
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Execute action
        action.action()
    }
}

// MARK: - Widget Collection View Cell

class WidgetCollectionViewCell: UICollectionViewCell {
    private let widgetCardView = WidgetCardView(style: .secondary)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(widgetCardView)
        widgetCardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            widgetCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            widgetCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            widgetCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            widgetCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with data: WidgetData) {
        widgetCardView.configure(with: data)
    }
}

// MARK: - Combine Import
import Combine