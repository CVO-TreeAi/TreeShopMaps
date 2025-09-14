import UIKit
import CoreData
import UniformTypeIdentifiers
import PencilKit

class ProposalViewController: UIViewController {
    
    // MARK: - Properties
    var property: Property!
    var proposal: ProjectProposal?
    
    // MARK: - UI Elements
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // Proposal Details
    @IBOutlet weak var proposalAmountTextField: UITextField!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var notesTextView: UITextView!
    
    // Drawing Attachments
    @IBOutlet weak var drawingsStackView: UIStackView!
    @IBOutlet weak var addDrawingButton: UIButton!
    @IBOutlet weak var createSketchButton: UIButton!
    
    // Actions
    @IBOutlet weak var saveButton: UIButton!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    enum ProposalStatus: String, CaseIterable {
        case draft = "Draft"
        case review = "Review"
        case sent = "Sent"
        case approved = "Approved"
        case rejected = "Rejected"
        
        var color: UIColor {
            switch self {
            case .draft: return .systemGray
            case .review: return .systemBlue
            case .sent: return .systemOrange
            case .approved: return .systemGreen
            case .rejected: return .systemRed
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProposalData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Proposal"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Configure status control
        statusSegmentedControl.removeAllSegments()
        ProposalStatus.allCases.enumerated().forEach { index, status in
            statusSegmentedControl.insertSegment(withTitle: status.rawValue, at: index, animated: false)
        }
        statusSegmentedControl.selectedSegmentIndex = 0
        
        // Configure text fields
        proposalAmountTextField.keyboardType = .decimalPad
        proposalAmountTextField.placeholder = "0.00"
        
        // Configure notes
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        
        // Configure drawing buttons
        addDrawingButton.backgroundColor = UIColor.systemBlue
        addDrawingButton.setTitleColor(.white, for: .normal)
        addDrawingButton.layer.cornerRadius = 8
        addDrawingButton.setTitle("📎 Add Drawing/Document", for: .normal)
        
        createSketchButton.backgroundColor = UIColor.systemGreen
        createSketchButton.setTitleColor(.white, for: .normal)
        createSketchButton.layer.cornerRadius = 8
        createSketchButton.setTitle("✏️ Create Sketch", for: .normal)
        
        // Save button
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        
        updateSaveButtonState()
    }
    
    private func loadProposalData() {
        if let proposal = proposal {
            // Load existing proposal
            proposalAmountTextField.text = proposal.proposalAmount?.stringValue
            notesTextView.text = proposal.notes
            
            if let status = proposal.status {
                let statuses = ProposalStatus.allCases.map { $0.rawValue }
                if let index = statuses.firstIndex(of: status) {
                    statusSegmentedControl.selectedSegmentIndex = index
                }
            }
            
            loadAttachedDrawings()
        }
    }
    
    private func loadAttachedDrawings() {
        guard let proposal = proposal,
              let drawings = proposal.drawings?.allObjects as? [ProposalDrawing] else { return }
        
        // Clear existing drawing views
        drawingsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add drawing previews
        for drawing in drawings {
            let drawingView = createDrawingPreview(for: drawing)
            drawingsStackView.addArrangedSubview(drawingView)
        }
    }
    
    private func createDrawingPreview(for drawing: ProposalDrawing) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = 8
        
        let label = UILabel()
        label.text = drawing.fileName ?? "Untitled"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        let typeLabel = UILabel()
        typeLabel.text = drawing.fileType ?? "Unknown"
        typeLabel.font = UIFont.systemFont(ofSize: 12)
        typeLabel.textColor = .secondaryLabel
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteDrawing(_:)), for: .touchUpInside)
        deleteButton.tag = drawing.objectID.hash
        
