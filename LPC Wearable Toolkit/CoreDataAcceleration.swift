//
//  CoreData2.swift
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 7/11/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//
import UIKit
import CoreData

class CoreDataAcceleration {
    
    func fetch(sport: String, start_ts: Int64, stop_ts: Int64) -> [Acceleration] {
        var accelerations: [Acceleration] = []
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return []
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            //2
            let fetchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Acceleration")
        
            let sportPredicate = NSPredicate(format: "sport = %@ && ( timestamp >= %@ && timestamp <= %@)", sport, start_ts, stop_ts)
            fetchRequest.predicate = sportPredicate
        
            let sort = NSSortDescriptor(key: #keyPath(Acceleration.timestamp), ascending: true)
            fetchRequest.sortDescriptors = [sort]
            
            //3
            do {
                accelerations = try managedContext.fetch(fetchRequest) as? [Acceleration] ?? []
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        return accelerations
    }
   
    func fetch(sport: String) -> [Acceleration] {
        var accelerations: [Acceleration] = []
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Acceleration")
        
        let sportPredicate = NSPredicate(format: "sport = %@", sport)
        fetchRequest.predicate = sportPredicate
        
        let sort = NSSortDescriptor(key: #keyPath(Acceleration.timestamp), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        //3
        do {
            accelerations = try managedContext.fetch(fetchRequest) as? [Acceleration] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return accelerations
    }



    

    //
    func save(x: Double, y: Double, z: Double, timestamp: Int, sport: String, id: Int) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Acceleration",
                                       in: managedContext)!
        
        let acceleration_ = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        // 3
        
        acceleration_.setValue(x, forKeyPath: "xAcceleration")
        acceleration_.setValue(y, forKeyPath: "yAcceleration")
        acceleration_.setValue(z, forKeyPath: "zAcceleration")
        acceleration_.setValue(sport, forKey: "sport")
        acceleration_.setValue(timestamp, forKey: "timestamp")
        acceleration_.setValue(id, forKey: "id")
        
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    
}


