//
//  CoreDataHandler.swift
//  THONAR
//
//  Created by Kevin Gardner on 1/25/19.
//  Copyright © 2019 THON. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import zlib
import AVFoundation

let appDelegate = UIApplication.shared.delegate as? AppDelegate
let managedContext = appDelegate!.persistentContainer.viewContext

public class CoreDataHandler {
    // Returns Data for a given NSManagedObject and a given key
    public func getData(forNSManagedObject resource: Any, forKey key: String) -> Data? {
        return ((resource as? NSManagedObject)?.value(forKey: key) as? NSData) as Data?
    }
    
    // Returns a String for a given NSManagedObject and a given key
    public func getStringData(forNSManagedObject resource: Any, forKey key: String) -> String? {
        return (resource as? NSManagedObject)?.value(forKey: key) as? String
    }
    
    // Returns a Bool for a given NSManagedObject and a given key
    public func getBoolData(forNSManagedObject resource: Any, forKey key: String) -> Bool? {
        return (resource as? NSManagedObject)?.value(forKey: key) as? Bool
    }
    
    // Deletes
    public func delete(forName name: String) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VideoPhotoBundle")
        
        let array: [NSManagedObject]
        
        do {
            array = try managedContext.fetch(fetchRequest)
            
            for object in array {
                if self.getStringData(forNSManagedObject: object, forKey: "name") == name {
                    managedContext.delete(object)
                    
                    try managedContext.save()
                    break
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    public func dataHasFetched() -> Bool {
        let fetchedArray: [NSManagedObject]
        
        let fetchedFetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Fetched")
        
        do {
            fetchedArray = try managedContext.fetch(fetchedFetchRequest)
            
            if fetchedArray.count == 0 || !((fetchedArray[0] as NSManagedObject).value(forKey: "cloudkitFetched") as! Bool) {
                return false
            } else {
                return true
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return false
    }
    
    // Query's from "VideoPhotoBundle" and updates the given NSMutableArray
    public func getCoreData(forResourceArray resources: inout NSMutableArray?) {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "VideoPhotoBundle")
        
        let fetchedArray: [NSManagedObject]
        
        let fetchedFetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Fetched")
        
        do {
            print("resources count \(String(describing: resources?.count))")
            fetchedArray = try managedContext.fetch(fetchedFetchRequest)
            
            if fetchedArray.count == 0 {
                print("fetchedArray.count == 0")
                
                // If fetched array is empty, then this is the first fetch call and resources should be updated
                resources = try NSMutableArray(array: managedContext.fetch(fetchRequest))
            } else if ((fetchedArray[0] as NSManagedObject).value(forKey: "cloudkitFetched") as! Bool) {
                print("!((fetchedArray[0] as NSManagedObject).value(forKey: \"cloudkitFetched\") as! Bool)")
                
                // If the first instance of the entity "Fetched" is true then we are safe to query from CoreData
                resources = try NSMutableArray(array: managedContext.fetch(fetchRequest))
            } else {
                // If the first instance of the entity "Fetched" is false then we are not safe to query from CoreData
                //resources = []
                resources = try NSMutableArray(array: managedContext.fetch(fetchRequest))
            }
            print("new resources count \(String(describing: resources?.count))")
            
            print("resources fetched")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    public func getCoreDataArray(forEntityName entity: String) throws -> [NSManagedObject] {
        let fetchedArray: [NSManagedObject]
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        do {
            fetchedArray = try managedContext.fetch(fetchRequest)
            return fetchedArray
        } catch let error as NSError {
            throw error
        }
    }
    
    public func setValue(forEntityName entity: String, forKey key: String, forValue value: Any) {
        let entity = NSEntityDescription.entity(forEntityName: entity, in: managedContext)!
        
        let fetched = NSManagedObject(entity: entity, insertInto: managedContext)
        
        // COULD THIS CAUSE AN ERROR? -If value is a different type than defined in the database?
        fetched.setValue(value, forKey: key)
    }
    
    public func setValue(forNSManagedObject object: NSManagedObject, forValue value: Any, forKey key: String) {
        // COULD THIS CAUSE AN ERROR? -If value is a different type than defined in the database?
        object.setValue(value, forKey: key)
    }
    
    // Saves either video or image data into the "VideoPhotoBundle" entity to CoreData
    public func save(forURL url: URL, forName name: String, withImages hasImages: Bool) {
        print("saved \(name)")
        
        let entity =
            NSEntityDescription.entity(forEntityName: "VideoPhotoBundle",
                                       in: managedContext)!
        
        if hasImages {
            // Creates a new NSManagedObject and inserts it into the persistent container
            let videoPhotoBundle = NSManagedObject(entity: entity,
                                                   insertInto: managedContext)
            
            // Sets the value of the created NSManagedObject for key name and photo
            videoPhotoBundle.setValue(name, forKeyPath: "name")
            videoPhotoBundle.setValue(NSData(contentsOf: url), forKey: "photo")
        } else {
            // This expects the image associated with the video to have already been queried and saved
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VideoPhotoBundle")
            
            let resources: [NSManagedObject]
            
            do {
                // Fetches the NSManagedObjects saved in CoreData
                resources = try managedContext.fetch(fetchRequest)
                print("new resources count \(String(describing: resources.count))")
                print("resources fetched")
                
                // Loops through NSManagedObjects to find the correct object to save the video to
                for dataObject in resources {
                    var found = false
                        print("dataObject name: \((dataObject).value(forKey: "name") as! String)")
                        print("parameter name: \(name)")
                        if (dataObject).value(forKey: "name") as! String == name {
                            
                            do {
                                try (dataObject).setValue(NSData(contentsOf: url, options: [.uncached]), forKey: "video")
                                
                            } catch {
                                print("couldn't process video")
                                
                            }
                            //do {
//                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//                                let destinationPath = documentsPath + "/filename.mp4"
//                                //try FileManager.default.createFile(atPath: destinationPath, contents: Data(contentsOf: url), attributes: nil)
//
//                                //let data = NSData()
//
//                                // This line creates a generic filename based on UUID, but you may want to use your own
//                                // The extension must match with the AVFileType enum
//                                //let path = NSTemporaryDirectory() + url.uuidString + ".mp4"
//                                let outputURL = URL.init(fileURLWithPath: documentsPath)
//                                let urlAsset = AVURLAsset(url: outputURL)
//                                // You can change the presetName value to obtain different results
//                                if let exportSession = AVAssetExportSession(asset: urlAsset,
//                                                                            presetName: AVAssetExportPresetMediumQuality) {
//                                    exportSession.outputURL = outputURL
//                                    // Changing the AVFileType enum gives you different options with
//                                    // varying size and quality. Just ensure that the file extension
//                                    // aligns with your choice
//                                    exportSession.outputFileType = AVFileType.mp4
//                                    exportSession.exportAsynchronously {
//                                        switch exportSession.status {
//                                        case .unknown:
//                                            print("exportSession.status: unknown)")
//                                            break
//                                        case .waiting:
//                                            print("exportSession.status: waiting")
//                                            break
//                                        case .exporting:
//                                            print("exportSession.status: exporting")
//                                            break
//                                        case .completed:
//                                            // This code only exists to provide the file size after compression. Should remove this from production code
////                                            do {
////                                                let data = try Data(contentsOf: outputFileURL)
////                                                print("File size after compression: \(Double(data.count / 1048576)) mb")
////                                            } catch {
////                                                print("Error: \(error)")
////                                            }
//                                            print("compression complete")
//                                            do {
//                                                try (dataObject).setValue(NSData(contentsOf: exportSession.outputURL!, options: [.uncached]), forKey: "video")
//                                            } catch {
//                                                print("couldn't process video")
//                                            }
//                                        case .failed:
//                                            print("exportSession.status: failed")
//                                            break
//                                        case .cancelled:
//                                            print("exportSession.status: cancelled")
//                                            break
//                                        }
//                                    }
                            
                                //} else {
                                    //print("Couldn't create exportSession")
                            //}
                                //et zipFilePath = try Zip.quickZipFiles([destinationPath], fileName: "archive")
                            //} catch {
                                //print("couldn't process video")
                            //}
                            
                            
                            found = true
                        }
                    if found {
                        break
                    }
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            return
        }
    }
    
    // Deletes all records for a given entity
    public func batchDeleteRecords(forEntityName entity: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        //let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            //try managedContext.execute(batchDeleteRequest)
            let results = try managedContext.fetch(fetchRequest)
            
            for managedObject in results {
                let managedObjectData: NSManagedObject = managedObject as! NSManagedObject
                managedContext.delete(managedObjectData)
            }
            //try managedContext.save()
            print("records deleted")
        } catch {
            print("Error - batchDeleteRequest could not be handled")
        }
    }
}
