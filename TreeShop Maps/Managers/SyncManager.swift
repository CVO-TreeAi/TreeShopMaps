import Foundation
import CloudKit
import CoreData
import UIKit

class SyncManager: NSObject {
    static let shared = SyncManager()
    
    private let container = CKContainer.default()
    private let database = CKContainer.default().privateCloudDatabase
    private let syncQueue = DispatchQueue(label: "com.treeshop.maps.sync", attributes: .concurrent)
    
    private var pendingChanges: [CKRecord] = []
    private var isSyncing = false
    
    override init() {
        super.init()
        setupCloudKit()
    }
    
    private func setupCloudKit() {
        container.accountStatus { status, error in
            switch status {
            case .available:
                print("CloudKit is available")
                self.startSync()
            case .noAccount:
                print("No iCloud account")
            case .restricted:
                print("CloudKit restricted")
            case .couldNotDetermine:
                print("Could not determine CloudKit status")
            case .temporarilyUnavailable:
                print("CloudKit temporarily unavailable")
            @unknown default:
                print("Unknown CloudKit status")
            }
        }
    }
    
    func startSync() {
        guard !isSyncing else { return }
        
        isSyncing = true
        
        syncQueue.async { [weak self] in
            self?.syncProperties()
            self?.syncWorkZones()
            self?.syncTreeMarks()
            self?.syncWorkSessions()
            self?.isSyncing = false
        }
    }
    
