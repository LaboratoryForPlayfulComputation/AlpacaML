//
//  Actions.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/12/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Actions {
    var managedActions: [Action] = []
    
    // potentially don't need
    init() {
        managedActions = fetchAll()
    }
    
    func fetch(sport: String) -> [Action] {
        var actions: [Action] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Action")
        
        let actionPredicate = NSPredicate(format: "sport = %@", sport)
        fetchRequest.predicate = actionPredicate
        
        //3
        do {
            actions = try managedContext.fetch(fetchRequest) as? [Action] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return actions
    }
    
    
    func save(name: String, sport: String ) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Action",
                                       in: managedContext)!
        
        let acceleration_ = NSManagedObject(entity: entity,
                                            insertInto: managedContext)
        
        // 3
        
        acceleration_.setValue(name, forKeyPath: "name")
        acceleration_.setValue(sport, forKey: "sport")
        
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        managedActions = fetchAll()
    }
    
    func fetchAll() -> [Action] {
        var fetchedActions: [Action] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Action")
        
        //3
        do {
            fetchedActions = try managedContext.fetch(fetchRequest) as? [Action] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedActions
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
