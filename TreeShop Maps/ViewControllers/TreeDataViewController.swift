import UIKit
import CoreData
import Photos

protocol TreeDataViewControllerDelegate: AnyObject {
    func treeDataViewControllerDidSave(_ controller: TreeDataViewController)
    func treeDataViewControllerDidDelete(_ controller: TreeDataViewController)
}

class TreeDataViewController: UIViewController {
    
    weak var delegate: TreeDataViewControllerDelegate?
    var treeMark: TreeMark?
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    private var speciesPicker: UIPickerView!
    private var speciesTextField: UITextField!
    private var heightTextField: UITextField!
    private var canopyRadiusTextField: UITextField!
    private var dbhTextField: UITextField!
    private var healthStatusSegmentedControl: UISegmentedControl!
    private var notesTextView: UITextView!
    private var photoImageView: UIImageView!
    private var takePhotoButton: UIButton!
    
    private let speciesOptions = ["Oak", "Pine", "Maple", "Cypress", "Palm", "Magnolia", "Cedar", "Other"]
    private let healthOptions = ["Excellent", "Good", "Fair", "Poor", "Dead"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
        loadTreeData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Tree Data"
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupFormFields()
    }
    
    private func setupFormFields() {
        var previousView: UIView? = nil
        
        let speciesLabel = createLabel("Species:")
        contentView.addSubview(speciesLabel)
        NSLayoutConstraint.activate([
            speciesLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            speciesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            speciesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        speciesTextField = UITextField()
        speciesTextField.translatesAutoresizingMaskIntoConstraints = false
        speciesTextField.borderStyle = .roundedRect
        speciesTextField.placeholder = "Select species"
        contentView.addSubview(speciesTextField)
        NSLayoutConstraint.activate([
            speciesTextField.topAnchor.constraint(equalTo: speciesLabel.bottomAnchor, constant: 8),
            speciesTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            speciesTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            speciesTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        speciesPicker = UIPickerView()
        speciesPicker.delegate = self
        speciesPicker.dataSource = self
        speciesTextField.inputView = speciesPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton]
        speciesTextField.inputAccessoryView = toolbar
        
        previousView = speciesTextField
        
        let heightLabel = createLabel("Height (feet):")
        contentView.addSubview(heightLabel)
        NSLayoutConstraint.activate([
            heightLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            heightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            heightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        heightTextField = createTextField(placeholder: "Enter height in feet", keyboardType: .decimalPad)
        contentView.addSubview(heightTextField)
        NSLayoutConstraint.activate([
            heightTextField.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 8),
            heightTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            heightTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            heightTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        previousView = heightTextField
        
        let canopyLabel = createLabel("Canopy Radius (feet):")
        contentView.addSubview(canopyLabel)
        NSLayoutConstraint.activate([
            canopyLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            canopyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            canopyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        canopyRadiusTextField = createTextField(placeholder: "Enter canopy radius in feet", keyboardType: .decimalPad)
        contentView.addSubview(canopyRadiusTextField)
        NSLayoutConstraint.activate([
            canopyRadiusTextField.topAnchor.constraint(equalTo: canopyLabel.bottomAnchor, constant: 8),
            canopyRadiusTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            canopyRadiusTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            canopyRadiusTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        previousView = canopyRadiusTextField
        
        let dbhLabel = createLabel("DBH - Diameter at Breast Height (inches):")
        contentView.addSubview(dbhLabel)
        NSLayoutConstraint.activate([
            dbhLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            dbhLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dbhLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        dbhTextField = createTextField(placeholder: "Enter DBH in inches", keyboardType: .decimalPad)
        contentView.addSubview(dbhTextField)
        NSLayoutConstraint.activate([
            dbhTextField.topAnchor.constraint(equalTo: dbhLabel.bottomAnchor, constant: 8),
            dbhTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dbhTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dbhTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        previousView = dbhTextField
        
        let healthLabel = createLabel("Health Status:")
        contentView.addSubview(healthLabel)
        NSLayoutConstraint.activate([
            healthLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            healthLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            healthLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        healthStatusSegmentedControl = UISegmentedControl(items: healthOptions)
        healthStatusSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        healthStatusSegmentedControl.selectedSegmentIndex = 1
        contentView.addSubview(healthStatusSegmentedControl)
        NSLayoutConstraint.activate([
            healthStatusSegmentedControl.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 8),
            healthStatusSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            healthStatusSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            healthStatusSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        previousView = healthStatusSegmentedControl
        
        let notesLabel = createLabel("Notes:")
        contentView.addSubview(notesLabel)
        NSLayoutConstraint.activate([
            notesLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        notesTextView = UITextView()
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(notesTextView)
        NSLayoutConstraint.activate([
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesTextView.heightAnchor.constraint(equalToConstant: 100)
        ])
        previousView = notesTextView
        
        let photoLabel = createLabel("Photo:")
        contentView.addSubview(photoLabel)
        NSLayoutConstraint.activate([
            photoLabel.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
            photoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        photoImageView = UIImageView()
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.contentMode = .scaleAspectFit
        photoImageView.backgroundColor = .systemGray6
        photoImageView.layer.cornerRadius = 8
        photoImageView.clipsToBounds = true
        contentView.addSubview(photoImageView)
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: photoLabel.bottomAnchor, constant: 8),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        takePhotoButton = UIButton(type: .system)
        takePhotoButton.setTitle("Take Photo", for: .normal)
        takePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        takePhotoButton.backgroundColor = .systemBlue
        takePhotoButton.setTitleColor(.white, for: .normal)
        takePhotoButton.layer.cornerRadius = 8
        takePhotoButton.addTarget(self, action: #selector(takePhotoButtonTapped), for: .touchUpInside)
        takePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(takePhotoButton)
        NSLayoutConstraint.activate([
            takePhotoButton.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 12),
            takePhotoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            takePhotoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            takePhotoButton.heightAnchor.constraint(equalToConstant: 44),
            takePhotoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }
    
    private func createTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        return textField
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        
        if treeMark?.species != nil {
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteButtonTapped))
            deleteButton.tintColor = .systemRed
            navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, deleteButton]
        }
    }
    
    @objc private func dismissPicker() {
        speciesTextField.resignFirstResponder()
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let treeMark = treeMark else { return }
        
        treeMark.species = speciesTextField.text
        treeMark.height = Double(heightTextField.text ?? "0") ?? 0
        treeMark.canopyRadius = Double(canopyRadiusTextField.text ?? "0") ?? 0
        treeMark.dbh = Double(dbhTextField.text ?? "0") ?? 0
        treeMark.healthStatus = healthOptions[healthStatusSegmentedControl.selectedSegmentIndex]
        treeMark.notes = notesTextView.text
        
        if let image = photoImageView.image {
            treeMark.photoData = image.jpegData(compressionQuality: 0.7)
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            try context.save()
            delegate?.treeDataViewControllerDidSave(self)
            dismiss(animated: true)
        } catch {
            showAlert(title: "Error", message: "Failed to save tree data: \(error.localizedDescription)")
        }
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(title: "Delete Tree Mark", message: "Are you sure you want to delete this tree mark?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteTreeMark()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteTreeMark() {
        guard let treeMark = treeMark,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let context = appDelegate.persistentContainer.viewContext
        context.delete(treeMark)
        
        do {
            try context.save()
            delegate?.treeDataViewControllerDidDelete(self)
            dismiss(animated: true)
        } catch {
            showAlert(title: "Error", message: "Failed to delete tree mark: \(error.localizedDescription)")
        }
    }
    
    @objc private func takePhotoButtonTapped() {
        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = takePhotoButton
            popover.sourceRect = takePhotoButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func loadTreeData() {
        guard let treeMark = treeMark else { return }
        
        speciesTextField.text = treeMark.species
        heightTextField.text = treeMark.height > 0 ? String(treeMark.height) : ""
        canopyRadiusTextField.text = treeMark.canopyRadius > 0 ? String(treeMark.canopyRadius) : ""
        dbhTextField.text = treeMark.dbh > 0 ? String(treeMark.dbh) : ""
        notesTextView.text = treeMark.notes
        
        if let healthStatus = treeMark.healthStatus,
           let index = healthOptions.firstIndex(of: healthStatus) {
            healthStatusSegmentedControl.selectedSegmentIndex = index
        }
        
        if let photoData = treeMark.photoData {
            photoImageView.image = UIImage(data: photoData)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension TreeDataViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return speciesOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return speciesOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        speciesTextField.text = speciesOptions[row]
    }
}

extension TreeDataViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            photoImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            photoImageView.image = originalImage
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}