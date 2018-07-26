//
//  CoreDataGesture.swift
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 7/12/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Gestures {
    
    func fetch(sport: String, gesture: String) -> [Gesture] {
        var gestures: [Gesture] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Gesture")

        //3
        do {
            gestures = try managedContext.fetch(fetchRequest) as? [Gesture] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return gestures
    }
    

    func save(id: Int64, gesture: String, rating: String,sport: String, start_ts: Double, stop_ts: Double ) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Gesture",
                                       in: managedContext)!
        
        let acceleration_ = NSManagedObject(entity: entity,
                                            insertInto: managedContext)
        
        // 3
        
        acceleration_.setValue(id, forKeyPath: "accelerationID")
        acceleration_.setValue(gesture, forKeyPath: "gesture")
        acceleration_.setValue(rating, forKeyPath: "rating")
        acceleration_.setValue(sport, forKey: "sport")
        acceleration_.setValue(start_ts, forKey: "start_ts")
        acceleration_.setValue(stop_ts, forKey: "stop_ts")
        
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func fetchAll() -> [NSManagedObject] {
        var fetchedGestures: [NSManagedObject] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Gesture")
        
        //3
        do {
            fetchedGestures = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedGestures
    }
    
    func deleteAllData(entity: String) {
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
