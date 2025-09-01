import UIKit
import MapKit

class TreeAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        canShowCallout = true
        
        let imageView = UIImageView(image: UIImage(systemName: "tree.fill"))
        imageView.tintColor = .systemGreen
        imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        self.image = imageView.image
        
        let detailButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = detailButton
        
        setupCalloutView()
    }
    
    private func setupCalloutView() {
        let calloutView = UIView()
        calloutView.translatesAutoresizingMaskIntoConstraints = false
        
        let thumbnailImageView = UIImageView()
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 4
        thumbnailImageView.backgroundColor = .systemGray6
        calloutView.addSubview(thumbnailImageView)
        
        let speciesLabel = UILabel()
        speciesLabel.translatesAutoresizingMaskIntoConstraints = false
        speciesLabel.font = UIFont.boldSystemFont(ofSize: 14)
        calloutView.addSubview(speciesLabel)
        
        let dbhLabel = UILabel()
        dbhLabel.translatesAutoresizingMaskIntoConstraints = false
        dbhLabel.font = UIFont.systemFont(ofSize: 12)
        dbhLabel.textColor = .secondaryLabel
        calloutView.addSubview(dbhLabel)
        
        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 11)
        dateLabel.textColor = .tertiaryLabel
        calloutView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: calloutView.leadingAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: calloutView.topAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 50),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 50),
            
            speciesLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 8),
            speciesLabel.topAnchor.constraint(equalTo: calloutView.topAnchor),
            speciesLabel.trailingAnchor.constraint(equalTo: calloutView.trailingAnchor),
            
            dbhLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 8),
            dbhLabel.topAnchor.constraint(equalTo: speciesLabel.bottomAnchor, constant: 2),
            dbhLabel.trailingAnchor.constraint(equalTo: calloutView.trailingAnchor),
            
            dateLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 8),
            dateLabel.topAnchor.constraint(equalTo: dbhLabel.bottomAnchor, constant: 2),
            dateLabel.trailingAnchor.constraint(equalTo: calloutView.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: calloutView.bottomAnchor)
        ])
        
        leftCalloutAccessoryView = calloutView
    }
    
    func configure(with treeMark: TreeMark) {
        if let healthStatus = treeMark.healthStatus {
            switch healthStatus {
            case "Excellent":
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            case "Good":
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            case "Fair":
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            case "Poor":
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
            case "Dead":
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            default:
                image = UIImage(systemName: "tree.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            }
        }
        
        if let calloutView = leftCalloutAccessoryView,
           let thumbnailImageView = calloutView.subviews.first(where: { $0 is UIImageView }) as? UIImageView,
           let speciesLabel = calloutView.subviews.first(where: { $0 is UILabel && ($0 as! UILabel).font == UIFont.boldSystemFont(ofSize: 14) }) as? UILabel,
           let dbhLabel = calloutView.subviews.first(where: { $0 is UILabel && ($0 as! UILabel).font == UIFont.systemFont(ofSize: 12) }) as? UILabel,
           let dateLabel = calloutView.subviews.first(where: { $0 is UILabel && ($0 as! UILabel).font == UIFont.systemFont(ofSize: 11) }) as? UILabel {
            
            if let photoData = treeMark.photoData {
                thumbnailImageView.image = UIImage(data: photoData)
            } else {
                thumbnailImageView.image = UIImage(systemName: "tree.circle.fill")
            }
            
            speciesLabel.text = treeMark.species ?? "Unknown Species"
            dbhLabel.text = String(format: "DBH: %.1f inches", treeMark.dbh)
            
            if let date = treeMark.dateMarked {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                dateLabel.text = formatter.string(from: date)
            }
        }
    }
}