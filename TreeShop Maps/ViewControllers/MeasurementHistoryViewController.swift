import UIKit
import MapKit

protocol MeasurementHistoryDelegate: AnyObject {
    func measurementHistoryDidSelectMeasurement(_ measurement: StoredMeasurement)
    func measurementHistoryDidDeleteMeasurement(_ measurement: StoredMeasurement)
}

class MeasurementHistoryViewController: UIViewController {
    
    weak var delegate: MeasurementHistoryDelegate?
    
    private var tableView: UITableView!
    private var measurements: [StoredMeasurement] = []
    private var filteredMeasurements: [StoredMeasurement] = []
    private var searchBar: UISearchBar!
    private var segmentedControl: UISegmentedControl!
    private var selectedFilter: MeasurementType? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMeasurements()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMeasurements()
    }
    
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        title = "Measurement History"
        
        TreeShopTheme.applyNavigationBarTheme(to: navigationController)
        
        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissViewController)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportMeasurements)
        )
        
        setupFilterControls()
        setupTableView()
    }
    
    private func setupFilterControls() {
        // Search bar
        searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Search measurements..."
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = TreeShopTheme.cardBackground
        searchBar.backgroundColor = UIColor.clear
        searchBar.tintColor = TreeShopTheme.primaryGreen
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = TreeShopTheme.buttonBackground
            textField.textColor = TreeShopTheme.primaryText
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search measurements...",
                attributes: [.foregroundColor: TreeShopTheme.secondaryText]
            )
            textField.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        }
        
        view.addSubview(searchBar)
        
        // Segmented control for filtering
        let items = ["All"] + MeasurementType.allCases.map { $0.rawValue }
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = TreeShopTheme.primaryGreen
            segmentedControl.backgroundColor = TreeShopTheme.buttonBackground
            segmentedControl.setTitleTextAttributes([.foregroundColor: TreeShopTheme.secondaryText], for: .normal)
            segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        }
        
        view.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 56),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = TreeShopTheme.backgroundColor
        tableView.separatorColor = TreeShopTheme.secondaryBackground
        tableView.register(MeasurementHistoryCell.self, forCellReuseIdentifier: "MeasurementHistoryCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadMeasurements() {
        measurements = MeasurementHistoryManager.shared.getMeasurements()
        filterMeasurements()
    }
    
    private func filterMeasurements() {
        var filtered = measurements
        
        // Apply type filter
        if let selectedFilter = selectedFilter {
            filtered = filtered.filter { $0.type == selectedFilter }
        }
        
        // Apply search filter
        if let searchText = searchBar.text, !searchText.isEmpty {
            filtered = filtered.filter { measurement in
                measurement.name.localizedCaseInsensitiveContains(searchText) ||
                measurement.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        filteredMeasurements = filtered
        tableView.reloadData()
    }
    
    @objc private func filterChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            selectedFilter = nil
        case 1:
            selectedFilter = .distance
        case 2:
            selectedFilter = .area
        default:
            selectedFilter = nil
        }
        filterMeasurements()
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    @objc private func exportMeasurements() {
        let alert = UIAlertController(title: "Export Measurements", message: "Choose export format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "PDF Report", style: .default) { [weak self] _ in
            self?.exportAsPDF()
        })
        
        alert.addAction(UIAlertAction(title: "KML for Google Earth", style: .default) { [weak self] _ in
            self?.exportAsKML()
        })
        
        alert.addAction(UIAlertAction(title: "CSV Spreadsheet", style: .default) { [weak self] _ in
            self?.exportAsCSV()
        })
        
        alert.addAction(UIAlertAction(title: "All Formats", style: .default) { [weak self] _ in
            self?.exportAllFormats()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func exportAsPDF() {
        guard let pdfURL = ProfessionalExportManager.shared.generateMeasurementPDFReport(measurements: measurements) else {
            showAlert(title: "Export Error", message: "Failed to generate PDF report.")
            return
        }
        
        ProfessionalExportManager.shared.shareFiles([pdfURL], from: self)
    }
    
    private func exportAsKML() {
        guard let kmlURL = ProfessionalExportManager.shared.exportMeasurementsToKML(measurements: measurements) else {
            showAlert(title: "Export Error", message: "Failed to generate KML file.")
            return
        }
        
        ProfessionalExportManager.shared.shareFiles([kmlURL], from: self)
    }
    
    private func exportAsCSV() {
        guard let csvURL = ProfessionalExportManager.shared.exportMeasurementsToCSV(measurements: measurements) else {
            showAlert(title: "Export Error", message: "Failed to generate CSV file.")
            return
        }
        
        ProfessionalExportManager.shared.shareFiles([csvURL], from: self)
    }
    
    private func exportAllFormats() {
        var urls: [URL] = []
        
        if let pdfURL = ProfessionalExportManager.shared.generateMeasurementPDFReport(measurements: measurements) {
            urls.append(pdfURL)
        }
        
        if let kmlURL = ProfessionalExportManager.shared.exportMeasurementsToKML(measurements: measurements) {
            urls.append(kmlURL)
        }
        
        if let csvURL = ProfessionalExportManager.shared.exportMeasurementsToCSV(measurements: measurements) {
            urls.append(csvURL)
        }
        
        guard !urls.isEmpty else {
            showAlert(title: "Export Error", message: "Failed to generate export files.")
            return
        }
        
        ProfessionalExportManager.shared.shareFiles(urls, from: self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showMeasurementOptions(for measurement: StoredMeasurement, at indexPath: IndexPath) {
        let alert = UIAlertController(title: measurement.name, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Load on Map", style: .default) { [weak self] _ in
            self?.delegate?.measurementHistoryDidSelectMeasurement(measurement)
            self?.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            self?.showRenameMeasurementAlert(for: measurement)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: measurement, at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            let cell = tableView.cellForRow(at: indexPath)
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? CGRect.zero
        }
        
        present(alert, animated: true)
    }
    
    private func showRenameMeasurementAlert(for measurement: StoredMeasurement) {
        let alert = UIAlertController(title: "Rename Measurement", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = measurement.name
            textField.placeholder = "Measurement name"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            // Create new measurement with updated name
            let updatedMeasurement = StoredMeasurement(
                id: measurement.id,
                name: newName,
                type: measurement.type,
                coordinates: measurement.coordinates,
                value: measurement.value,
                perimeter: measurement.perimeter,
                notes: measurement.notes,
                accuracy: measurement.accuracy
            )
            
            MeasurementHistoryManager.shared.updateMeasurement(updatedMeasurement)
            self?.loadMeasurements()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showDeleteConfirmation(for measurement: StoredMeasurement, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Measurement",
            message: "Are you sure you want to delete '\(measurement.name)'? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            MeasurementHistoryManager.shared.deleteMeasurement(by: measurement.id)
            self?.delegate?.measurementHistoryDidDeleteMeasurement(measurement)
            self?.loadMeasurements()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension MeasurementHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMeasurements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeasurementHistoryCell", for: indexPath) as! MeasurementHistoryCell
        let measurement = filteredMeasurements[indexPath.row]
        cell.configure(with: measurement)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MeasurementHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let measurement = filteredMeasurements[indexPath.row]
        showMeasurementOptions(for: measurement, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UISearchBarDelegate
extension MeasurementHistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMeasurements()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Custom Table View Cell
class MeasurementHistoryCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let typeIcon = UIImageView()
    private let valueLabel = UILabel()
    private let dateLabel = UILabel()
    private let notesLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = TreeShopTheme.backgroundColor
        selectionStyle = .none
        
        // Configure labels
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = TreeShopTheme.primaryText
        
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = TreeShopTheme.primaryGreen
        
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = TreeShopTheme.secondaryText
        
        notesLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        notesLabel.textColor = TreeShopTheme.tertiaryText
        notesLabel.numberOfLines = 2
        
        typeIcon.contentMode = .scaleAspectFit
        typeIcon.tintColor = TreeShopTheme.primaryGreen
        
        // Add subviews
        [nameLabel, typeIcon, valueLabel, dateLabel, notesLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Layout
        NSLayoutConstraint.activate([
            typeIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            typeIcon.widthAnchor.constraint(equalToConstant: 24),
            typeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
            
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            notesLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            notesLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 12),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            notesLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with measurement: StoredMeasurement) {
        nameLabel.text = measurement.name
        typeIcon.image = UIImage(systemName: measurement.type.systemImageName)
        
        let settings = MeasurementSettings.shared
        valueLabel.text = measurement.getFormattedValue(
            distanceUnit: settings.distanceUnit,
            areaUnit: settings.areaUnit
        )
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: measurement.dateCreated)
        
        if let notes = measurement.notes, !notes.isEmpty {
            notesLabel.text = notes
            notesLabel.isHidden = false
        } else {
            notesLabel.isHidden = true
        }
    }
}