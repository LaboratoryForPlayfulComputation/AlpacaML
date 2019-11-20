//
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 7/12/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Segments {
    
    var managedSegments: [Segment] = []
    
    init() {
        managedSegments = fetchAll()
    }
    
    func save(id: Int64, model: Model, rating: String, start_ts: Double, stop_ts: Double, inTrainingSet: Bool, video: Video ) -> Segment {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return Segment()
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Segment",
                                       in: managedContext)!
        
        let segment = Segment(entity: entity,
                                            insertInto: managedContext)
        
        // 3
        
        segment.setValue(id, forKeyPath: "accelerationID")
        segment.setValue(rating, forKeyPath: "rating")
        segment.setValue(start_ts, forKey: "start_ts")
        segment.setValue(stop_ts, forKey: "stop_ts")
        segment.setValue(inTrainingSet, forKey: "inTrainingSet")
        
        segment.video = video
        segment.model = model
        // 4
        do {
            try managedContext.save()
            return segment
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return Segment()
    }
    
    func fetch(model: Model, trainingSet: Bool) -> [Segment] {
        let segments = model.segments.unsafelyUnwrapped.allObjects as? [Segment] ?? []
        return segments.filter({$0.inTrainingSet})
    }
    
    func fetchAll() -> [Segment] {
        var fetchedSegments: [Segment] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Segment")
        
        //3
        do {
            fetchedSegments = try managedContext.fetch(fetchRequest) as? [Segment] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedSegments
    }
    
    func deleteOne(segment: Segment) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.delete(segment)
        print("Deleted segment")
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
