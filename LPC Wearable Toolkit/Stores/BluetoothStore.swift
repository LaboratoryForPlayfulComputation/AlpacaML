//
//  BluetoothStore.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/24/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothStore: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothStore()
    
    // ACCELEROMETER SERVICE
    let AccelerometerServiceUUID = CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    // Notify,Read
    let AccelerometerDataCharacteristicUUID = CBUUID(string:"E95DCA4B-251D-470A-A062-FA1922DFA9A8")
    var accelerometerDataCharacteristic:CBCharacteristic?
    // Write
    let AccelerometerPeriodCharacteristicUUID = CBUUID(string:"E95DFB24-251D-470A-A062-FA1922DFA9A8")
    var accelerometerPeriodCharacteristic:CBCharacteristic?
    
    var centralManager: CBCentralManager!
    var devicesFound:[CBPeripheral] = []
    var microbit: CBPeripheral!
    // this should update or something
    var centralManagerState = ""
    var connectionState = "Not Connected"
    var accelerationBuffer: [(Double, Double, Double)] = []
    
    let ACCELEROMETER_PERIOD = 60.0
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func getConnectionState() -> String {
        return connectionState
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // maybe we can do something to the label here idk.
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
            centralManagerState = "Unknown"
        case .resetting:
            print("central.state is .resetting")
            centralManagerState = "Resetting"
        case .unsupported:
            print("central.state is .unsupported")
            centralManagerState = "Unsupported"
        case .unauthorized:
            print("central.state is .unauthorized")
            centralManagerState = "Unauthorized"
        case .poweredOff:
            print("central.state is .poweredOff")
            centralManagerState = "Powered Off"
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManagerState = "Powered On"
            centralManager.scanForPeripherals(withServices: nil,options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
        NotificationCenter.default.post(name: BluetoothNotification.didUpdateState.notification, object: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        
        if let deviceName = peripheral.name {
            print("Possible device detected: \(peripheral.name ?? "")")
            if deviceName.contains("micro:bit") {
                devicesFound.append(peripheral)
            }
        }
        print(devicesFound.count)
        NotificationCenter.default.post(name: BluetoothNotification.didDiscoverPeripheral.notification, object: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = "\(microbit.name ?? "")"
        peripheral.discoverServices([AccelerometerServiceUUID])
        NotificationCenter.default.post(name: BluetoothNotification.didConnectToPeripheral.notification, object: nil)
    }
    
    // MARK : Bluetooth - Peripheral functions
    // we'll probably want to let the user know this happened
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for s in peripheral.services! {
            let service = s as CBService
            print("Service discovered: \(service.description)")
            peripheral.discoverCharacteristics(nil, for: service)
            connectionState = "Discovered services"
        }
        NotificationCenter.default.post(name: BluetoothNotification.didDiscoverServices.notification, object: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            print("No characteristic for service")
            return
        }
        
        for characteristic in characteristics {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == AccelerometerDataCharacteristicUUID {
                print("Accelerometer data characteristic found")
                accelerometerDataCharacteristic = thisCharacteristic
                peripheral.setNotifyValue(true, for: thisCharacteristic)
            }
        }
        connectionState = "Discovered characteristics"
        NotificationCenter.default.post(name: BluetoothNotification.didDiscoverCharacteristics.notification, object: nil)
    }
    // https://jayeshkawli.ghost.io/pass-data-with-ios-notifications-swift-3-0/
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == AccelerometerDataCharacteristicUUID {
            struct AccelerometerData {
                let x: Int16
                let y: Int16
                let z: Int16
            }
            let dataBytes = characteristic.value!
            let accelerometerData = dataBytes.withUnsafeBytes {(int16Ptr: UnsafePointer<Int16>)->AccelerometerData in
                AccelerometerData(x: Int16(littleEndian: int16Ptr[0]),
                                  y: Int16(littleEndian: int16Ptr[1]),
                                  z: Int16(littleEndian: int16Ptr[2]))
            }
            accelerationBuffer.append((Double(accelerometerData.x), Double(accelerometerData.y), Double(accelerometerData.z)))
            if accelerationBuffer.count > 5 {
                NotificationCenter.default.post(name: BluetoothNotification.didUpdateValueFor.notification, object: nil, userInfo: ["acceleration":accelerationBuffer])
                accelerationBuffer = []
            }
            
        }
    }
    
    func getAccelerometerDataFromMicrobit() throws -> (Double,Double,Double) {
        struct AccelerometerData {
            let x: Int16
            let y: Int16
            let z: Int16
        }
        guard let dataBytes = accelerometerDataCharacteristic?.value! else {
            throw BluetoothConnectError.NoValueForCharacteristic
        }
        let accelerometerData = dataBytes.withUnsafeBytes {(int16Ptr: UnsafePointer<Int16>)->AccelerometerData in
            AccelerometerData(x: Int16(littleEndian: int16Ptr[0]),
                              y: Int16(littleEndian: int16Ptr[1]),
                              z: Int16(littleEndian: int16Ptr[2]))
        }
        print("Point: \(accelerometerData.x), \(accelerometerData.y), \(accelerometerData.z)")
        return (Double(accelerometerData.x),Double(accelerometerData.y),Double(accelerometerData.z))
    }
    
    func connectToMicrobitAtRow(row: Int) -> Bool {
        if devicesFound.count > 0 {
            microbit = devicesFound[row]
            microbit.delegate = self
            centralManager.stopScan()
            centralManager.connect(microbit)
            NotificationCenter.default.post(name: BluetoothNotification.didConnectToPeripheral.notification, object: nil)
            return true
        } else {
            return false
        }
    }
    
    func connectToMicrobitWithName(name: String) {
        if devicesFound.count > 0 {
            for device in devicesFound {
                if device.name == name {
                    microbit = device
                    microbit.delegate = self
                    centralManager.stopScan()
                    centralManager.connect(microbit)
                    NotificationCenter.default.post(name: BluetoothNotification.didConnectToPeripheral.notification, object: nil)
                }
            }
        }
    }
    
    func getCentralManagerState() -> String {
        return centralManagerState
    }
    
    func isMicrobitConnected() -> Bool {
        return microbit.state == CBPeripheralState.connected
    }
    
}

enum BluetoothConnectError: Error {
    case NoValueForCharacteristic
    case NoCharacteristicForService
}
enum BluetoothNotification: String {
    case didDiscoverPeripheral = "didDiscoverPeripheral"
    case didConnectToPeripheral = "didConnectToPeripheral"
    case didUpdateState = "didUpdateState"
    case didDiscoverServices = "didDiscoverServices"
    case didDiscoverCharacteristics = "didDiscoverCharacteristics"
    case didUpdateValueFor = "didUpdateValueFor"
    
    var notification : Notification.Name {
        return Notification.Name(rawValue: self.rawValue)
    }
}
