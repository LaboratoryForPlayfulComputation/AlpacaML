//
//  ClassificationViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/24/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth

class ClassificationViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UIPickerViewDelegate, UIPickerViewDataSource, ChartViewDelegate {
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var microbitPicker: UIPickerView!
    
    // ACCELEROMETER SERVICE
    let AccelerometerServiceUUID = CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    // Notify,Read
    let AccelerometerDataCharacteristicUUID = CBUUID(string:"E95DCA4B-251D-470A-A062-FA1922DFA9A8")
    var accelerometerDataCharacteristic:CBCharacteristic?
    // Write
    let AccelerometerPeriodCharacteristicUUID = CBUUID(string:"E95DFB24-251D-470A-A062-FA1922DFA9A8")
    var accelerometerPeriodCharacteristic:CBCharacteristic?
    let ACCELEROMETER_PERIOD = 60.0
    
    var centralManager: CBCentralManager!
    var devicesFound:[CBPeripheral] = []
    var microbit: CBPeripheral!
    
    var accelerationStore = Accelerations()
    var gestureStore = Gestures()
    var gestureList:[Gesture]!
    
    var newAccelerations: [(Double,Double,Double)] = []
    var xAccelerations: [ChartDataEntry]!
    var yAccelerations: [ChartDataEntry]!
    var zAccelerations: [ChartDataEntry]!
    var isRecording = false
    var chunkSize = 0
    let dtw = DTW()

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.lineChart.delegate = self
        self.microbitPicker.delegate = self
        self.microbitPicker.dataSource = self
        self.gestureList = gestureStore.fetch(sport: "Sportsball", gesture: "Gesture")
        let min_ts = accelerationStore.getMinTimestamp()
        for gesture in gestureList {
            let adjustedStart = gesture.start_ts/ACCELEROMETER_PERIOD + min_ts
            let adjustedStop = gesture.stop_ts/ACCELEROMETER_PERIOD + min_ts
            let accelerations = self.accelerationStore.fetch(sport: "Sportsball", start_ts: adjustedStart, stop_ts: adjustedStop)
            let accelerationAsDoubles = accelerations.map({acc in return (acc.xAcceleration, acc.yAcceleration, acc.zAcceleration)})
            dtw.addToTrainingSet(label: gesture.rating!, data: accelerationAsDoubles)
        }
        chunkSize = Int(self.getMaxSegmentLength())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralManager.cancelPeripheralConnection(microbit)
    }
    
    // MARK: UI Components

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return devicesFound.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return devicesFound[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Connect to microbit
        print("Row selected")
        if devicesFound.count > 0 {
            microbit = devicesFound[row]
            microbit.delegate = self
            centralManager.stopScan()
            centralManager.connect(microbit)
        } else {
            print("No micro:bits present")
        }
    }
    
    @IBAction func toggleCapture(_ sender: UIButton) {
        isRecording = !isRecording
    }
    
    // MARK: Bluetooth - Central Manager functions
    // https://www.raywenderlich.com/177848/core-bluetooth-tutorial-for-ios-heart-rate-monitor
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // maybe we can do something to the label here idk.
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
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
        microbitPicker.reloadAllComponents()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([AccelerometerServiceUUID])
    }
    
    // MARK : Bluetooth - Peripheral functions
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for s in peripheral.services! {
            let service = s as CBService
            print("Service discovered: \(service.description)")
            peripheral.discoverCharacteristics(nil, for: service)
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
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if isRecording {
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
                newAccelerations.append((Double(accelerometerData.x), Double(accelerometerData.y), Double(accelerometerData.z)))
                accelerationStore.save(x: Double(accelerometerData.x), y: Double(accelerometerData.y), z: Double(accelerometerData.z), timestamp: NSDate().timeIntervalSinceReferenceDate, sport: "TestSport", id: 1)
                print("Number stored: \(accelerationStore.fetch(sport: "TestSport").count)")
                updateChart()
                
                if newAccelerations.count > chunkSize {
                    classifyChunk()
                }
            }
        }
    }
    
    func classifyChunk() {
        let maxIndex = newAccelerations.count - 1
        let test = newAccelerations[(maxIndex-chunkSize)..<maxIndex]
        let classification = dtw.classify(test: Array(test))
        classificationLabel.text = classification
        // make it also talk
    }
    
    // MARK - Chart functions
    
    private func updateChart() {
        xAccelerations = [ChartDataEntry]()
        yAccelerations = [ChartDataEntry]()
        zAccelerations = [ChartDataEntry]()
        
        for i in 0..<newAccelerations.count {
            xAccelerations.append(ChartDataEntry(x: Double(i), y: newAccelerations[i].0))
            yAccelerations.append(ChartDataEntry(x: Double(i), y: newAccelerations[i].1))
            zAccelerations.append(ChartDataEntry(x: Double(i), y: newAccelerations[i].2))
        }
        
        let xline = LineChartDataSet(values: xAccelerations, label: "X Values")
        xline.drawCirclesEnabled = false
        xline.colors = [NSUIColor.black]
        xline.drawValuesEnabled = false
        
        let yline = LineChartDataSet(values: yAccelerations, label: "Y Values")
        yline.drawValuesEnabled = false
        yline.drawCirclesEnabled = false
        yline.colors = [NSUIColor.blue]
        
        let zline = LineChartDataSet(values: zAccelerations, label: "Z Values")
        zline.drawValuesEnabled = false
        zline.drawCirclesEnabled = false
        zline.colors = [NSUIColor.cyan]
        
        let data = LineChartData()
        data.addDataSet(xline)
        data.addDataSet(yline)
        data.addDataSet(zline)
        lineChart.data = data
        lineChart.setVisibleXRangeMaximum(50)
        lineChart.chartDescription?.text = "Acceleration"
        
        lineChart.data?.notifyDataChanged()
        lineChart.notifyDataSetChanged()
        
        lineChart.moveViewToX(Double(newAccelerations.count - 25))
    }
    
    // MARK - Gesture recognition code
    
    func getMaxSegmentLength() -> Double {
        let gestures = gestureStore.fetch(sport: "Sportsball", gesture: "Gesture")
        let longest = gestures.max(by: {g1, g2 in (g1.stop_ts - g1.start_ts) < (g2.stop_ts - g2.start_ts)} )
        print("Start: \(String(describing: longest?.start_ts)), Stop: \(String(describing: longest?.stop_ts))")
        return (longest?.stop_ts)! - (longest?.start_ts)!
    }
    
}
