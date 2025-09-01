import Foundation
import PDFKit
import MapKit
import MessageUI
import UIKit

class ProfessionalExportManager: NSObject {
    static let shared = ProfessionalExportManager()
    
    // MARK: - PDF Export for Professional Measurements
    func generateMeasurementPDFReport(measurements: [StoredMeasurement], title: String = "Land Measurement Report") -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "TreeShop Maps Professional",
            kCGPDFContextAuthor: "TreeShop Maps",
            kCGPDFContextTitle: title,
            kCGPDFContextSubject: "Professional Land Measurement Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 28)
            let headingFont = UIFont.boldSystemFont(ofSize: 18)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            
            var yPosition: CGFloat = margin
            
            // Header
            let headerTitle = title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            headerTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 45
            
            // Date and summary info
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .short
            
            let summaryInfo = """
            Generated: \(dateFormatter.string(from: Date()))
            Total Measurements: \(measurements.count)
            Software: TreeShop Maps Professional v1.0
            """
            
            summaryInfo.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray])
            yPosition += 60
            
            // Summary statistics
            let settings = MeasurementSettings.shared
            let distanceMeasurements = measurements.filter { $0.type == .distance }
            let areaMeasurements = measurements.filter { $0.type == .area }
            
            let totalDistance = distanceMeasurements.reduce(0) { $0 + settings.distanceUnit.convert(from: $1.value) }
            let totalArea = areaMeasurements.reduce(0) { $0 + settings.areaUnit.convert(from: $1.value) }
            
            "Summary Statistics".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: headingFont])
            yPosition += 25
            
            let summaryStats = """
            Distance Measurements: \(distanceMeasurements.count) (\(String(format: "%.1f", totalDistance)) \(settings.distanceUnit.abbreviation) total)
            Area Measurements: \(areaMeasurements.count) (\(String(format: "%.2f", totalArea)) \(settings.areaUnit.abbreviation) total)
            """
            
            summaryStats.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: bodyFont])
            yPosition += 50
            
            // Individual measurements
            if !measurements.isEmpty {
                "Detailed Measurements".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: headingFont])
                yPosition += 25
                
                for (index, measurement) in measurements.enumerated() {
                    // Check if we need a new page
                    if yPosition > pageHeight - 150 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    // Measurement header
                    let measurementTitle = "\(index + 1). \(measurement.name)"
                    measurementTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
                    yPosition += 20
                    
                    // Measurement details
                    var details = """
                    Type: \(measurement.type.rawValue)
                    Value: \(measurement.getFormattedValue(distanceUnit: settings.distanceUnit, areaUnit: settings.areaUnit))
                    """
                    
                    if let perimeterText = measurement.getFormattedPerimeter(distanceUnit: settings.distanceUnit) {
                        details += "\nPerimeter: \(perimeterText)"
                    }
                    
                    details += "\nDate: \(dateFormatter.string(from: measurement.dateCreated))"
                    
                    if let accuracy = measurement.accuracy {
                        let accuracyText = accuracy > 0 ? "±\(String(format: "%.1f", accuracy))m" : "No GPS signal"
                        details += "\nGPS Accuracy: \(accuracyText)"
                    }
                    
                    if let notes = measurement.notes, !notes.isEmpty {
                        details += "\nNotes: \(notes)"
                    }
                    
                    // Coordinates
                    details += "\nCoordinates (\(measurement.coordinates.count) points):"
                    
                    details.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: [.font: bodyFont])
                    yPosition += CGFloat(details.components(separatedBy: "\n").count) * 15
                    
                    // List coordinates in a compact format
                    let maxCoordsPerLine = 2
                    let coordChunks = measurement.coordinates.chunked(into: maxCoordsPerLine)
                    
                    for chunk in coordChunks {
                        let coordLine = chunk.map { String(format: "(%.6f, %.6f)", $0.latitude, $0.longitude) }.joined(separator: "  ")
                        coordLine.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: [.font: smallFont, .foregroundColor: UIColor.darkGray])
                        yPosition += 12
                    }
                    
                    yPosition += 15 // Space between measurements
                }
            }
            
            // Footer on last page
            if yPosition < pageHeight - 100 {
                let footerY = pageHeight - 50
                let footerText = "Generated by TreeShop Maps Professional - Professional Land Measurement Tool"
                footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: [.font: smallFont, .foregroundColor: UIColor.lightGray])
            }
        }
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Measurement_Report_\(Date().timeIntervalSince1970).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Enhanced KML Export
    func exportMeasurementsToKML(measurements: [StoredMeasurement], title: String = "TreeShop Measurements") -> URL? {
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <name>\(title)</name>
        <description>Professional measurements exported from TreeShop Maps on \(Date())</description>
        """
        
        // Styles
        kmlString += """
        <Style id="distanceLineStyle">
        <LineStyle>
        <color>ff0099ff</color>
        <width>3</width>
        </LineStyle>
        </Style>
        
        <Style id="areaPolygonStyle">
        <LineStyle>
        <color>ff00ff00</color>
        <width>2</width>
        </LineStyle>
        <PolyStyle>
        <color>4400ff00</color>
        </PolyStyle>
        </Style>
        
        <Style id="measurementPointStyle">
        <IconStyle>
        <color>ff00ff00</color>
        <scale>0.8</scale>
        <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
        </Icon>
        </IconStyle>
        </Style>
        """
        
        let settings = MeasurementSettings.shared
        
        for measurement in measurements {
            let valueText = measurement.getFormattedValue(distanceUnit: settings.distanceUnit, areaUnit: settings.areaUnit)
            let perimeterText = measurement.getFormattedPerimeter(distanceUnit: settings.distanceUnit) ?? ""
            
            var description = """
            Type: \(measurement.type.rawValue)
            Value: \(valueText)
            """
            
            if !perimeterText.isEmpty {
                description += "\nPerimeter: \(perimeterText)"
            }
            
            description += "\nDate: \(measurement.dateCreated)"
            
            if let notes = measurement.notes, !notes.isEmpty {
                description += "\nNotes: \(notes)"
            }
            
            if let accuracy = measurement.accuracy {
                let accuracyText = accuracy > 0 ? "±\(String(format: "%.1f", accuracy))m" : "No GPS signal"
                description += "\nGPS Accuracy: \(accuracyText)"
            }
            
            kmlString += """
            <Placemark>
            <name>\(measurement.name)</name>
            <description><![CDATA[\(description)]]></description>
            """
            
            if measurement.type == .distance && measurement.coordinates.count == 2 {
                // Line for distance measurements
                kmlString += """
                <styleUrl>#distanceLineStyle</styleUrl>
                <LineString>
                <coordinates>
                """
                for coord in measurement.coordinates {
                    kmlString += "\(coord.longitude),\(coord.latitude),0 "
                }
                kmlString += """
                </coordinates>
                </LineString>
                """
            } else if measurement.type == .area && measurement.coordinates.count >= 3 {
                // Polygon for area measurements
                kmlString += """
                <styleUrl>#areaPolygonStyle</styleUrl>
                <Polygon>
                <outerBoundaryIs>
                <LinearRing>
                <coordinates>
                """
                for coord in measurement.coordinates {
                    kmlString += "\(coord.longitude),\(coord.latitude),0 "
                }
                // Close the polygon
                if let firstCoord = measurement.coordinates.first {
                    kmlString += "\(firstCoord.longitude),\(firstCoord.latitude),0 "
                }
                kmlString += """
                </coordinates>
                </LinearRing>
                </outerBoundaryIs>
                </Polygon>
                """
            }
            
            kmlString += "</Placemark>\n"
            
            // Add points as separate placemarks
            for (index, coord) in measurement.coordinates.enumerated() {
                kmlString += """
                <Placemark>
                <name>\(measurement.name) - Point \(index + 1)</name>
                <styleUrl>#measurementPointStyle</styleUrl>
                <Point>
                <coordinates>\(coord.longitude),\(coord.latitude),0</coordinates>
                </Point>
                </Placemark>
                """
            }
        }
        
        kmlString += """
        </Document>
        </kml>
        """
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Measurements_\(Date().timeIntervalSince1970).kml"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try kmlString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving KML: \(error)")
            return nil
        }
    }
    
    // MARK: - Enhanced CSV Export
    func exportMeasurementsToCSV(measurements: [StoredMeasurement]) -> URL? {
        let settings = MeasurementSettings.shared
        
        var csvContent = "Name,Type,Value,Units,Perimeter,Perimeter Units,Date Created,GPS Accuracy,Notes,Point Count,Coordinates\n"
        
        for measurement in measurements {
            let value = measurement.type == .distance ? 
                settings.distanceUnit.convert(from: measurement.value) :
                settings.areaUnit.convert(from: measurement.value)
            
            let units = measurement.type == .distance ? 
                settings.distanceUnit.abbreviation : 
                settings.areaUnit.abbreviation
            
            let perimeter = measurement.perimeter.map { settings.distanceUnit.convert(from: $0) } ?? 0
            let perimeterUnits = measurement.perimeter != nil ? settings.distanceUnit.abbreviation : ""
            
            let accuracy = measurement.accuracy.map { $0 > 0 ? String(format: "%.1f", $0) : "No Signal" } ?? "Unknown"
            let notes = measurement.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            let coordString = measurement.coordinates.map { 
                String(format: "%.6f,%.6f", $0.latitude, $0.longitude) 
            }.joined(separator: ";")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let line = """
            "\(measurement.name)",\(measurement.type.rawValue),\(String(format: "%.3f", value)),\(units),\(String(format: "%.1f", perimeter)),\(perimeterUnits),\(dateFormatter.string(from: measurement.dateCreated)),\(accuracy),"\(notes)",\(measurement.coordinates.count),"\(coordString)"
            """
            
            csvContent += line + "\n"
        }
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "Measurements_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Share Multiple Files
    func shareFiles(_ urls: [URL], from viewController: UIViewController, sourceView: UIView? = nil) {
        let activityViewController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
        }
        
        viewController.present(activityViewController, animated: true)
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}