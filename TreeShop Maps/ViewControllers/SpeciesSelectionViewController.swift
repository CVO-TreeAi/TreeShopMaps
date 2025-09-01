import UIKit

class SpeciesSelectionViewController: UIViewController {
    
    // MARK: - Properties
    var onSpeciesSelected: ((String) -> Void)?
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    // Common tree species list
    private let allSpecies = [
        // Hardwoods
        "Oak, White",
        "Oak, Red", 
        "Oak, Black",
        "Oak, Pin",
        "Oak, Post",
        "Oak, Chestnut",
        "Maple, Sugar",
        "Maple, Red",
        "Maple, Silver",
        "Maple, Norway",
        "Ash, White",
        "Ash, Green",
        "Hickory, Shagbark",
        "Hickory, Pignut",
        "Walnut, Black",
        "Cherry, Black",
        "Elm, American",
        "Elm, Slippery",
        "Birch, Yellow",
        "Birch, Paper",
        "Birch, River",
        "Beech, American",
        "Poplar, Yellow",
        "Sycamore, American",
        "Willow, Black",
        "Willow, Weeping",
        "Cottonwood, Eastern",
        "Basswood, American",
        "Locust, Black",
        "Locust, Honey",
        
        // Conifers
        "Pine, White",
        "Pine, Red",
        "Pine, Pitch",
        "Pine, Virginia",
        "Pine, Loblolly",
        "Pine, Longleaf",
        "Pine, Slash",
        "Pine, Ponderosa",
        "Spruce, Norway",
        "Spruce, White",
        "Spruce, Black",
        "Spruce, Blue",
        "Fir, Douglas",
        "Fir, Balsam",
        "Fir, Fraser",
        "Hemlock, Eastern",
        "Cedar, Eastern Red",
        "Cedar, Northern White",
        "Cypress, Bald",
        "Larch, American",
        
        // Ornamental/Other
        "Dogwood, Flowering",
        "Redbud, Eastern",
        "Magnolia, Southern",
        "Crabapple",
        "Hawthorn",
        "Serviceberry",
        "Sassafras",
        "Persimmon, American",
        "Mulberry, Red",
        "Catalpa, Northern",
        "Ginkgo",
        "Sweetgum, American",
        
        // Additional common species
        "Unknown/Other",
        "Dead/Snag",
        "Invasive Species"
    ].sorted()
    
