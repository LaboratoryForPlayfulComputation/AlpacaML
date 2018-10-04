//
//  Peripherals.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/5/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Peripherals {
    // should we move the bluetooth stuff in here?
    var managedPeripherals: [Peripheral] = []
    
    init() {
        managedPeripherals = fetchAll()
    }
    
    func fetchAll() -> [Peripheral] {
        var fetchedPeripherals: [Peripheral] = []
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Peripheral")
        
        do {
            fetchedPeripherals = try managedContext.fetch(fetchRequest) as? [Peripheral] ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedPeripherals
    }
    
    func fetchLastConnected() -> String {
        let peripherals: [Peripheral] = self.fetchAll()
        let maxPeripheral = peripherals.max(by: { (p1, p2) in p1.lastConnected < p2.lastConnected })
        if (maxPeripheral != nil) {
            return maxPeripheral!.name!
        } else {
            return ""
        }
    }
    
    func save(name: String, last_connected: Double, connected: Bool, has_accelerometer: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Peripheral", in: managedContext)!
        
        let peripheral = Peripheral(entity: entity, insertInto: managedContext)
        
        peripheral.setValue(name, forKeyPath: "name")
        peripheral.setValue(last_connected, forKeyPath: "lastConnected")
        peripheral.setValue(connected, forKeyPath: "available")
        peripheral.setValue(has_accelerometer, forKey: "accelerationAvailable")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        managedPeripherals = fetchAll()
    }
}
