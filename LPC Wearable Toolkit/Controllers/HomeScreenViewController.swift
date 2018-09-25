//
//  BluetoothConnectViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/5/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

class HomeScreenViewController: UIViewController {
    
    var microbitStore: Peripherals!
    var lastUsedMicrobitName: String!
    
    @IBOutlet weak var microbitNameLabel: UILabel!
    @IBOutlet weak var enterButton: UIButton!
    
    var connectedToLastMicrobit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enterButton.isEnabled = false
        
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
    
    @objc func onDidDiscoverPeripheral(_ notification: Notification) {
        print("Devices found: \(BluetoothStore.shared.devicesFound.count)")
        BluetoothStore.shared.connectToMicrobitWithName(name: lastUsedMicrobitName)
    }
    
    @objc func onDidConnectToPeripheral(_ notification: Notification) {
        print("Connected to peripheral")
        microbitNameLabel.text = lastUsedMicrobitName
        enterButton.isEnabled = true
        enterButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
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
    }
    
}

