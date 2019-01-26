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
import CoreData

var container: CKContainer = CKContainer.default()
public var publicDatabase: CKDatabase  = container.publicCloudDatabase

public class CloudKitHandler {
    var errorTimer: Timer?
    let coreDataHandler = CoreDataHandler()
    
    public func setUpSubscription() {
        let fetchedArray: [NSManagedObject]
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SubscriptionFetched")
        
        do {
            fetchedArray = try managedContext.fetch(fetchRequest)
            
            let entity = NSEntityDescription.entity(forEntityName: "SubscriptionFetched", in: managedContext)!
            
            let fetched = NSManagedObject(entity: entity, insertInto: managedContext)
            
            if fetchedArray.count == 0 {
                fetched.setValue(false, forKey: "subscriptionFetched")
                saveSubscription(forNSManagedObject: fetched)
            } else if !((fetchedArray[0] as NSManagedObject).value(forKey: "subscriptionFetched") as! Bool) {
                saveSubscription(forNSManagedObject: fetched)
            } else {
                print("Subscription already saved")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func saveSubscription(forNSManagedObject fetched: NSManagedObject) {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "videos", predicate: predicate, subscriptionID: "videosSubscription", options: [.firesOnRecordCreation])
        let info = CKSubscription.NotificationInfo()
        
        info.shouldSendContentAvailable = true
        info.alertBody = "New video is available"
        subscription.notificationInfo = info
        
        publicDatabase.save(subscription) { (subscription, error) in
            if error != nil {
                print("Error adding the subscription")
            } else {
                print("subscriptionSaved")
                fetched.setValue(true, forKey: "subscriptionFetched")
                NotificationCenter.default.addObserver(self, selector: #selector(self.updateforNewVideos(_:)), name: NSNotification.Name("updateForNewVideos"), object: nil)
            }
        }
    }
    
    @objc private func updateforNewVideos(_ notification: NSNotification) {
        print("updateForNewVideos ran")
        let queryNotification = notification.userInfo!["queryNotification"] as! CKQueryNotification
        print(queryNotification)
        publicDatabase.fetch(withRecordID: queryNotification.recordID!) { (record, error) in
            guard error == nil else {
                print("Error with fetch record with ID \(queryNotification.recordID!)")
                return
            }
            
            if queryNotification.queryNotificationReason == .recordUpdated {
                
            } else {
                print(".recordCreated within updateForNewVideos")
                guard let imageAsset = record!["Image"] as? CKAsset else {
                    return
                }
                
                self.coreDataHandler.save(forURL: imageAsset.fileURL, forName: record!["Name"]!, withImages: true)
                self.coreDataHandler.save(forURL: (record!["Video"] as? CKAsset)!.fileURL, forName: record!["Name"]!, withImages: false)
            }
        }
    }
    
    public func fetchEstablishments() {
        let fetchedArray: [NSManagedObject]
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Fetched")
        
        
        do {
            fetchedArray =  try managedContext.fetch(fetchRequest)
            if fetchedArray.count == 0 {
                let entity = NSEntityDescription.entity(forEntityName: "Fetched", in: managedContext)!
                
                let fetched = NSManagedObject(entity: entity, insertInto: managedContext)
                
                fetched.setValue(false, forKey: "cloudkitFetched")
                print("fetched block 1")
                self.query(forManagedContext: managedContext)
                self.setUpSubscription()
            } else if !((fetchedArray[0] as NSManagedObject).value(forKey: "cloudkitFetched") as! Bool) {
                print("fetched block 2")
                coreDataHandler.batchDeleteRecords(forEntityName: "VideoPhotoBundle")
                self.query(forManagedContext: managedContext)
                self.setUpSubscription()
            } else {
                print("Query already occured")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func query(forManagedContext managedContext: NSManagedObjectContext) {
        print("begin query")
        let predicate = NSPredicate(value: true)
        let establishmentType = "videos"
        let query = CKQuery(recordType: establishmentType, predicate: predicate)
        var queryOperation = CKQueryOperation(query: query)
        var videoQueryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 10000
        queryOperation.desiredKeys = ["Image", "Name"]
        queryOperation.qualityOfService = .userInitiated
        
        queryOperation.recordFetchedBlock = { (record) -> Void in
            guard let imageAsset = record["Image"] as? CKAsset else {
                return
            }
            self.coreDataHandler.save(forURL: imageAsset.fileURL, forName: record["Name"]!, withImages: true)
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            
            if error != nil {
                if let ckError = error as? CKError {
                    DispatchQueue.main.async {
                        self.handleCKError(ckError)
                        print("Cloud Query Error for Images - Fetch Establishments: \(ckError)")
                        //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Images - Fetch Establishments: \(String(describing: error))", ofSize: AlertSize.large, withDismissAnimation: true)
                    }
                } else if let nsError = error {
                    DispatchQueue.main.async {
                        //self.handleCKError(ckError)
                        print("Cloud Query Error for Images - Fetch Establishments: \(nsError)")
                        //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Images - Fetch Establishments: \(String(describing: nsError))", ofSize: AlertSize.large, withDismissAnimation: true)
                    }
                } else {
                    
                }
                return
            }
            
            if cursor != nil {
                let newQueryOperation = CKQueryOperation(cursor: cursor!)
                newQueryOperation.cursor = cursor
                newQueryOperation.resultsLimit = queryOperation.resultsLimit
                newQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                newQueryOperation.qualityOfService = queryOperation.qualityOfService
                
                queryOperation = newQueryOperation
                
                publicDatabase.add(queryOperation)
                return
            } else {
                DispatchQueue.main.async {
                    print("Query Complete for Images")
                    //self.alertMessageDelegate?.showAlert(forMessage: "Query Complete for Images", ofSize: AlertSize.large, withDismissAnimation: true)
                }
                
                videoQueryOperation = CKQueryOperation(query: query)
                videoQueryOperation.resultsLimit = 5000
                videoQueryOperation.desiredKeys = ["Video", "Name"]
                videoQueryOperation.qualityOfService = .userInitiated
                
                videoQueryOperation.recordFetchedBlock = { (record) -> Void in
                    self.coreDataHandler.save(forURL: (record["Video"] as? CKAsset)!.fileURL, forName: record["Name"]!, withImages: false)
                }
                
                videoQueryOperation.queryCompletionBlock = { (cursor, error) -> Void in
                    
                    if error != nil {
                        if let ckError = error as? CKError {
                            DispatchQueue.main.async {
                                self.handleCKError(ckError)
                                print("Cloud Query Error for Videos - Fetch Establishments: \(String(describing: ckError))")
                                //self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error for Videos - Fetch Establishments: \(String(describing: ckError))", ofSize: AlertSize.large, withDismissAnimation: true)
                            }
                        } else if let nsError = error as NSError? {
                            DispatchQueue.main.async {
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
                        let newestQueryOperation = CKQueryOperation(cursor: cursor!)
                        newestQueryOperation.cursor = cursor
                        newestQueryOperation.resultsLimit = videoQueryOperation.resultsLimit
                        newestQueryOperation.queryCompletionBlock = videoQueryOperation.queryCompletionBlock
                        newestQueryOperation.qualityOfService = videoQueryOperation.qualityOfService
                        
                        videoQueryOperation = newestQueryOperation
                        
                        publicDatabase.add(videoQueryOperation)
                        return
                    } else {
                        DispatchQueue.main.async {
                            print("Query Complete for Videos")
                            //self.alertMessageDelegate?.showAlert(forMessage: "Query Complete for Videos", ofSize: AlertSize.large, withDismissAnimation: true)
                        }
                        
                        let fetchedArray: [NSManagedObject]
                        
                        let fetchedFetchRequest =
                            NSFetchRequest<NSManagedObject>(entityName: "Fetched")
                        
                        do {
                            fetchedArray = try managedContext.fetch(fetchedFetchRequest)
                            fetchedArray[0].setValue(true, forKey: "cloudkitFetched")
                            try managedContext.save()
                        } catch let error as NSError {
                            print("Could not save. \(error), \(error.userInfo)")
                        }
                    }
                }
                
                publicDatabase.add(videoQueryOperation)
            }
        }
        
        publicDatabase.add(queryOperation)
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
