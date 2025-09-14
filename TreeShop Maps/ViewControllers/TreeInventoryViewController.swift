import UIKit
import MapKit
import CoreData

/// Tree Inventory CRUD Interface
class TreeInventoryViewController: UITableViewController {
    
    weak var mapViewController: MainMapViewController?
    private var trees: [TreeInventoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTreeInventoryUI()
        loadTrees()
    }
    
    private func setupTreeInventoryUI() {
        title = "Tree Inventory"
        view.backgroundColor = TreeShopTheme.backgroundColor
        tableView.backgroundColor = TreeShopTheme.backgroundColor
        tableView.separatorColor = TreeShopTheme.buttonBackground
        
        // Navigation buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissInventory)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Export All",
            style: .plain,
            target: self,
            action: #selector(exportAllTrees)
        )
        
        // Register cell
        tableView.register(TreeInventoryCell.self, forCellReuseIdentifier: "TreeCell")
    }
    
    private func loadTrees() {
        trees = TreeInventoryManager.shared.getTrees()
        tableView.reloadData()
        
        // Update title with count
        title = "Tree Inventory (\(trees.count))"
    }
    
    @objc private func dismissInventory() {
        dismiss(animated: true)
    }
    
    @objc private func exportAllTrees() {
        // Export functionality
        let alert = UIAlertController(title: "Export Trees", message: "Export \(trees.count) trees to CSV or PDF", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { _ in
            // Implement CSV export
            print("📤 Exporting trees to CSV")
        })
        
        alert.addAction(UIAlertAction(title: "PDF Report", style: .default) { _ in
            // Implement PDF export
            print("📄 Generating PDF report")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trees.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TreeCell", for: indexPath) as! TreeInventoryCell
        cell.configure(with: trees[indexPath.row], index: indexPath.row + 1)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tree = trees[indexPath.row]
        
        // Show action sheet for tree
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "📍 Zoom to Tree", style: .default) { [weak self] _ in
            self?.zoomToTree(tree)
        })
        
        alert.addAction(UIAlertAction(title: "✏️ Edit Tree", style: .default) { [weak self] _ in
            self?.editTree(tree)
        })
        
        alert.addAction(UIAlertAction(title: "🗑 Delete Tree", style: .destructive) { [weak self] _ in
            self?.deleteTree(tree, at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "📤 Export Tree", style: .default) { [weak self] _ in
            self?.exportTree(tree)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Tree Actions
    private func zoomToTree(_ tree: TreeInventoryItem) {
        dismiss(animated: true) {
            // Zoom to tree location on map
            let region = MKCoordinateRegion(
                center: tree.coordinate,
                latitudinalMeters: 100,
                longitudinalMeters: 100
            )
            self.mapViewController?.mapView.setRegion(region, animated: true)
            
            // Highlight the tree annotation
            if let annotation = self.mapViewController?.mapView.annotations.first(where: { annotation in
                if let treeAnnotation = annotation as? TreeScoreAnnotation {
                    return treeAnnotation.coordinate.latitude == tree.coordinate.latitude &&
                           treeAnnotation.coordinate.longitude == tree.coordinate.longitude
                }
                return false
            }) {
                self.mapViewController?.mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
    private func editTree(_ tree: TreeInventoryItem) {
        // Reopen tree assessment workflow for editing
        dismiss(animated: true) {
            // Trigger tree assessment at this location
            self.mapViewController?.presentSimpleTreeScoreInput(at: tree.coordinate, accuracy: tree.gpsAccuracy)
        }
    }
    
    private func deleteTree(_ tree: TreeInventoryItem, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Tree",
            message: "Are you sure you want to delete this tree from inventory?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // Delete from database
            TreeInventoryManager.shared.deleteTree(by: tree.id)
            
            // Remove from map
            if let annotation = self?.mapViewController?.mapView.annotations.first(where: { annotation in
                if let treeAnnotation = annotation as? TreeScoreAnnotation {
                    return treeAnnotation.coordinate.latitude == tree.coordinate.latitude &&
                           treeAnnotation.coordinate.longitude == tree.coordinate.longitude
                }
                return false
            }) {
                self?.mapViewController?.mapView.removeAnnotation(annotation)
            }
            
            // Update UI
            self?.loadTrees()
            self?.mapViewController?.updateAreaLabelWithTreeScoreInfo()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func exportTree(_ tree: TreeInventoryItem) {
        // Export single tree data
        let treeData = """
        Tree Assessment Report
        ======================
        Species: \(tree.species ?? "Unknown")
        Height: \(String(format: "%.1f", tree.height)) ft
        Canopy Radius: \(String(format: "%.1f", tree.canopyRadius)) ft  
        DBH: \(String(format: "%.1f", tree.dbh)) inches
        TreeScore: \(String(format: "%.0f", tree.treeScore.finalTreeScore))
        AFISS: \(String(format: "%.0f", tree.afissPercentage))%
        Location: \(String(format: "%.6f, %.6f", tree.coordinate.latitude, tree.coordinate.longitude))
        Date: \(tree.dateCreated)
        """
        
        let activityVC = UIActivityViewController(activityItems: [treeData], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
    }
}

// MARK: - Tree Inventory Cell
class TreeInventoryCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let treeScoreLabel = UILabel()
    private let locationLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = TreeShopTheme.cardBackground
        selectionStyle = .none
        
        // Tree icon/number
        let iconLabel = UILabel()
        iconLabel.text = "🌳"
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconLabel)
        
        // Tree details
        let detailStack = UIStackView()
        detailStack.axis = .vertical
        detailStack.spacing = 2
        detailStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailStack)
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = TreeShopTheme.primaryText
        detailStack.addArrangedSubview(titleLabel)
        
        detailsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        detailsLabel.textColor = TreeShopTheme.secondaryText
        detailStack.addArrangedSubview(detailsLabel)
        
        locationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        locationLabel.textColor = TreeShopTheme.tertiaryText
        detailStack.addArrangedSubview(locationLabel)
        
        // TreeScore
        treeScoreLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        treeScoreLabel.textColor = TreeShopTheme.primaryGreen
        treeScoreLabel.textAlignment = .right
        treeScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(treeScoreLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            detailStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            detailStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailStack.trailingAnchor.constraint(equalTo: treeScoreLabel.leadingAnchor, constant: -12),
            
            treeScoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            treeScoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with tree: TreeInventoryItem, index: Int) {
        titleLabel.text = "Tree #\(index) - \(tree.species ?? "Unknown")"
        detailsLabel.text = String(format: "%.1fft tall, %.1fft canopy, %.1fin DBH", 
                                  tree.height, tree.canopyRadius, tree.dbh)
        locationLabel.text = String(format: "GPS: %.6f, %.6f", 
                                   tree.coordinate.latitude, tree.coordinate.longitude)
        
        let complexity = tree.treeScore.finalTreeScore < 500 ? "Low" : 
                        tree.treeScore.finalTreeScore < 1500 ? "Med" : "High"
        treeScoreLabel.text = String(format: "%.0f\n%@", tree.treeScore.finalTreeScore, complexity)
    }
}