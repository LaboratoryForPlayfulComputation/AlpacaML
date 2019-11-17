//
//  Videos.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/20/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Videos {
    
    var managedVideos: [NSManagedObject] = []
    
    func countAll(model: Model) -> Int {
        return self.fetch(model: model).count
    }
    
    func fetch(model: Model) -> [Video] {
        let videos = model.videos.unsafelyUnwrapped.allObjects as? [Video] ?? []
        return videos
    }
    
    func save(model: Model, name: String, url: String, accelerations: [Acceleration]) -> Video {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return Video()
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Video", in: managedContext)!
        let video = Video(entity: entity, insertInto: managedContext)
        let min_ts = accelerations.min(by: {acc1, acc2 in acc1.timestamp < acc2.timestamp})?.timestamp
        video.setValue(1, forKeyPath: "id")
        video.setValue(url, forKey: "url")
        video.setValue(min_ts, forKey: "min_ts")
        video.setValue(name, forKey: "name")

        video.accelerations = NSSet(array: accelerations)
        video.model = model
        do {
            try managedContext.save()
            managedVideos.append(video)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return video
    }
    
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedContext.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
}
