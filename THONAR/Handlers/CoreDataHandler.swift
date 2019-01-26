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

let appDelegate = UIApplication.shared.delegate as? AppDelegate
let managedContext = appDelegate!.persistentContainer.viewContext

public class CoreDataHandler {
    public func getData(forNSManagedObject resource: Any, forKey key: String) -> Data? {
        return ((resource as? NSManagedObject)?.value(forKey: key) as! NSData) as Data?
    }
    
    public func getStringData(forNSManagedObject resource: Any, forKey key: String) -> String? {
        return (resource as? NSManagedObject)?.value(forKey: key) as? String
    }
    
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
                resources = try NSMutableArray(array: managedContext.fetch(fetchRequest))
            } else if ((fetchedArray[0] as NSManagedObject).value(forKey: "cloudkitFetched") as! Bool) {
                print("!((fetchedArray[0] as NSManagedObject).value(forKey: \"cloudkitFetched\") as! Bool)")
                resources = try NSMutableArray(array: managedContext.fetch(fetchRequest))
            } else {
                resources = []
            }
            print("new resources count \(String(describing: resources?.count))")
            
            print("resources fetched")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    public func save(forURL url: URL, forName name: String, withImages hasImages: Bool) {
        print("saved \(name)")
        
        let entity =
            NSEntityDescription.entity(forEntityName: "VideoPhotoBundle",
                                       in: managedContext)!
        
        
        
        if hasImages {
            let videoPhotoBundle = NSManagedObject(entity: entity,
                                                   insertInto: managedContext)
            
            videoPhotoBundle.setValue(name, forKeyPath: "name")
            videoPhotoBundle.setValue(NSData(contentsOf: url), forKey: "photo")
        } else {
            // This expects the image associated with the video to have already been queried and saved
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VideoPhotoBundle")
            
            let resources: [NSManagedObject]
            
            //3
            do {
                resources = try managedContext.fetch(fetchRequest)
                print("new resources count \(String(describing: resources.count))")
                print("resources fetched")
                
                for dataObject in resources {
                    //let managedObject = dataObject as! NSManagedObject
                    print("dataObject name: \((dataObject).value(forKey: "name") as! String)")
                    print("parameter name: \(name)")
                    if (dataObject).value(forKey: "name") as! String == name {
                        (dataObject).setValue(NSData(contentsOf: url), forKey: "video")
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
        
        //print("resources.count after saved: \(String(describing: resources.count))")
    }
    
    public func batchDeleteRecords(forEntityName entity: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(batchDeleteRequest)
        } catch {
            print("Error - batchDeleteRequest could not be handled")
        }
    }
}
