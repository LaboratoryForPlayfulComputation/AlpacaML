//
//  Sport.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/18/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Sports {
    
    var managedSports: [NSManagedObject] = []
    
    init() {
        managedSports = fetchAll()
    }
    
    func fetchAll() -> [NSManagedObject] {
        var fetchedSports: [NSManagedObject] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Sport")
        
        //3
        do {
            fetchedSports = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedSports
    }
    
    func count() -> Int {
        return managedSports.count
    }
    
    func objectAtIndex(i: Int) -> NSManagedObject {
        return managedSports[i]
    }
    
    func save(name: String, sportDescription: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Sport", in: managedContext)!
        let sport = NSManagedObject(entity: entity, insertInto: managedContext)
        
        sport.setValue(name, forKeyPath: "name")
        sport.setValue(sportDescription, forKey: "notes")
        
        do {
            try managedContext.save()
            managedSports.append(sport)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
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
