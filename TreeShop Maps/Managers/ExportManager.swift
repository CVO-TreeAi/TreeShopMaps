import Foundation
import PDFKit
import MapKit
import MessageUI
import CoreData

class ExportManager: NSObject {
    static let shared = ExportManager()
    
    func generatePDFReport(for property: Property) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "TreeShop Maps",
            kCGPDFContextAuthor: "TreeShop",
            kCGPDFContextTitle: "Property Report - \(property.clientName ?? "")"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let headingFont = UIFont.boldSystemFont(ofSize: 16)
            
            var yPosition: CGFloat = 50
            
            let title = "Property Report"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let date = "Date: \(dateFormatter.string(from: Date()))"
            date.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
            yPosition += 30
            
            "Client Information".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headingFont])
            yPosition += 25
            
            let clientInfo = """
            Name: \(property.clientName ?? "N/A")
            Address: \(property.address ?? "N/A")
            Phone: \(property.phoneNumber ?? "N/A")
            Email: \(property.emailAddress ?? "N/A")
            """
            clientInfo.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
            yPosition += 80
            
            if let workZones = property.workZones as? Set<WorkZone>, !workZones.isEmpty {
                "Work Zones".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headingFont])
                yPosition += 25
                
                var totalAcreage = 0.0
                var totalPrice = 0.0
                
                for zone in workZones {
                    let zoneInfo = """
                    Service: \(zone.servicePackage ?? "N/A")
                    Acreage: \(String(format: "%.2f", zone.acreage)) acres
                    Estimated Price: $\(String(format: "%.2f", zone.priceEstimate))
                    Status: \(zone.isCompleted ? "Completed" : "Pending")
                    """
                    zoneInfo.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
                    yPosition += 70
                    
                    totalAcreage += zone.acreage
                    totalPrice += zone.priceEstimate
                    
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
                
                let totals = """
                Total Acreage: \(String(format: "%.2f", totalAcreage)) acres
                Total Estimated Price: $\(String(format: "%.2f", totalPrice))
                """
                totals.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headingFont])
                yPosition += 50
            }
            
            if let treeMarks = property.treeMarks as? Set<TreeMark>, !treeMarks.isEmpty {
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = 50
                }
                
                "Tree Inventory".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headingFont])
                yPosition += 25
                
                let treeCount = "Total Trees Marked: \(treeMarks.count)"
                treeCount.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
                yPosition += 20
                
                var speciesCount: [String: Int] = [:]
                for tree in treeMarks {
                    let species = tree.species ?? "Unknown"
                    speciesCount[species] = (speciesCount[species] ?? 0) + 1
                }
                
                for (species, count) in speciesCount {
                    let speciesInfo = "\(species): \(count) trees"
                    speciesInfo.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: [.font: bodyFont])
                    yPosition += 20
                }
            }
            
            if let sessions = property.sessions as? Set<WorkSession>, !sessions.isEmpty {
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = 50
                }
                
                "Work Sessions".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headingFont])
                yPosition += 25
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                
                for session in sessions {
                    let sessionInfo = """
                    Date: \(dateFormatter.string(from: session.startTime ?? Date()))
                    Operator: \(session.operatorName ?? "N/A")
                    Acres Covered: \(String(format: "%.2f", session.acresCovered))
                    """
                    sessionInfo.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
                    yPosition += 60
                    
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
            }
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Property_Report_\(Date().timeIntervalSince1970).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    func exportKML(for property: Property) -> URL? {
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <name>\(property.clientName ?? "Property") - TreeShop Maps</name>
        <description>Exported from TreeShop Maps on \(Date())</description>
        """
        
        kmlString += """
        <Style id="workZoneStyle">
        <LineStyle>
        <color>ff0000ff</color>
        <width>2</width>
        </LineStyle>
        <PolyStyle>
        <color>7f00ff00</color>
        </PolyStyle>
        </Style>
        """
        
        kmlString += """
        <Style id="treeMarkStyle">
        <IconStyle>
        <color>ff00ff00</color>
        <scale>1.0</scale>
        <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/tree.png</href>
        </Icon>
        </IconStyle>
        </Style>
        """
        
        if let workZones = property.workZones as? Set<WorkZone> {
            for zone in workZones {
                kmlString += """
                <Placemark>
                <name>Work Zone - \(zone.servicePackage ?? "Unknown")</name>
                <description>
                Acreage: \(zone.acreage) acres
                Estimated Price: $\(zone.priceEstimate)
                Status: \(zone.isCompleted ? "Completed" : "Pending")
                </description>
                <styleUrl>#workZoneStyle</styleUrl>
                <Polygon>
                <outerBoundaryIs>
                <LinearRing>
                <coordinates>
                """
                
                if let polygonData = zone.polygonData,
                   let polygon = (try? NSKeyedUnarchiver(forReadingFrom: polygonData))?.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? MKPolygon {
                    let points = (0..<polygon.pointCount).map { polygon.points()[$0] }
                    for point in points {
                        let coordinate = point.coordinate
                        kmlString += "\(coordinate.longitude),\(coordinate.latitude),0 "
                    }
                }
                
                kmlString += """
                </coordinates>
                </LinearRing>
                </outerBoundaryIs>
                </Polygon>
                </Placemark>
                """
            }
        }
        
        if let treeMarks = property.treeMarks as? Set<TreeMark> {
            for tree in treeMarks {
                kmlString += """
                <Placemark>
                <name>\(tree.species ?? "Unknown Tree")</name>
                <description>
                Height: \(tree.height) ft
                DBH: \(tree.dbh) inches
                Canopy Radius: \(tree.canopyRadius) ft
                Date Marked: \(tree.dateMarked ?? Date())
                Marked By: \(tree.markedBy ?? "Unknown")
                </description>
                <styleUrl>#treeMarkStyle</styleUrl>
                <Point>
                <coordinates>\(tree.longitude),\(tree.latitude),0</coordinates>
                </Point>
                </Placemark>
                """
            }
        }
        
        kmlString += """
        </Document>
        </kml>
        """
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Property_\(Date().timeIntervalSince1970).kml"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try kmlString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving KML: \(error)")
            return nil
        }
    }
    
    func createShareableLink(for fileURL: URL) -> URL? {
        return fileURL
    }
    
    func shareViaEmail(fileURL: URL, from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            showEmailNotAvailableAlert(from: viewController)
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setSubject("TreeShop Maps Report")
        mailComposer.setMessageBody("Please find the attached report from TreeShop Maps.", isHTML: false)
        
        if let data = try? Data(contentsOf: fileURL) {
            let fileName = fileURL.lastPathComponent
            let mimeType = fileURL.pathExtension == "pdf" ? "application/pdf" : "application/vnd.google-earth.kml+xml"
            mailComposer.addAttachmentData(data, mimeType: mimeType, fileName: fileName)
        }
        
        viewController.present(mailComposer, animated: true)
    }
    
    private func showEmailNotAvailableAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Email Not Available",
            message: "Please configure your email account in Settings to send reports via email.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    func exportCSV(for property: Property) -> URL? {
        var csvString = "Type,Latitude,Longitude,Details\n"
        
        if let workZones = property.workZones as? Set<WorkZone> {
            for zone in workZones {
                csvString += "WorkZone,N/A,N/A,\"\(zone.servicePackage ?? "") - \(zone.acreage) acres - $\(zone.priceEstimate)\"\n"
            }
        }
        
        if let treeMarks = property.treeMarks as? Set<TreeMark> {
            for tree in treeMarks {
                csvString += "Tree,\(tree.latitude),\(tree.longitude),\"\(tree.species ?? "") - Height: \(tree.height)ft - DBH: \(tree.dbh)in\"\n"
            }
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Property_Data_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
}

extension ExportManager: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}