        let stackView = UIStackView(arrangedSubviews: [label, typeLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        
        let horizontalStack = UIStackView(arrangedSubviews: [stackView, deleteButton])
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
        
        containerView.addSubview(horizontalStack)
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            horizontalStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            containerView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return containerView
    }
    
    @objc private func deleteDrawing(_ sender: UIButton) {
        // Find and delete drawing based on tag
        guard let proposal = proposal,
              let drawings = proposal.drawings?.allObjects as? [ProposalDrawing] else { return }
        
        if let drawingToDelete = drawings.first(where: { $0.objectID.hash == sender.tag }) {
            context.delete(drawingToDelete)
            
            do {
                try context.save()
                loadAttachedDrawings()
            } catch {
                showAlert(title: "Error", message: "Failed to delete drawing: \\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func addDrawingTapped(_ sender: UIButton) {
        presentDocumentPicker()
    }
    
    @IBAction func createSketchTapped(_ sender: UIButton) {
        presentSketchEditor()
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf,
            UTType.image,
            UTType.text,
            UTType.spreadsheet
        ])
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .formSheet
        
        present(documentPicker, animated: true)
    }
    
    private func presentSketchEditor() {
        let sketchVC = SketchViewController()
        sketchVC.delegate = self
        
        let navController = UINavigationController(rootViewController: sketchVC)
        navController.modalPresentationStyle = .fullScreen
        
        present(navController, animated: true)
    }
    
    private func updateSaveButtonState() {
        let hasAmount = !(proposalAmountTextField.text?.isEmpty ?? true)
        saveButton.isEnabled = hasAmount
        navigationItem.rightBarButtonItem?.isEnabled = hasAmount
        
        if hasAmount {
            saveButton.setTitle("💾 Save Proposal", for: .normal)
        } else {
            saveButton.setTitle("Enter proposal amount to save", for: .normal)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        saveProposal()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        saveProposal()
    }
    
    private func saveProposal() {
        guard let amountText = proposalAmountTextField.text,
              let amount = Decimal(string: amountText) else {
            showAlert(title: "Invalid Amount", message: "Please enter a valid proposal amount.")
            return
        }
        
        if proposal == nil {
            proposal = ProjectProposal(context: context)
            proposal?.id = UUID()
            proposal?.property = property
            proposal?.createdAt = Date()
        }
        
        // Update proposal data
        proposal?.proposalAmount = NSDecimalNumber(decimal: amount)
        proposal?.notes = notesTextView.text
        proposal?.updatedAt = Date()
        
        let selectedStatus = ProposalStatus.allCases[statusSegmentedControl.selectedSegmentIndex]
        proposal?.status = selectedStatus.rawValue
        
        // Save to Core Data
        do {
            try context.save()
            
            let alert = UIAlertController(
                title: "Proposal Saved",
                message: "Proposal for $\\(amount) has been saved.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            present(alert, animated: true)
            
        } catch {
            showAlert(title: "Save Error", message: "Failed to save proposal: \\(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Document Picker Delegate
extension ProposalViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            // Read document data
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileType = url.pathExtension
            
            // Create new drawing attachment
            let drawing = ProposalDrawing(context: context)
            drawing.id = UUID()
            drawing.fileName = fileName
            drawing.fileType = fileType
            drawing.drawingData = data
            drawing.createdAt = Date()
            drawing.updatedAt = Date()
            drawing.proposal = proposal
            
            // Generate thumbnail if it's an image
            if fileType.lowercased() == "png" || fileType.lowercased() == "jpg" || fileType.lowercased() == "jpeg" {
                if let image = UIImage(data: data) {
                    drawing.thumbnailData = generateThumbnail(from: image)
                }
            }
            
            try context.save()
            loadAttachedDrawings()
            
            print("✅ Document attached: \\(fileName)")
            
        } catch {
            showAlert(title: "Attachment Error", message: "Failed to attach document: \\(error.localizedDescription)")
        }
    }
    
    private func generateThumbnail(from image: UIImage) -> Data? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Sketch Editor Delegate
extension ProposalViewController: SketchViewControllerDelegate {
    func sketchViewController(_ controller: SketchViewController, didCreateSketch drawing: PKDrawing) {
        // Convert PKDrawing to image and save
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        guard let imageData = image.jpegData(compressionQuality: 0.9) else { return }
        
        // Create new drawing attachment
        let proposalDrawing = ProposalDrawing(context: context)
        proposalDrawing.id = UUID()
        proposalDrawing.fileName = "Sketch_\\(Date().timeIntervalSince1970)"
        proposalDrawing.fileType = "sketch"
        proposalDrawing.drawingData = imageData
        proposalDrawing.thumbnailData = generateThumbnail(from: image)
        proposalDrawing.createdAt = Date()
        proposalDrawing.updatedAt = Date()
        proposalDrawing.proposal = proposal
        
        do {
            try context.save()
            loadAttachedDrawings()
            print("✅ Sketch saved as drawing attachment")
        } catch {
            showAlert(title: "Save Error", message: "Failed to save sketch: \\(error.localizedDescription)")
        }
        
        controller.dismiss(animated: true)
    }
    
    func sketchViewControllerDidCancel(_ controller: SketchViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Simple Sketch Editor
protocol SketchViewControllerDelegate: AnyObject {
    func sketchViewController(_ controller: SketchViewController, didCreateSketch drawing: PKDrawing)
    func sketchViewControllerDidCancel(_ controller: SketchViewController)
}

class SketchViewController: UIViewController {
    weak var delegate: SketchViewControllerDelegate?
    
    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSketchEditor()
    }
    
    private func setupSketchEditor() {
        title = "Create Sketch"
        view.backgroundColor = .white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Setup PencilKit canvas
        canvasView = PKCanvasView()
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .white
        canvasView.isOpaque = false
        
        view.addSubview(canvasView)
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Setup tool picker for Apple Pencil support
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    @objc private func cancelTapped() {
        delegate?.sketchViewControllerDidCancel(self)
    }
    
    @objc private func saveTapped() {
        delegate?.sketchViewController(self, didCreateSketch: canvasView.drawing)
    }
}