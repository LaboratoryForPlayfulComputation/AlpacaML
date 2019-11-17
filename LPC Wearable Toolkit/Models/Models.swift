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

public class Models {
    
    var managedModels: [Model] = []
    
    public struct Constants {
        static let NONE_LABEL = "None"
    }
    
    init() {
        managedModels = fetchAll()
    }
    
    func fetchAll() -> [Model] {
        var fetchedModels: [Model] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Model")
        
        //3
        do {
            fetchedModels = try managedContext.fetch(fetchRequest) as? [Model] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedModels
    }
    
    func count() -> Int {
        return managedModels.count
    }
    
    func objectAtIndex(i: Int) -> NSManagedObject {
        return managedModels[i]
    }
    
    func save(name: String, modelDescription: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Model", in: managedContext)!
        let model = Model(entity: entity, insertInto: managedContext)
        
        model.name = name
        model.notes = modelDescription
        model.labels = []
        model.labels!.append(Constants.NONE_LABEL)
        
        do {
            try managedContext.save()
            managedModels.append(model)
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