    private var filteredSpecies: [String] = []
    private var recentSpecies: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecentSpecies()
        filteredSpecies = getDefaultList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = TreeShopTheme.backgroundColor
        title = "Select Tree Species"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Search Bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Type species name..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .words
        searchBar.returnKeyType = .done
        
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = TreeShopTheme.buttonBackground
            searchBar.searchTextField.textColor = TreeShopTheme.primaryText
            searchBar.searchTextField.leftView?.tintColor = TreeShopTheme.secondaryText
        }
        
        view.addSubview(searchBar)
        
        // Table View
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = TreeShopTheme.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SpeciesCell.self, forCellReuseIdentifier: "SpeciesCell")
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorColor = TreeShopTheme.buttonBackground
        
        view.addSubview(tableView)
        
        // Add custom entry button
        let customButton = UIButton(type: .system)
        customButton.translatesAutoresizingMaskIntoConstraints = false
        customButton.setTitle("Use Custom Entry", for: .normal)
        customButton.backgroundColor = TreeShopTheme.buttonBackground
        customButton.setTitleColor(TreeShopTheme.primaryGreen, for: .normal)
        customButton.layer.cornerRadius = TreeShopTheme.smallCornerRadius
        customButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        customButton.addTarget(self, action: #selector(useCustomEntry), for: .touchUpInside)
        view.addSubview(customButton)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 56),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: customButton.topAnchor, constant: -10),
            
            customButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            customButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func useCustomEntry() {
        let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !text.isEmpty {
            selectSpecies(text)
        } else {
            selectSpecies("Unknown")
        }
    }
    
    private func selectSpecies(_ species: String) {
        // Save to recent
        saveToRecent(species)
        
        // Call completion
        onSpeciesSelected?(species)
        dismiss(animated: true)
    }
    
    // MARK: - Data Management
    private func getDefaultList() -> [String] {
        if !recentSpecies.isEmpty {
            // Show recent species at top, then common ones
            var list = recentSpecies
            let remainingSpecies = allSpecies.filter { !recentSpecies.contains($0) }
            list.append(contentsOf: remainingSpecies.prefix(20))
            return list
        } else {
            // Show most common species
            return Array(allSpecies.prefix(30))
        }
    }
    
    private func filterSpecies(searchText: String) {
        if searchText.isEmpty {
            filteredSpecies = getDefaultList()
        } else {
            // Filter and sort by relevance
            let searchLower = searchText.lowercased()
            
            // Exact matches first
            let exactMatches = allSpecies.filter { 
                $0.lowercased() == searchLower 
            }
            
            // Starts with search text
            let startsWithMatches = allSpecies.filter { 
                $0.lowercased().hasPrefix(searchLower) && !exactMatches.contains($0)
            }
            
            // Contains search text
            let containsMatches = allSpecies.filter { 
                $0.lowercased().contains(searchLower) && 
                !exactMatches.contains($0) && 
                !startsWithMatches.contains($0)
            }
            
            filteredSpecies = exactMatches + startsWithMatches + containsMatches
            
            // If no matches, suggest custom entry
            if filteredSpecies.isEmpty {
                filteredSpecies = ["No matches - tap 'Use Custom Entry' below"]
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Recent Species
    private func loadRecentSpecies() {
        recentSpecies = UserDefaults.standard.stringArray(forKey: "RecentTreeSpecies") ?? []
    }
    
    private func saveToRecent(_ species: String) {
        // Remove if already exists
        recentSpecies.removeAll { $0 == species }
        
        // Add to front
        recentSpecies.insert(species, at: 0)
        
        // Keep only last 10
        if recentSpecies.count > 10 {
            recentSpecies = Array(recentSpecies.prefix(10))
        }
        
        UserDefaults.standard.set(recentSpecies, forKey: "RecentTreeSpecies")
    }
}

// MARK: - UISearchBarDelegate
extension SpeciesSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterSpecies(searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // If there's text and only one match, select it
        if filteredSpecies.count == 1 && !filteredSpecies[0].starts(with: "No matches") {
            selectSpecies(filteredSpecies[0])
        } else if let text = searchBar.text, !text.isEmpty {
            // Use custom entry
            selectSpecies(text)
        }
    }
}

// MARK: - UITableViewDataSource
extension SpeciesSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSpecies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpeciesCell", for: indexPath) as! SpeciesCell
        
        let species = filteredSpecies[indexPath.row]
        cell.configure(with: species, isRecent: recentSpecies.contains(species))
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SpeciesSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let species = filteredSpecies[indexPath.row]
        if !species.starts(with: "No matches") {
            selectSpecies(species)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - Custom Cell
class SpeciesCell: UITableViewCell {
    private let speciesLabel = UILabel()
    private let recentBadge = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = TreeShopTheme.backgroundColor
        
        let selectedView = UIView()
        selectedView.backgroundColor = TreeShopTheme.buttonBackground
        selectedBackgroundView = selectedView
        
        speciesLabel.translatesAutoresizingMaskIntoConstraints = false
        speciesLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        speciesLabel.textColor = TreeShopTheme.primaryText
        contentView.addSubview(speciesLabel)
        
        recentBadge.translatesAutoresizingMaskIntoConstraints = false
        recentBadge.text = "RECENT"
        recentBadge.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        recentBadge.textColor = TreeShopTheme.backgroundColor
        recentBadge.backgroundColor = TreeShopTheme.primaryGreen
        recentBadge.textAlignment = .center
        recentBadge.layer.cornerRadius = 4
        recentBadge.layer.masksToBounds = true
        recentBadge.isHidden = true
        contentView.addSubview(recentBadge)
        
        NSLayoutConstraint.activate([
            speciesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            speciesLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            speciesLabel.trailingAnchor.constraint(lessThanOrEqualTo: recentBadge.leadingAnchor, constant: -10),
            
            recentBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recentBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            recentBadge.widthAnchor.constraint(equalToConstant: 50),
            recentBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with species: String, isRecent: Bool) {
        speciesLabel.text = species
        recentBadge.isHidden = !isRecent
        
        if species.starts(with: "No matches") {
            speciesLabel.textColor = TreeShopTheme.secondaryText
            speciesLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        } else {
            speciesLabel.textColor = TreeShopTheme.primaryText
            speciesLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
    }
}