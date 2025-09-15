import UIKit
import MapKit

// MARK: - MainMapViewController Dynamic Scoreboard Extension

extension MainMapViewController {
    
    // MARK: - Scoreboard Setup
    
    func setupDynamicScoreboard() {
        // Remove old bottom tools view if it exists
        if let oldBottomView = view.subviews.first(where: { $0 === bottomToolsView }) {
            oldBottomView.removeFromSuperview()
        }
        
        // Create and setup dynamic scoreboard
        let scoreboardVC = DynamicScoreboardViewController()
        scoreboardVC.mapViewController = self
        
        // Add as child view controller
        addChild(scoreboardVC)
        view.addSubview(scoreboardVC.view)
        scoreboardVC.didMove(toParent: self)
        
        // Store reference
        self.dynamicScoreboardVC = scoreboardVC
        
        // Setup constraints
        scoreboardVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreboardVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scoreboardVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scoreboardVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scoreboardVC.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25)
        ])
        
        // Bring to front
        view.bringSubviewToFront(scoreboardVC.view)
        
        // Setup gesture recognizers for scoreboard interactions
        setupScoreboardGestures()
    }
    
    private func setupScoreboardGestures() {
        // Add edge pan gesture for expanding/collapsing scoreboard
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleScoreboardEdgePan(_:)))
        edgePan.edges = .bottom
        edgePan.delegate = self
        view.addGestureRecognizer(edgePan)
    }
    
    // MARK: - Scoreboard State Management
    
    func updateScoreboardForDrawingMode() {
        dynamicScoreboardVC?.transitionToState(.areaDrawing)
        
        // Update data with current drawing state
        refreshScoreboardData()
        
        // Optionally expand scoreboard for better visibility
        if isDrawingComplexArea() {
            dynamicScoreboardVC?.expandToFullHeight()
        }
    }
    
    func updateScoreboardForTreeInventory() {
        dynamicScoreboardVC?.transitionToState(.treeInventory)
        refreshScoreboardData()
    }
    
    func updateScoreboardForMeasurement() {
        dynamicScoreboardVC?.transitionToState(.measurement)
        refreshScoreboardData()
    }
    
    func updateScoreboardForPackageSelection() {
        dynamicScoreboardVC?.transitionToState(.packageSelection)
        refreshScoreboardData()
    }
    
    func resetScoreboardToDefault() {
        dynamicScoreboardVC?.transitionToState(.defaultView)
        dynamicScoreboardVC?.collapseToDefaultHeight()
        refreshScoreboardData()
    }
    
    // MARK: - Data Updates
    
    func refreshScoreboardData() {
        dynamicScoreboardVC?.refreshData()
    }
    
    // MARK: - Mode-Specific Updates
    
    override func toggleDrawingMode() {
        super.toggleDrawingMode()
        
        if currentMode == .drawing {
            updateScoreboardForDrawingMode()
        } else {
            resetScoreboardToDefault()
        }
    }
    
    override func toggleTreeInventoryMode() {
        super.toggleTreeInventoryMode()
        
        if treeInventoryMode {
            updateScoreboardForTreeInventory()
        } else {
            resetScoreboardToDefault()
        }
    }
    
    override func toggleMeasuringMode() {
        super.toggleMeasuringMode()
        
        if currentMode == .measuring {
            updateScoreboardForMeasurement()
        } else {
            resetScoreboardToDefault()
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleScoreboardEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            // Store initial state
            break
            
        case .changed:
            // Handle drag to expand/collapse
            if translation.y < -50 { // Dragging up
                dynamicScoreboardVC?.expandToFullHeight()
            }
            
        case .ended, .cancelled:
            // Determine final state based on velocity and position
            if velocity.y < -500 || translation.y < -100 {
                dynamicScoreboardVC?.expandToFullHeight()
            } else {
                dynamicScoreboardVC?.collapseToDefaultHeight()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Scoreboard Integration with Existing Features
    
    func updateScoreboardWithAreaData(_ area: Double, perimeter: Double, pointCount: Int) {
        // Update area measurement data
        NotificationCenter.default.post(
            name: .drawingManagerDidUpdateArea,
            object: nil,
            userInfo: [
                "area": area,
                "perimeter": perimeter,
                "pointCount": pointCount
            ]
        )
    }
    
    func updateScoreboardWithTreeData() {
        // Trigger tree inventory update
        NotificationCenter.default.post(name: .treeInventoryDidUpdate, object: nil)
    }
    
    func updateScoreboardWithLocationData(_ location: CLLocation) {
        // Update GPS data
        NotificationCenter.default.post(
            name: .locationManagerDidUpdateLocation,
            object: nil,
            userInfo: ["location": location]
        )
    }
    
    // MARK: - Workflow Integration
    
    func showPackageSelectionInScoreboard() {
        updateScoreboardForPackageSelection()
        dynamicScoreboardVC?.expandToFullHeight()
    }
    
    func completeAreaDrawingWithScoreboard() {
        // Handle area completion
        let alertController = UIAlertController(
            title: "Area Complete",
            message: "Would you like to select a service package for this area?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Select Package", style: .default) { [weak self] _ in
            self?.showPackageSelectionInScoreboard()
        })
        
        alertController.addAction(UIAlertAction(title: "Save & Continue", style: .default) { [weak self] _ in
            self?.resetScoreboardToDefault()
        })
        
        present(alertController, animated: true)
    }
    
    // MARK: - Animation Helpers
    
    private func isDrawingComplexArea() -> Bool {
        // Logic to determine if current drawing is complex enough to warrant expanded scoreboard
        return drawingMarkers.count > 6 || currentPolygon?.pointCount ?? 0 > 6
    }
    
    // MARK: - Accessibility
    
    func announceScoreboardStateChange(_ state: ScoreboardState) {
        let announcement: String
        
        switch state {
        case .defaultView:
            announcement = "Returned to main view"
        case .areaDrawing:
            announcement = "Switched to area drawing mode"
        case .treeInventory:
            announcement = "Switched to tree assessment mode"
        case .measurement:
            announcement = "Switched to measurement mode"
        case .packageSelection:
            announcement = "Showing package selection"
        }
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    // MARK: - Debug & Development
    
    #if DEBUG
    func debugScoreboardState() {
        guard let scoreboard = dynamicScoreboardVC else {
            print("❌ Dynamic scoreboard not initialized")
            return
        }
        
        print("🎯 Scoreboard Debug Info:")
        print("   Current State: \(scoreboard.scoreboardManager.currentState)")
        print("   Can Go Back: \(scoreboard.scoreboardManager.canGoBack)")
        print("   Is Transitioning: \(scoreboard.scoreboardManager.isTransitioning)")
        print("   Widget Count: \(scoreboard.currentWidgets.count)")
        print("   Action Count: \(scoreboard.currentActions.count)")
    }
    #endif
}

// MARK: - UIGestureRecognizerDelegate

extension MainMapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow scoreboard gestures to work alongside map gestures
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Prevent conflicts with scoreboard UI
        if let view = touch.view, view.isDescendant(of: dynamicScoreboardVC?.view ?? UIView()) {
            return false
        }
        return true
    }
}

// MARK: - Scoreboard Property Extension

private var dynamicScoreboardVCKey: UInt8 = 0

extension MainMapViewController {
    
    var dynamicScoreboardVC: DynamicScoreboardViewController? {
        get {
            return objc_getAssociatedObject(self, &dynamicScoreboardVCKey) as? DynamicScoreboardViewController
        }
        set {
            objc_setAssociatedObject(self, &dynamicScoreboardVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - MKPolygon Extension for Point Count

extension MKPolygon {
    var pointCount: Int {
        return coordinate.count
    }
}