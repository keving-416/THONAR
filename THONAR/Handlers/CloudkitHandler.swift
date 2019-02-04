//
//  CloudkitHandler.swift
//  THONAR
//
//  Created by Kevin Gardner on 1/25/19.
//  Copyright © 2019 THON. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

// Creates global variables for the default CKContainer and the publicCloudDatabase
var container: CKContainer = CKContainer.default()
public var publicDatabase: CKDatabase  = container.publicCloudDatabase

public class CloudKitHandler {
    // Timer used to check for network connection in event of network related failures
    var errorTimer: Timer?
    
    // Instance of the CoreDataHandler that handles querying from CoreData
    let coreDataHandler = CoreDataHandler()
    
    public func setUpSubscription() {
        do {
            let fetchedArray = try coreDataHandler.getCoreDataArray(forEntityName: "SubscriptionFetched")
            
            if fetchedArray.count == 0 {
                print("subscription fetch block 1")
                // If fetched array is empty, then this is the first fetch call and an object should be created for the entity and set to false.
                //  Then save the subscription
                coreDataHandler.setValue(forEntityName: "SubscriptionFetched", forKey: "subscriptionFetched", forValue: false)
                saveSubscription()
            } else if !(coreDataHandler.getBoolData(forNSManagedObject: fetchedArray[0], forKey: "subscriptionFetched") ?? true) {
                print("subscription fetch block 2")
                // If the subscription has not been saved, save it
                saveSubscription()
            } else {
                print("Subscription already saved")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func saveSubscription() {
        let predicate = NSPredicate(value: true)
        
        // Creates a Query Subcription that fires whenever a record is created in the iCloud Database
        let subscription = CKQuerySubscription(recordType: "videos", predicate: predicate, subscriptionID: "videosSubscription", options: [.firesOnRecordCreation, .firesOnRecordDeletion])
        let info = CKSubscription.NotificationInfo()
        
        // Sets up the notification message
        info.shouldSendContentAvailable = true
        info.alertBody = "Videos have been updated"
        subscription.notificationInfo = info
        
        // Saves the subscription to the iCloud Database
        publicDatabase.save(subscription) { (subscription, error) in
            if error != nil {
                print("Error adding the subscription")
            } else {
                print("subscriptionSaved")
                do {
                    // Call on coreDataHandler to return the NSManagedObjects for the given entity
                    let fetchedArray = try self.coreDataHandler.getCoreDataArray(forEntityName: "SubscriptionFetched")
                    
                    // Set the value for the first object for the given key to true to save in memory that the subscription has saved
                    self.coreDataHandler.setValue(forNSManagedObject: fetchedArray[0], forValue: true, forKey: "subscriptionFetched")
                    
                    // Set up observer that should be called whenever the subscription fires
                    //NotificationCenter.default.addObserver(self, selector: #selector(self.updateforNewVideos(_:)), name: NSNotification.Name("updateForNewVideos"), object: nil)
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    @objc private func updateforNewVideos(_ notification: NSNotification) {
        print("updateForNewVideos ran")
        // Get the CKQueryNotification that is stored in the userInfo property of the notification
        let queryNotification = notification.userInfo!["queryNotification"] as! CKQueryNotification
        print(queryNotification)
        
        // Query new record from iCloud Database
        publicDatabase.fetch(withRecordID: queryNotification.recordID!) { (record, error) in
            guard error == nil else {
                print("Error with fetch record with ID \(queryNotification.recordID!)")
                return
            }
            
            if queryNotification.queryNotificationReason == .recordUpdated {
                // Handle when a record is updated
            } else {
                // Handle when a record is created
                print(".recordCreated within updateForNewVideos")
                guard let imageAsset = record!["Image"] as? CKAsset else {
                    return
                }
                
                self.coreDataHandler.save(forURL: imageAsset.fileURL, forName: record!["Name"]!, withImages: true)
                self.coreDataHandler.save(forURL: (record!["Video"] as? CKAsset)!.fileURL, forName: record!["Name"]!, withImages: false)
            }
        }
    }
    
    func queryNotificationData(for queryNotification: CKQueryNotification) {
        // Query new record from iCloud Database
        publicDatabase.fetch(withRecordID: queryNotification.recordID!) { (record, error) in
            if error != nil {
                print("Error with fetch record with ID \(queryNotification.recordID?.recordName)")
                guard let _ = queryNotification.recordID?.recordName else {
                    print("Fetch canceled due to error")
                    return
                }
            }
            
            if queryNotification.queryNotificationReason == .recordUpdated {
                // Handle when a record is updated
            } else if queryNotification.queryNotificationReason == .recordCreated {
                // Handle when a record is created
                print(".recordCreated within updateForNewVideos")
                guard let imageAsset = record!["Image"] as? CKAsset else {
                    return
                }
                
                self.coreDataHandler.save(forURL: imageAsset.fileURL, forName: record!["Name"]!, withImages: true)
                self.coreDataHandler.save(forURL: (record!["Video"] as? CKAsset)!.fileURL, forName: record!["Name"]!, withImages: false)
            } else if queryNotification.queryNotificationReason == .recordDeleted {
                self.coreDataHandler.delete(forName: (queryNotification.recordID?.recordName)!)
            } else {
                print("queryNotificationReason not handled")
            }
        }
    }
    
    public func dataHasFetched() -> Bool {
        return coreDataHandler.dataHasFetched()
    }
    
    public func fetchEstablishments() {
        do {
            let fetchedArray =  try coreDataHandler.getCoreDataArray(forEntityName: "Fetched")
            
            if fetchedArray.count == 0 {
                print("fetched block 1")
                // If fetched array is empty, then this is the first fetch call and an object should be created for the entity and set to false.
                //  Then query from the iCloud Database and set up the subscriptions
                coreDataHandler.setValue(forEntityName: "Fetched", forKey: "cloudkitFetched", forValue: false)
                self.query()
                self.setUpSubscription()
            } else if !(coreDataHandler.getBoolData(forNSManagedObject: fetchedArray[0], forKey: "cloudkitFetched") ?? true) {
                print("fetched block 2")
                coreDataHandler.batchDeleteRecords(forEntityName: "VideoPhotoBundle")
                // If the cloudkit records did not finish querying then requery from the iCloud Database and set up the subscriptions
                self.query()
                self.setUpSubscription()
            } else {
                print("Query already occured")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func query() {
        print("begin query")
        // Gets records with any value
        let predicate = NSPredicate(value: true)
        
        // Video and Photo pairs are stored with establishment type "videos"
        let establishmentType = "videos"
        
        let query = CKQuery(recordType: establishmentType, predicate: predicate)
        
        var imageQueryOperation = CKQueryOperation(query: query)
        var videoQueryOperation = CKQueryOperation(query: query)
        
        // Set to a high number so that all records are queried
        imageQueryOperation.resultsLimit = 10000
        
        // Sets it so only the Image and Name fields are queried so as to not query the videos, which take much longer
        imageQueryOperation.desiredKeys = ["Image", "Name"]
        
        //
        imageQueryOperation.qualityOfService = .userInitiated
        
        imageQueryOperation.recordFetchedBlock = { (record) -> Void in
            // Safely unwrap the asset for key Image
            guard let imageAsset = record["Image"] as? CKAsset else {
                return
            }
            
            // Save the asset URL to CoreData
            self.coreDataHandler.save(forURL: imageAsset.fileURL, forName: record["Name"]!, withImages: true)
        }
        
        imageQueryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            
            if error != nil {
                if let ckError = error as? CKError {
                    DispatchQueue.main.async {
                        // Handle CKError on main thread
                        
                        self.handleCKError(ckError)
                        print("Cloud Query Error for Images - Fetch Establishments: \(ckError)")
                        //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Images - Fetch Establishments: \(String(describing: error))", ofSize: AlertSize.large, withDismissAnimation: true)
                    }
                } else if let nsError = error {
                    DispatchQueue.main.async {
                        // Handle NSError on main thread
                        
                        //self.handleCKError(ckError)
                        print("Cloud Query Error for Images - Fetch Establishments: \(nsError)")
                        //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Images - Fetch Establishments: \(String(describing: nsError))", ofSize: AlertSize.large, withDismissAnimation: true)
                    }
                } else {
                    print("Cloud Query Error for Images not handled - \(String(describing: error))")
                }
                return
            }
            
            if cursor != nil {
                // If there are records that still haven't been queried for the Image and Name fields, query again
                let newQueryOperation = CKQueryOperation(cursor: cursor!)
                newQueryOperation.cursor = cursor
                newQueryOperation.resultsLimit = imageQueryOperation.resultsLimit
                newQueryOperation.queryCompletionBlock = imageQueryOperation.queryCompletionBlock
                newQueryOperation.qualityOfService = imageQueryOperation.qualityOfService
                
                imageQueryOperation = newQueryOperation
                
                publicDatabase.add(imageQueryOperation)
                return
            } else {
                // If there are no more records to query for the Image and Name fields, start querying for the Video and Name fields
                DispatchQueue.main.async {
                    print("Query Complete for Images")
                    //self.alertMessageDelegate?.showAlert(forMessage: "Query Complete for Images", ofSize: AlertSize.large, withDismissAnimation: true)
                }
                
                videoQueryOperation = CKQueryOperation(query: query)
                videoQueryOperation.resultsLimit = 10000
                videoQueryOperation.desiredKeys = ["Video", "Name"]
                videoQueryOperation.qualityOfService = .userInitiated
                
                videoQueryOperation.recordFetchedBlock = { (record) -> Void in
                    // Save the asset URL to CoreData
                    self.coreDataHandler.save(forURL: (record["Video"] as? CKAsset)!.fileURL, forName: record["Name"]!, withImages: false)
                }
                
                videoQueryOperation.queryCompletionBlock = { (cursor, error) -> Void in
                    
                    if error != nil {
                        if let ckError = error as? CKError {
                            DispatchQueue.main.async {
                                // Handle CKError on main thread
                                
                                self.handleCKError(ckError)
                                print("Cloud Query Error for Videos - Fetch Establishments: \(String(describing: ckError))")
                                //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Videos - Fetch Establishments: \(String(describing: ckError))", ofSize: AlertSize.large, withDismissAnimation: true)
                            }
                        } else if let nsError = error as NSError? {
                            DispatchQueue.main.async {
                                // Handle NSError on main thread
                                
                                //self.handleCKError(ckError)
                                self.handleNSError(nsError)
                                print("Cloud Query Error for Videos - Fetch Establishments: \(String(describing: nsError))")
                                //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Videos - Fetch Establishments: \(String(describing: nsError))", ofSize: AlertSize.large, withDismissAnimation: true)
                            }
                        } else {
                            print("Cloud Query Error for Videos not handled - \(String(describing: error))")
                        }
                        return
                    }
                    
                    if cursor != nil {
                        // If there are records that still haven't been queried for the Video and Name fields, query again
                        let newestQueryOperation = CKQueryOperation(cursor: cursor!)
                        newestQueryOperation.cursor = cursor
                        newestQueryOperation.resultsLimit = videoQueryOperation.resultsLimit
                        newestQueryOperation.queryCompletionBlock = videoQueryOperation.queryCompletionBlock
                        newestQueryOperation.qualityOfService = videoQueryOperation.qualityOfService
                        
                        videoQueryOperation = newestQueryOperation
                        
                        publicDatabase.add(videoQueryOperation)
                        return
                    } else {
                        // If there are no more records to query for the Video and Name fields, save in memory that the query has finished
                        DispatchQueue.main.async {
                            print("Query Complete for Videos")
                            //self.alertMessageDelegate?.showAlert(forMessage: "Query Complete for Videos", ofSize: AlertSize.large, withDismissAnimation: true)
                        }
                        
                        do {
                            let fetchedArray = try self.coreDataHandler.getCoreDataArray(forEntityName: "Fetched")
                            self.coreDataHandler.setValue(forNSManagedObject: fetchedArray[0], forValue: true, forKey: "cloudkitFetched")
                            try managedContext.save()
                        } catch let error as NSError {
                            print("Could not save. \(error), \(error.userInfo)")
                        }
                    }
                }
                
                publicDatabase.add(videoQueryOperation)
            }
        }
        
        publicDatabase.add(imageQueryOperation)
    }
    
    private func handleNSError(_ error: NSError) {
        switch error.code {
        case 4097:
            errorTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(errorTimerCallBack(timer:)), userInfo: nil, repeats: false)
        default:
            print("Default NSError")
        }
    }
    
    private func handleCKError(_ error: CKError) {
        switch error.code {
        case .alreadyShared:
            print("alreadyShared")
        case .assetFileModified:
            print("assetFileModified")
        case .assetFileNotFound:
            print("assetFileNotFound")
        case .assetNotAvailable:
            print("assetNotAvailable")
        case .badContainer:
            print("badContainer")
        case .badDatabase:
            print("badDatabase")
        case .batchRequestFailed:
            print("batchRequestFailed")
        case .changeTokenExpired:
            print("changeTokenExpired")
        case .constraintViolation:
            print("constraintViolation")
        case .incompatibleVersion:
            print("incompatibleVersion")
        case .internalError:
            print("internalError")
        case .invalidArguments:
            print("invalidArguments")
        case .limitExceeded:
            print("limitExceeded")
        case .managedAccountRestricted:
            print("managedAccountRestricted")
        case .missingEntitlement:
            print("missingEntitlement")
        case .networkFailure:
            errorTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(errorTimerCallBack(timer:)), userInfo: nil, repeats: true)
            print("networkFailure")
        case .networkUnavailable:
            errorTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(errorTimerCallBack(timer:)), userInfo: nil, repeats: true)
            //alertMessageDelegate?.showAlert(forMessage: "Could not download images or videos due to the network being unavailable. Please connect to the internet to resume the download.", ofSize: .large, withDismissAnimation: true)
            print("networkUnavailable")
        case .notAuthenticated:
            print("notAuthenticated")
        case .operationCancelled:
            print("operationCancelled")
        case .partialFailure:
            print("partialFailure")
        case .participantMayNeedVerification:
            print("participantMayNeedVerification")
        case .permissionFailure:
            print("permissionFailure")
        case .quotaExceeded:
            print("quotaExceeded")
        case .referenceViolation:
            print("referenceViolation")
        case .requestRateLimited:
            guard let timeInterval = error.retryAfterSeconds else {
                print("error.retryAfterSeconds is \(String(describing: error.retryAfterSeconds))")
                return
            }
            errorTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(retryQuery(timer:)), userInfo: nil, repeats: false)
            print("requestRateLimited")
        case .serverRecordChanged:
            print("serverRecordChanged")
        case .serverRejectedRequest:
            print("serverRejectedRequest")
        case .serverResponseLost:
            print("serverResponseLost")
        case .serviceUnavailable:
            guard let timeInterval = error.retryAfterSeconds else {
                print("error.retryAfterSeconds is \(String(describing: error.retryAfterSeconds))")
                return
            }
            errorTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(retryQuery(timer:)), userInfo: nil, repeats: false)
            print("serviceUnavailable")
        case .tooManyParticipants:
            print("tooManyParticipants")
        case .unknownItem:
            print("unknownItem")
        case .userDeletedZone:
            print("userDeletedZone")
        case .zoneBusy:
            print("zoneBusy")
        case .zoneNotFound:
            print("zoneNotFound")
        default:
            print("Default CKError")
        }
    }
    
    @objc private func errorTimerCallBack( timer: Timer) {
        // Instance of Reachability class to check the network connection
        let reachability = Reachability()
        if reachability.isConnectedToNetwork() == true {
            print("connected to internet")
            
            // Delete records from core Data
            coreDataHandler.batchDeleteRecords(forEntityName: "VideoPhotoBundle")
            
            // Reattempt to fetch the cloudkit establishments
            fetchEstablishments()
            
            // Invalidate the timer
            errorTimer?.invalidate()
            errorTimer = nil
        } else {
            print("not connected to internet")
        }
    }
    
    @objc private func retryQuery( timer: Timer) {
        
        // Delete records from core Data
        coreDataHandler.batchDeleteRecords(forEntityName: "VideoPhotoBundle")
        
        // Reattempt to fetch the cloudkit establishments
        fetchEstablishments()
    }
    
}
