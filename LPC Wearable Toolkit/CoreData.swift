//
//  CoreData.swift
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 6/14/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import UIKit
import CoreData

/*//MARK ACCELERATION OBJECT//
var period: [NSManagedObject] = []
var timestamp: [NSManagedObject] = []
var xAcceleration: [NSManagedObject] = []
var yAcceleration: [NSManagedObject] = []
var zAcceleration: [NSManagedObject] = []

//MARK GESTURE OBJECT//
var activity: [NSManagedObject] = []
var gesture: [NSManagedObject] = []
var classification: [NSManagedObject] = []
var video: [NSManagedObject] = []

//MARK MLDATA OBJECT//
var enoughData: [NSManagedObject] = []
var modelAlgorithm: [NSManagedObject] = []*/

var Accxyz: [NSManagedObject] = []
var Gestures: [NSManagedObject] = []
var MLDatas: [NSManagedObject] = []

/*let saveAction = UIAlertAction(title: "Save", style: .default) {
    [unowned self] action in
    
    guard let textField = alert.textFields?.first,
        let nameToSave = textField.text else {
            return
    }
    
    self.save(name: nameToSave)
}*/

func save(period_: Double, timestamp_: Double, xData: Double, yData: Double, zData: Double) {
    
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
    
    let acceleration = NSManagedObject(entity: entity,
                                 insertInto: managedContext)
    //MARK GESTURE//
    /*
    let entity2 =
        NSEntityDescription.entity(forEntityName: "Gesture",
                                   in: managedContext)!
    
    let Gesture = NSManagedObject(entity: entity2,
                                       insertInto: managedContext)*/
   /* //MARK MLDATA//
    
    let entity3 =
        NSEntityDescription.entity(forEntityName: "MLData",
                                   in: managedContext)!
    
    let mldata = NSManagedObject(entity: entity3,
                                  insertInto: managedContext)
    */
    // 3
    // MARK ACCELERATION //
    acceleration.setValue(timestamp_, forKeyPath: "timestamp")
    acceleration.setValue(period_, forKeyPath: "period")
    acceleration.setValue(xData, forKeyPath: "xAcceleration")
    acceleration.setValue(yData, forKeyPath: "yAcceleration")
    acceleration.setValue(zData, forKeyPath: "zAcceleration")
    
    /*//MARK GESTURE//
    Gesture.setValue(<#T##value: Any?##Any?#>, forKey: "activity")
    Gesture.setValue(<#T##value: Any?##Any?#>, forKey: "classification")
    Gesture.setValue(<#T##value: Any?##Any?#>, forKey: "gesture")
    Gesture.setValue(<#T##value: Any?##Any?#>, forKey: "video")
    */


    
    // 4
    do {
        try managedContext.save()
        Accxyz.append(acceleration)
       // Gestures.append(Gesture)
       // MLDatas.append(mldata)
    } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
    }
}
