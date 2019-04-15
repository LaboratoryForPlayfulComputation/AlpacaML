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
    
    func countAll(sport: String) -> Int {
        return fetch(sport: sport).count
    }
    
    func fetch(sport: String) -> [Video] {
        var videos: [Video] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Video")
        
        let sportPredicate = NSPredicate(format: "sport = %@", sport)
        fetchRequest.predicate = sportPredicate
        
        //3
        do {
            videos = try managedContext.fetch(fetchRequest) as? [Video] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        //let test = fetchAll()[0].sport
        return videos
    }
    
    func fetchAll() -> [Video] {
        var fetchedSports: [Video] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Video")
        
        //3
        do {
            fetchedSports = try managedContext.fetch(fetchRequest) as? [Video] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedSports
    }
    
    func save(name: String, url: String, accelerations: [Acceleration]) -> Video {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return Video()
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Video", in: managedContext)!
        let video = Video(entity: entity, insertInto: managedContext)
        let min_ts = accelerations.min(by: {acc1, acc2 in acc1.timestamp < acc2.timestamp})?.timestamp
        video.setValue(1, forKeyPath: "id")
        video.setValue(name, forKeyPath: "sport")
        video.setValue(url, forKey: "url")
        video.setValue(min_ts, forKey: "min_ts")

        video.accelerations = NSSet(array: accelerations)
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
