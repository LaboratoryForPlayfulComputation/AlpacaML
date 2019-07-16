//
//  BluetoothConnectViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/9/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

class BluetoothConnectViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var microbitPicker: UIPickerView!
    @IBOutlet weak var bluetoothStatus: UILabel!
    @IBOutlet weak var microbitNameLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var connectButton: UIButton!
    
    var selectedMicrobit = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.microbitPicker.delegate = self
        self.microbitPicker.dataSource = self
        doneButton.isEnabled = false
        connectButton.isEnabled = false
        bluetoothStatus.text = BluetoothStore.shared.getCentralManagerState()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidDiscoverPeripheral(_:)), name: BluetoothNotification.didDiscoverPeripheral.notification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidConnectToPeripheral(_:)), name: BluetoothNotification.didConnectToPeripheral.notification, object: nil)
        if(BluetoothStore.shared.devicesFound.count > 0) {
            self.pickerView(microbitPicker, didSelectRow: 0, inComponent: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(BluetoothNotification.didDiscoverPeripheral.notification)
        NotificationCenter.default.removeObserver(BluetoothNotification.didConnectToPeripheral.notification)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return BluetoothStore.shared.devicesFound.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return BluetoothStore.shared.devicesFound[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMicrobit = row
        connectButton.isEnabled = true
    }
    
    @IBAction func connectToMicrobit(_ sender: Any) {
        if ( BluetoothStore.shared.devicesFound.count > 0 && (selectedMicrobit >= 0)) {
            let connected = BluetoothStore.shared.connectToMicrobitAtRow(row: selectedMicrobit)
            let microbitName = BluetoothStore.shared.microbit.name // check to make sure this is correct
            if connected {
                microbitNameLabel.text = microbitName
                doneButton.isEnabled = true
            } else {
                // Set label to no microbits found
                microbitNameLabel.text = "No micro:bits present"
            }
        }
    }
    
    @objc func onDidDiscoverPeripheral(_ notification: Notification) {
        print("Devices found: \(BluetoothStore.shared.devicesFound.count)")
        microbitPicker.reloadAllComponents()
    }
    
    @objc func onDidConnectToPeripheral(_ notification: Notification) {
        microbitNameLabel.text = BluetoothStore.shared.microbit.name
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