    private func syncProperties() {
        let query = CKQuery(recordType: "Property", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                DispatchQueue.main.async {
                    self?.mergeProperties(records)
                }
            case .failure(let error):
                print("Error syncing properties: \(error)")
            }
        }
    }
    
    private func syncWorkZones() {
        let query = CKQuery(recordType: "WorkZone", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                DispatchQueue.main.async {
                    self?.mergeWorkZones(records)
                }
            case .failure(let error):
                print("Error syncing work zones: \(error)")
            }
        }
    }
    
    private func syncTreeMarks() {
        let query = CKQuery(recordType: "TreeMark", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                DispatchQueue.main.async {
                    self?.mergeTreeMarks(records)
                }
            case .failure(let error):
                print("Error syncing tree marks: \(error)")
            }
        }
    }
    
    private func syncWorkSessions() {
        let query = CKQuery(recordType: "WorkSession", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                DispatchQueue.main.async {
                    self?.mergeWorkSessions(records)
                }
            case .failure(let error):
                print("Error syncing work sessions: \(error)")
            }
        }
    }
    
    private func mergeProperties(_ records: [CKRecord]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        for record in records {
            let fetchRequest: NSFetchRequest<Property> = Property.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.recordID.recordName)
            
            do {
                let existingProperties = try context.fetch(fetchRequest)
                
                if let property = existingProperties.first {
                    updateProperty(property, from: record)
                } else {
                    createProperty(from: record, in: context)
                }
            } catch {
                print("Error fetching property: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func mergeWorkZones(_ records: [CKRecord]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        for record in records {
            let fetchRequest: NSFetchRequest<WorkZone> = WorkZone.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.recordID.recordName)
            
            do {
                let existingZones = try context.fetch(fetchRequest)
                
                if let zone = existingZones.first {
                    updateWorkZone(zone, from: record)
                } else {
                    createWorkZone(from: record, in: context)
                }
            } catch {
                print("Error fetching work zone: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func mergeTreeMarks(_ records: [CKRecord]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        for record in records {
            let fetchRequest: NSFetchRequest<TreeMark> = TreeMark.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.recordID.recordName)
            
            do {
                let existingMarks = try context.fetch(fetchRequest)
                
                if let mark = existingMarks.first {
                    updateTreeMark(mark, from: record)
                } else {
                    createTreeMark(from: record, in: context)
                }
            } catch {
                print("Error fetching tree mark: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func mergeWorkSessions(_ records: [CKRecord]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        for record in records {
            let fetchRequest: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.recordID.recordName)
            
            do {
                let existingSessions = try context.fetch(fetchRequest)
                
                if let session = existingSessions.first {
                    updateWorkSession(session, from: record)
                } else {
                    createWorkSession(from: record, in: context)
                }
            } catch {
                print("Error fetching work session: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func updateProperty(_ property: Property, from record: CKRecord) {
        property.clientName = record["clientName"] as? String
        property.address = record["address"] as? String
        property.phoneNumber = record["phoneNumber"] as? String
        property.emailAddress = record["emailAddress"] as? String
        property.lastModified = record["lastModified"] as? Date ?? Date()
    }
    
    private func createProperty(from record: CKRecord, in context: NSManagedObjectContext) {
        let property = Property(context: context)
        property.id = UUID(uuidString: record.recordID.recordName)
        property.clientName = record["clientName"] as? String
        property.address = record["address"] as? String
        property.phoneNumber = record["phoneNumber"] as? String
        property.emailAddress = record["emailAddress"] as? String
        property.createdDate = record["createdDate"] as? Date ?? Date()
        property.lastModified = record["lastModified"] as? Date ?? Date()
    }
    
    private func updateWorkZone(_ zone: WorkZone, from record: CKRecord) {
        zone.servicePackage = record["servicePackage"] as? String
        zone.acreage = record["acreage"] as? Double ?? 0
        zone.estimatedHours = record["estimatedHours"] as? Double ?? 0
        zone.priceEstimate = record["priceEstimate"] as? Double ?? 0
        zone.notes = record["notes"] as? String
        zone.isCompleted = record["isCompleted"] as? Bool ?? false
        
        if let polygonData = record["polygonData"] as? Data {
            zone.polygonData = polygonData
        }
    }
    
    private func createWorkZone(from record: CKRecord, in context: NSManagedObjectContext) {
        let zone = WorkZone(context: context)
        zone.id = UUID(uuidString: record.recordID.recordName)
        zone.servicePackage = record["servicePackage"] as? String
        zone.acreage = record["acreage"] as? Double ?? 0
        zone.estimatedHours = record["estimatedHours"] as? Double ?? 0
        zone.priceEstimate = record["priceEstimate"] as? Double ?? 0
        zone.notes = record["notes"] as? String
        zone.isCompleted = record["isCompleted"] as? Bool ?? false
        
        if let polygonData = record["polygonData"] as? Data {
            zone.polygonData = polygonData
        }
    }
    
    private func updateTreeMark(_ mark: TreeMark, from record: CKRecord) {
        mark.latitude = record["latitude"] as? Double ?? 0
        mark.longitude = record["longitude"] as? Double ?? 0
        mark.species = record["species"] as? String
        mark.height = record["height"] as? Double ?? 0
        mark.canopyRadius = record["canopyRadius"] as? Double ?? 0
        mark.dbh = record["dbh"] as? Double ?? 0
        mark.dateMarked = record["dateMarked"] as? Date
        mark.markedBy = record["markedBy"] as? String
        mark.notes = record["notes"] as? String
        mark.healthStatus = record["healthStatus"] as? String
        mark.workRecommended = record["workRecommended"] as? String
        
        if let photoAsset = record["photo"] as? CKAsset,
           let photoURL = photoAsset.fileURL,
           let photoData = try? Data(contentsOf: photoURL) {
            mark.photoData = photoData
        }
    }
    
    private func createTreeMark(from record: CKRecord, in context: NSManagedObjectContext) {
        let mark = TreeMark(context: context)
        mark.id = UUID(uuidString: record.recordID.recordName)
        mark.latitude = record["latitude"] as? Double ?? 0
        mark.longitude = record["longitude"] as? Double ?? 0
        mark.species = record["species"] as? String
        mark.height = record["height"] as? Double ?? 0
        mark.canopyRadius = record["canopyRadius"] as? Double ?? 0
        mark.dbh = record["dbh"] as? Double ?? 0
        mark.dateMarked = record["dateMarked"] as? Date
        mark.markedBy = record["markedBy"] as? String
        mark.notes = record["notes"] as? String
        mark.healthStatus = record["healthStatus"] as? String
        mark.workRecommended = record["workRecommended"] as? String
        
        if let photoAsset = record["photo"] as? CKAsset,
           let photoURL = photoAsset.fileURL,
           let photoData = try? Data(contentsOf: photoURL) {
            mark.photoData = photoData
        }
    }
    
    private func updateWorkSession(_ session: WorkSession, from record: CKRecord) {
        session.startTime = record["startTime"] as? Date
        session.endTime = record["endTime"] as? Date
        session.operatorName = record["operatorName"] as? String
        session.machineID = record["machineID"] as? String
        session.acresCovered = record["acresCovered"] as? Double ?? 0
        session.fuelUsed = record["fuelUsed"] as? Double ?? 0
        session.weatherConditions = record["weatherConditions"] as? String
        
        if let trackData = record["gpsTrackData"] as? Data {
            session.gpsTrackData = trackData
        }
    }
    
    private func createWorkSession(from record: CKRecord, in context: NSManagedObjectContext) {
        let session = WorkSession(context: context)
        session.id = UUID(uuidString: record.recordID.recordName)
        session.startTime = record["startTime"] as? Date
        session.endTime = record["endTime"] as? Date
        session.operatorName = record["operatorName"] as? String
        session.machineID = record["machineID"] as? String
        session.acresCovered = record["acresCovered"] as? Double ?? 0
        session.fuelUsed = record["fuelUsed"] as? Double ?? 0
        session.weatherConditions = record["weatherConditions"] as? String
        
        if let trackData = record["gpsTrackData"] as? Data {
            session.gpsTrackData = trackData
        }
    }
    
    func queueForSync(_ record: CKRecord) {
        pendingChanges.append(record)
        
        if pendingChanges.count >= 10 {
            syncPendingChanges()
        }
    }
    
    func syncPendingChanges() {
        guard !pendingChanges.isEmpty else { return }
        
        let operation = CKModifyRecordsOperation(recordsToSave: pendingChanges, recordIDsToDelete: nil)
        
        operation.modifyRecordsResultBlock = { [weak self] result in
            switch result {
            case .success:
                print("Successfully synced \(self?.pendingChanges.count ?? 0) records")
                self?.pendingChanges.removeAll()
            case .failure(let error):
                print("Error syncing pending changes: \(error)")
            }
        }
        
        database.add(operation)
    }
    
    func handleNetworkChange(isConnected: Bool) {
        if isConnected {
            startSync()
            syncPendingChanges()
        }
    }
}