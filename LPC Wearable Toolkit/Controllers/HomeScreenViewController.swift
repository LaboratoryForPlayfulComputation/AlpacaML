//
//  BluetoothConnectViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/5/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import Photos

class HomeScreenViewController: UIViewController {
    
    var microbitStore: Peripherals!
    var lastUsedMicrobitName: String!
    var trackedData: TrackedData = TrackedData()
    
    
    @IBOutlet weak var microbitNameLabel: UILabel!
    @IBOutlet weak var enterButton: UIButton!
    
    
    var connectedToLastMicrobit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enterButton.isEnabled = false
        // request status: https://stackoverflow.com/questions/39893918/xcode-8-swift-3-phphotolibrary-requestauthorization-crashing
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("authorized")
        case .denied:
            print("denied") // it is denied
        case .notDetermined:
            print("notDetermined")
            PHPhotoLibrary.requestAuthorization({(status) -> Void in
                switch status {
                case .authorized:
                        print("Authorized!")
                case .denied, .restricted:
                        print("Denied or Restricted")
                case .notDetermined: break
                }
            })
        case .restricted:
            print("restricted")
        }
        microbitStore = Peripherals()
        lastUsedMicrobitName = microbitStore.fetchLastConnected()
        print("lastUsedMicrobitName: \(lastUsedMicrobitName)")
        NotificationCenter.default.addObserver(self, selector: #selector(onDidDiscoverPeripheral(_:)), name: BluetoothNotification.didDiscoverPeripheral.notification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidConnectToPeripheral(_:)), name: BluetoothNotification.didConnectToPeripheral.notification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func deleteFromCoredata(_ sender: Any) {
        let alert = UIAlertController(title: "Wait!", message: "Are you sure you want to clear all data?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes, delete", style: .destructive, handler: { [weak alert] (_) in
            self.microbitStore.deleteAllData(entity: "Acceleration")
            self.microbitStore.deleteAllData(entity: "Segment")
            self.microbitStore.deleteAllData(entity: "Sport")
            self.microbitStore.deleteAllData(entity: "Video")
            self.microbitStore.deleteAllData(entity: "Action")
        }))
        
        alert.addAction(UIAlertAction(title: "No, go back", style: .default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func onDidDiscoverPeripheral(_ notification: Notification) {
        print("Devices found: \(BluetoothStore.shared.devicesFound.count)")
        BluetoothStore.shared.connectToMicrobitWithName(name: lastUsedMicrobitName)
        trackedData.save(button: "Microbit Discover", contextName: "HomeScreen", metadata1: lastUsedMicrobitName, metadata2: "", ts: NSDate().timeIntervalSinceReferenceDate)
    }
    
    @objc func onDidConnectToPeripheral(_ notification: Notification) {
        print("Connected to peripheral")
        microbitNameLabel.text = lastUsedMicrobitName
        enterButton.isEnabled = true
        enterButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
        trackedData.save(button: "Microbit Connect", contextName: "HomeScreen", metadata1: lastUsedMicrobitName, metadata2: "", ts: NSDate().timeIntervalSinceReferenceDate)
    }
}

extension HomeScreenViewController {
    @IBAction func cancelToHomeScreenViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveMicrobit(_ segue: UIStoryboardSegue) {
        enterButton.isEnabled = true
        enterButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
        let connectedMicrobit = BluetoothStore.shared.microbit
        let existingMicrobitNames = microbitStore.fetchAll().map({ $0.name })
        if !existingMicrobitNames.contains(connectedMicrobit?.name) {
            microbitStore.save(name: (connectedMicrobit?.name)!, last_connected: NSDate().timeIntervalSince1970, connected: true, has_accelerometer: true)
            print("Saved microbit \(connectedMicrobit?.name ?? "None") to CoreData")
        }
        microbitNameLabel.text = connectedMicrobit?.name
        self.trackedData.save(button: "Microbit Saved", contextName: "HomeScreen", metadata1: (connectedMicrobit?.name)!, metadata2: "", ts: NSDate().timeIntervalSinceReferenceDate)
    }
    
}

