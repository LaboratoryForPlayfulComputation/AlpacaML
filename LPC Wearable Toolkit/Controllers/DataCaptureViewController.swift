//
//  DataCaptureViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/19/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreBluetooth
import Photos
//import ExternalAccessory

class DataCaptureViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CustomOverlayDelegate  {
    
    // ACCELEROMETER SERVICE
    let AccelerometerServiceUUID = CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    // Notify,Read
    let AccelerometerDataCharacteristicUUID = CBUUID(string:"E95DCA4B-251D-470A-A062-FA1922DFA9A8")
    var accelerometerDataCharacteristic:CBCharacteristic?
    // Write
    let AccelerometerPeriodCharacteristicUUID = CBUUID(string:"E95DFB24-251D-470A-A062-FA1922DFA9A8")
    var accelerometerPeriodCharacteristic:CBCharacteristic?
    
    @IBOutlet weak var microbitPicker: UIPickerView!
    @IBOutlet weak var connectionLabel: UILabel!
    
    let videoCaptureController = UIImagePickerController()
    var centralManager: CBCentralManager!
    var devicesFound:[CBPeripheral] = []
    var microbit: CBPeripheral!
    var recording = false
    var accelerationObjects:[(Double,Double,Double)] = []
    var accelerationStore = Accelerations()
    var videoStore = Videos()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.microbitPicker.delegate = self
        self.microbitPicker.dataSource = self
        self.accelerationStore.deleteAllData(entity: "Acceleration")
        self.videoStore.deleteAllData(entity: "Video")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            connectionLabel.text = "No micro:bits present"
        }
    }
    
    // MARK: Video
    
    // TODO: use this tutorial to do playback (https://www.ioscreator.com/tutorials/take-video-tutorial-ios8-swift)
    @IBAction func takeVideo(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let customViewController = CustomOverlayViewController()
                let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
                customView.frame = videoCaptureController.view.frame
                customView.delegate = self
                // We really need to change this to AV foundation or make it prettier or something
                videoCaptureController.sourceType = .camera
                videoCaptureController.showsCameraControls = false
                videoCaptureController.mediaTypes = [kUTTypeMovie as String]
                videoCaptureController.delegate = self
                videoCaptureController.videoMaximumDuration = 10.0
            
                videoCaptureController.cameraOverlayView = customView
                present(videoCaptureController, animated: true, completion: {self.videoCaptureController.cameraOverlayView = customView})
            } else {
                print("Camera is not available")
            }
    }
    
    // tutorial: https://stackoverflow.com/questions/29482738/swift-save-video-from-nsurl-to-user-camera-roll
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL
        if let url = urlOfVideo {
            PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)}, completionHandler: {saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            } else if error != nil {
                let alertController = UIAlertController(title: "Your video was not saved", message: error.unsafelyUnwrapped.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
            videoStore.save(name: "Sportsball", url: url.absoluteString!)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func didCancel(overlayView: CustomOverlayView) {
        videoCaptureController.cameraOverlayView?.removeFromSuperview()
        videoCaptureController.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true) {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.readAndSaveAccelerationData), userInfo: nil, repeats: true)
            videoCaptureController.startVideoCapture()
            recording = true
        } else {
            videoCaptureController.stopVideoCapture()
            timer.invalidate()
            recording = false
            videoCaptureController.dismiss(animated: true, completion: nil)
            //Arrow.isHidden = false
        }
    }
    
    @objc func readAndSaveAccelerationData() {
        do {
            let acceleration = try self.getAccelerometerDataFromMicrobit()
            print(acceleration)
            self.accelerationStore.save(x: acceleration.0,y: acceleration.1,z: acceleration.2, timestamp: NSDate().timeIntervalSinceReferenceDate,sport: "Sportball", id: 1)
            print(self.accelerationStore.fetch(sport: "Sportball").count)
            self.accelerationObjects.append(acceleration)
        } catch {
            print("No data available from microbit: \(error)")
        }
    }

    // MARK: Bluetooth - Central Manager functions
    // https://www.raywenderlich.com/177848/core-bluetooth-tutorial-for-ios-heart-rate-monitor
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // maybe we can do something to the label here idk.
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
            connectionLabel.text = "Unknown"
        case .resetting:
            print("central.state is .resetting")
            connectionLabel.text = "Resetting"
        case .unsupported:
            print("central.state is .unsupported")
            connectionLabel.text = "Unsupported"
        case .unauthorized:
            print("central.state is .unauthorized")
            connectionLabel.text = "Unauthorized"
        case .poweredOff:
            print("central.state is .poweredOff")
            connectionLabel.text = "Powered Off"
        case .poweredOn:
            print("central.state is .poweredOn")
            connectionLabel.text = "Powered On"
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
        connectionLabel.text = "Connected to \(microbit.name ?? "")"
        connectionLabel.textColor = UIColor.orange
        peripheral.discoverServices([AccelerometerServiceUUID])
    }
    
    // MARK : Bluetooth - Peripheral functions
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for s in peripheral.services! {
            let service = s as CBService
            print("Service discovered: \(service.description)")
            peripheral.discoverCharacteristics(nil, for: service)
            connectionLabel.text = "Discovered services"
            connectionLabel.textColor = UIColor.yellow
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
        connectionLabel.text = "Discovered characteristics"
        connectionLabel.textColor = UIColor.green
        // enable record button here
    }
    
    func getAccelerometerDataFromMicrobit() throws -> (Double,Double,Double) {
        // TODO : MAKE SURE THIS STOPS
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
}
enum BluetoothConnectError: Error {
    case NoValueForCharacteristic
    case NoCharacteristicForService
}
