import UIKit
import CoreData

class PropertyListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var properties: [Property] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProperties()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProperties()
    }
    
    private func setupUI() {
        title = "Projects"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add navigation buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewProject)
        )
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PropertyCell")
    }
    
    private func loadProperties() {
        let request: NSFetchRequest<Property> = Property.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            properties = try context.fetch(request)
            tableView.reloadData()
            print("📋 Loaded \\(properties.count) projects")
        } catch {
            print("❌ Error loading projects: \\(error)")
        }
    }
    
    @objc private func addNewProject() {
        let alert = UIAlertController(title: "New Project", message: "Enter project details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Project Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Client Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Address"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Phone (optional)"
            textField.keyboardType = .phonePad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Email (optional)"
            textField.keyboardType = .emailAddress
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            self.createNewProject(
                projectName: alert.textFields?[0].text ?? "",
                clientName: alert.textFields?[1].text ?? "",
                address: alert.textFields?[2].text ?? "",
                phone: alert.textFields?[3].text ?? "",
                email: alert.textFields?[4].text ?? ""
            )
        })
        
        present(alert, animated: true)
    }
    
    private func createNewProject(projectName: String, clientName: String, address: String, phone: String, email: String) {
        guard !projectName.isEmpty && !clientName.isEmpty else {
            showAlert(title: "Error", message: "Project name and client name are required")
            return
        }
        
        let newProperty = Property(context: context)
        newProperty.id = UUID()
        newProperty.projectName = projectName
        newProperty.clientName = clientName
        newProperty.address = address.isEmpty ? nil : address
        newProperty.phoneNumber = phone.isEmpty ? nil : phone
        newProperty.emailAddress = email.isEmpty ? nil : email
        newProperty.projectStatus = "Lead"
        newProperty.createdDate = Date()
        newProperty.lastModified = Date()
        
        do {
            try context.save()
            loadProperties()
            print("✅ New project created: \\(projectName)")
        } catch {
            print("❌ Error creating project: \\(error)")
            showAlert(title: "Error", message: "Failed to create project: \\(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table View Data Source & Delegate
extension PropertyListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PropertyCell", for: indexPath)
        let property = properties[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = property.projectName ?? "Untitled Project"
        
        let treeCount = property.treeMarks?.count ?? 0
        let stumpCount = property.stumps?.count ?? 0
        let status = property.projectStatus ?? "Lead"
        
        cell.detailTextLabel?.text = "Client: \\(property.clientName ?? "Unknown") | Trees: \\(treeCount) | Stumps: \\(stumpCount) | Status: \\(status)"
        
        // Status color indicator
        cell.backgroundColor = statusColor(for: status)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let property = properties[indexPath.row]
        showProjectDetail(for: property)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let property = properties[indexPath.row]
            context.delete(property)
            
            do {
                try context.save()
                properties.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print("❌ Error deleting project: \\(error)")
            }
        }
    }
    
    private func statusColor(for status: String) -> UIColor {
        switch status {
        case "Lead": return UIColor.systemBlue.withAlphaComponent(0.1)
        case "Proposal": return UIColor.systemOrange.withAlphaComponent(0.1)
        case "Active": return UIColor.systemGreen.withAlphaComponent(0.1)
        case "Complete": return UIColor.systemPurple.withAlphaComponent(0.1)
        case "Invoiced": return UIColor.systemGray.withAlphaComponent(0.1)
        default: return UIColor.clear
        }
    }
    
    private func showProjectDetail(for property: Property) {
        // Present project detail view
        let alert = UIAlertController(
            title: property.projectName ?? "Project",
            message: "Trees: \\(property.treeMarks?.count ?? 0)\\nStumps: \\(property.stumps?.count ?? 0)\\nStatus: \\(property.projectStatus ?? "Unknown")",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "View on Map", style: .default) { _ in
            self.dismiss(animated: true) {
                // TODO: Center map on project location
            }
        })
        
        alert.addAction(UIAlertAction(title: "Edit Project", style: .default) { _ in
            self.editProject(property)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func editProject(_ property: Property) {
        let alert = UIAlertController(title: "Edit Project", message: "Update project details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = property.projectName
            textField.placeholder = "Project Name"
        }
        
        alert.addTextField { textField in
            textField.text = property.clientName
            textField.placeholder = "Client Name"
        }
        
        // Add status picker
        alert.addTextField { textField in
            textField.text = property.projectStatus
            textField.placeholder = "Status (Lead/Proposal/Active/Complete/Invoiced)"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            property.projectName = alert.textFields?[0].text
            property.clientName = alert.textFields?[1].text
            property.projectStatus = alert.textFields?[2].text
            property.lastModified = Date()
            
            do {
                try self.context.save()
                self.loadProperties()
            } catch {
                print("❌ Error updating project: \\(error)")
            }
        })
        
        present(alert, animated: true)
    }
}