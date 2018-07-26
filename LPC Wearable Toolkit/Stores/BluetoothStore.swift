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
    var centralManagerState = ""
    var connectionState = "Not Connected"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func getCentralManagerState() -> String {
        return centralManagerState
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
        // !!!!!!! microbitPicker.reloadAllComponents()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = "Connected to \(microbit.name ?? "")"
        peripheral.discoverServices([AccelerometerServiceUUID])
    }
    
    // MARK : Bluetooth - Peripheral functions
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for s in peripheral.services! {
            let service = s as CBService
            print("Service discovered: \(service.description)")
            peripheral.discoverCharacteristics(nil, for: service)
            connectionState = "Discovered services"
        }
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
        return (Double(accelerometerData.x),Double(accelerometerData.y),Double(accelerometerData.z))
    }

    func connectToMicrobitAtRow(row: Int) {
        if devicesFound.count > 0 {
            microbit = devicesFound[row]
            microbit.delegate = self
            centralManager.stopScan()
            centralManager.connect(microbit)
        } else {
            connectionState = "No micro:bits present"
        }
    }
}
