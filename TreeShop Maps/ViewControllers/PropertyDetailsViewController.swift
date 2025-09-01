import UIKit
import CoreData

class PropertyDetailsViewController: UITableViewController {
    
    var property: Property?
    
    private enum Section: Int, CaseIterable {
        case clientInfo = 0
        case workZones
        case treeInventory
        case workSessions
        case documents
        
        var title: String {
            switch self {
            case .clientInfo: return "Client Information"
            case .workZones: return "Work Zones"
            case .treeInventory: return "Tree Inventory"
            case .workSessions: return "Work Sessions"
            case .documents: return "Documents"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "Property Details"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "SubtitleCell")
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func editButtonTapped() {
        showEditClientInfo()
    }
    
    private func showEditClientInfo() {
        let alert = UIAlertController(title: "Edit Client Information", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Client Name"
            textField.text = self.property?.clientName
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Address"
            textField.text = self.property?.address
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Phone Number"
            textField.text = self.property?.phoneNumber
            textField.keyboardType = .phonePad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Email Address"
            textField.text = self.property?.emailAddress
            textField.keyboardType = .emailAddress
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.saveClientInfo(from: alert.textFields)
        })
        
        present(alert, animated: true)
    }
    
    private func saveClientInfo(from textFields: [UITextField]?) {
        guard let textFields = textFields,
              textFields.count == 4,
              let property = property,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        property.clientName = textFields[0].text
        property.address = textFields[1].text
        property.phoneNumber = textFields[2].text
        property.emailAddress = textFields[3].text
        property.lastModified = Date()
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            try context.save()
            tableView.reloadSections(IndexSet(integer: Section.clientInfo.rawValue), with: .automatic)
        } catch {
            showAlert(title: "Error", message: "Failed to save client information")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section),
              let property = property else { return 0 }
        
        switch section {
        case .clientInfo:
            return 4
        case .workZones:
            return (property.workZones?.count ?? 0) + 1
        case .treeInventory:
            return min(5, (property.treeMarks?.count ?? 0)) + 1
        case .workSessions:
            return (property.sessions?.count ?? 0) + 1
        case .documents:
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section),
              let property = property else {
            return UITableViewCell()
        }
        
        switch section {
        case .clientInfo:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Name: \(property.clientName ?? "Not set")"
            case 1:
                cell.textLabel?.text = "Address: \(property.address ?? "Not set")"
            case 2:
                cell.textLabel?.text = "Phone: \(property.phoneNumber ?? "Not set")"
            case 3:
                cell.textLabel?.text = "Email: \(property.emailAddress ?? "Not set")"
            default:
                break
            }
            
            cell.selectionStyle = .none
            return cell
            
        case .workZones:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                
                let zones = property.workZones as? Set<WorkZone> ?? []
                let totalAcres = zones.reduce(0) { $0 + $1.acreage }
                let totalPrice = zones.reduce(0) { $0 + $1.priceEstimate }
                
                cell.textLabel?.text = String(format: "Total: %.2f acres - $%.2f", totalAcres, totalPrice)
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath)
                
                if let zones = property.workZones?.allObjects as? [WorkZone],
                   indexPath.row - 1 < zones.count {
                    let zone = zones[indexPath.row - 1]
                    cell.textLabel?.text = "\(zone.servicePackage ?? "Unknown") - \(String(format: "%.2f acres", zone.acreage))"
                    cell.detailTextLabel?.text = String(format: "$%.2f - %@", zone.priceEstimate, zone.isCompleted ? "Completed" : "Pending")
                }
                
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .treeInventory:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                
                let treeCount = property.treeMarks?.count ?? 0
                cell.textLabel?.text = "Total Trees: \(treeCount)"
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                cell.accessoryType = treeCount > 5 ? .disclosureIndicator : .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath)
                
                if let trees = property.treeMarks?.allObjects as? [TreeMark],
                   indexPath.row - 1 < trees.count {
                    let tree = trees[indexPath.row - 1]
                    cell.textLabel?.text = tree.species ?? "Unknown Species"
                    cell.detailTextLabel?.text = String(format: "Height: %.0fft, DBH: %.0fin", tree.height, tree.dbh)
                }
                
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .workSessions:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                
                let sessions = property.sessions as? Set<WorkSession> ?? []
                let totalHours = sessions.reduce(0) { total, session in
                    if let start = session.startTime, let end = session.endTime {
                        return total + end.timeIntervalSince(start) / 3600
                    }
                    return total
                }
                
                cell.textLabel?.text = String(format: "Total Sessions: %d (%.1f hours)", sessions.count, totalHours)
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath)
                
                if let sessions = property.sessions?.allObjects as? [WorkSession],
                   indexPath.row - 1 < sessions.count {
                    let session = sessions[indexPath.row - 1]
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    
                    if let startTime = session.startTime {
                        cell.textLabel?.text = dateFormatter.string(from: startTime)
                    }
                    
                    cell.detailTextLabel?.text = String(format: "%.2f acres - %@", session.acresCovered, session.operatorName ?? "Unknown")
                }
                
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .documents:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Export PDF Report"
            case 1:
                cell.textLabel?.text = "Export KML File"
            case 2:
                cell.textLabel?.text = "Export CSV Data"
            default:
                break
            }
            
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section),
              let _ = property else { return }
        
        switch section {
        case .documents:
            switch indexPath.row {
            case 0:
                exportPDF()
            case 1:
                exportKML()
            case 2:
                exportCSV()
            default:
                break
            }
        default:
            break
        }
    }
    
    private func exportPDF() {
        guard let property = property else { return }
        
        if let url = ExportManager.shared.generatePDFReport(for: property) {
            shareFile(url)
        }
    }
    
    private func exportKML() {
        guard let property = property else { return }
        
        if let url = ExportManager.shared.exportKML(for: property) {
            shareFile(url)
        }
    }
    
    private func exportCSV() {
        guard let property = property else { return }
        
        if let url = ExportManager.shared.exportCSV(for: property) {
            shareFile(url)
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            if let cell = tableView.cellForRow(at: tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(activityVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

class SubtitleTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}