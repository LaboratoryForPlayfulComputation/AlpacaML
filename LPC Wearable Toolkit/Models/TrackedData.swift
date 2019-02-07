//
//  Tracker.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 12/7/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import CoreData

class TrackedData: NSObject {

    var managedData: [Tracker] = []
    
    func fetchAll() -> [Tracker] {
        var fetchedData: [Tracker] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Tracker")
        
        //3
        do {
            fetchedData = try managedContext.fetch(fetchRequest) as? [Tracker] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedData
    }
    
    //
    func save(button: String, contextName: String, metadata1: String, metadata2: String, ts: Double) -> Tracker? {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Tracker",
                                       in: managedContext)!
        
        let tracker = Tracker(entity: entity, insertInto: managedContext)
        
        // 3
        
        tracker.setValue(button, forKeyPath: "buttonName")
        tracker.setValue(contextName, forKeyPath: "contextName")
        tracker.setValue(metadata1, forKeyPath: "metadata1")
        tracker.setValue(metadata2, forKey: "metadata2")
        tracker.setValue(ts, forKey: "timestamp")
        
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return tracker
    }
}
