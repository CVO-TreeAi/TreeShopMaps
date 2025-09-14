import UIKit
import CoreLocation

/// Coordinator for the new 3-screen TreeScore workflow
class TreeScoreWorkflowViewController: UINavigationController {
    
    // MARK: - Properties
    weak var treeScoreDelegate: TreeScoreInputDelegate?
    var currentLocation: CLLocationCoordinate2D?
    var locationAccuracy: CLLocationAccuracy?
    var prefilledServicePackage: ServicePackage?
    
    // Data flow between screens
    private var treeData: (height: Double, canopyRadius: Double, dbh: Double, species: String?)?
    private var assessmentData: (afissPercentage: Double, healthStatus: String, servicePackage: ServicePackage, notes: String?)?
    
    // View controllers
    private var step1ViewController: TreeScoreStep1ViewController!
    private var step2ViewController: TreeScoreStep2ViewController!
    private var step3ViewController: TreeScoreStep3ViewController!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWorkflow()
        setupNavigationBar()
    }
    
    private func setupWorkflow() {
        // Create Step 1 (Measurements & Species)
        step1ViewController = TreeScoreStep1ViewController()
        step1ViewController.delegate = self
        step1ViewController.setLocation(currentLocation ?? CLLocationCoordinate2D(), accuracy: locationAccuracy ?? 0)
        
        // Start with Step 1
        viewControllers = [step1ViewController]
    }
    
    private func setupNavigationBar() {
        navigationBar.prefersLargeTitles = false
        navigationBar.tintColor = TreeShopTheme.primaryGreen
        
        // Custom appearance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = TreeShopTheme.backgroundColor
            appearance.titleTextAttributes = [
                .foregroundColor: TreeShopTheme.primaryText,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - Public Methods
    func setLocation(_ coordinate: CLLocationCoordinate2D, accuracy: CLLocationAccuracy) {
        currentLocation = coordinate
        locationAccuracy = accuracy
        step1ViewController?.setLocation(coordinate, accuracy: accuracy)
    }
    
    func setPrefilledServicePackage(_ package: ServicePackage) {
        prefilledServicePackage = package
    }
    
    // MARK: - Navigation Methods
    private func navigateToStep2() {
        step2ViewController = TreeScoreStep2ViewController()
        step2ViewController.delegate = self
        step2ViewController.setTreeData(treeData!)
        step2ViewController.setLocation(currentLocation ?? CLLocationCoordinate2D(), accuracy: locationAccuracy ?? 0)
        
        if let package = prefilledServicePackage {
            step2ViewController.setPrefilledServicePackage(package)
        }
        
        pushViewController(step2ViewController, animated: true)
    }
    
    private func navigateToStep3() {
        step3ViewController = TreeScoreStep3ViewController()
        step3ViewController.delegate = self
        step3ViewController.setTreeData(treeData!)
        step3ViewController.setAssessmentData(assessmentData!)
        step3ViewController.setLocation(currentLocation ?? CLLocationCoordinate2D(), accuracy: locationAccuracy ?? 0)
        
        pushViewController(step3ViewController, animated: true)
    }
    
    private func goBackToStep1() {
        popToViewController(step1ViewController, animated: true)
    }
    
    private func goBackToStep2() {
        if let step2 = step2ViewController {
            popToViewController(step2, animated: true)
        }
    }
}

// MARK: - TreeScoreStep1Delegate
extension TreeScoreWorkflowViewController: TreeScoreStep1Delegate {
    
    func didCompleteStep1(height: Double, canopyRadius: Double, dbh: Double, species: String?) {
        // Store data for next step
        treeData = (height: height, canopyRadius: canopyRadius, dbh: dbh, species: species)
        
        // Proceed to Step 2
        navigateToStep2()
    }
    
    func didCancelStep1() {
        treeScoreDelegate?.didCancelTreeInput()
    }
}

// MARK: - TreeScoreStep2Delegate
extension TreeScoreWorkflowViewController: TreeScoreStep2Delegate {
    
    func didCompleteStep2(afissPercentage: Double, healthStatus: String, servicePackage: ServicePackage, notes: String?) {
        // Store assessment data
        assessmentData = (afissPercentage: afissPercentage, healthStatus: healthStatus, servicePackage: servicePackage, notes: notes)
        
        // Proceed to Step 3
        navigateToStep3()
    }
    
    func didGoBackToStep1() {
        goBackToStep1()
    }
}

// MARK: - TreeScoreStep3Delegate
extension TreeScoreWorkflowViewController: TreeScoreStep3Delegate {
    
    func didAddTreeToInventory(_ item: TreeInventoryItem) {
        treeScoreDelegate?.didCreateTreeInventoryItem(item)
    }
    
    func didGoBackToStep2() {
        goBackToStep2()
    }
    
    func didCancelTreeInput() {
        treeScoreDelegate?.didCancelTreeInput()
    }
}

// MARK: - Enhanced Modal Presentation Helper
extension TreeScoreWorkflowViewController {
    
    static func presentWorkflow(
        from presentingViewController: UIViewController,
        location: CLLocationCoordinate2D,
        accuracy: CLLocationAccuracy,
        delegate: TreeScoreInputDelegate,
        prefilledPackage: ServicePackage? = nil
    ) {
        let workflowVC = TreeScoreWorkflowViewController()
        workflowVC.treeScoreDelegate = delegate
        workflowVC.setLocation(location, accuracy: accuracy)
        
        if let package = prefilledPackage {
            workflowVC.setPrefilledServicePackage(package)
        }
        
        // Configure modal presentation
        workflowVC.modalPresentationStyle = .formSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = workflowVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
            }
        }
        
        presentingViewController.present(workflowVC, animated: true)
    }
}

// MARK: - Progress Tracking
extension TreeScoreWorkflowViewController {
    
    private func updateProgressIndicator() {
        // Could add a progress indicator view at the top
        // For now, each step shows its own progress in the header
    }
    
    var currentStepNumber: Int {
        switch topViewController {
        case step1ViewController:
            return 1
        case step2ViewController:
            return 2
        case step3ViewController:
            return 3
        default:
            return 1
        }
    }
    
    var totalSteps: Int {
        return 3
    }
}

// MARK: - Animation Enhancements
extension TreeScoreWorkflowViewController {
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // Add subtle haptic feedback for navigation
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        return super.popViewController(animated: animated)
    }
}