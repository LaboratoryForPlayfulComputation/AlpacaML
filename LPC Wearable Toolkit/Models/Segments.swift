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
    
    func countAll(sport: String, action: String) -> Int {
        return fetchAllFor(sport: sport, action: action).count
    }
    
    func fetch(sport: String, action: String, trainingSet: Bool) -> [Segment] {
        var segments: [Segment] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Segment")
        var sportActionPredicate: NSPredicate!
        if trainingSet {
            print("Fetching segments in training set")
            sportActionPredicate = NSPredicate(format: "sport = %@ && action = %@ && inTrainingSet = true", sport, action)
        } else {
            print("Fetching all segments")
            sportActionPredicate = NSPredicate(format:"sport = %@ && action = %@", sport, action)
        }
        fetchRequest.predicate = sportActionPredicate
        
        //3
        do {
            segments = try managedContext.fetch(fetchRequest) as? [Segment] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        print("Fetched \(segments.count) segments")
        return segments
    }
    
    func fetchAllFor(sport: String, action: String) -> [Segment] {
        var segments: [Segment] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Segment")
        
        let actionPredicate = NSPredicate(format: "sport = %@ && action = %@", sport, action)
        fetchRequest.predicate = actionPredicate
        
        //3
        do {
            segments = try managedContext.fetch(fetchRequest) as? [Segment] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return segments
    }
    
    func fetchAllFor(sport: String) -> [Segment] {
        var segments: [Segment] = []
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Segment")
        
        let actionPredicate = NSPredicate(format: "sport = %@", sport)
        fetchRequest.predicate = actionPredicate
        
        //3
        do {
            segments = try managedContext.fetch(fetchRequest) as? [Segment] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return segments
    }
    
    func save(id: Int64, action: String, rating: String,sport: String, start_ts: Double, stop_ts: Double, inTrainingSet: Bool, video: Video ) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
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
        segment.setValue(action, forKeyPath: "action")
        segment.setValue(rating, forKeyPath: "rating")
        segment.setValue(sport, forKey: "sport")
        segment.setValue(start_ts, forKey: "start_ts")
        segment.setValue(stop_ts, forKey: "stop_ts")
        segment.setValue(inTrainingSet, forKey: "inTrainingSet")
        
        segment.video = video
        
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
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
