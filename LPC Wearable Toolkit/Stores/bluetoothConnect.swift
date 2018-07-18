import Foundation
import CoreBluetooth
import UIKit

/**
 The MicrobitDelegate protocol defines the methods that a delegate of a micro:bit object must adopt.
 */
public protocol MicrobitDelegate {
    
    func logUpdated(_ log:[String])
    func advertisementData(url:String,namespace:Int64,instance:Int32,RSSI:Int)
    func serviceAvailable(service:ServiceName)
    func uartReceived(message:String)
    func pinGet(pins:[UInt8:UInt8])
    func accelerometerData(x:Int16,y:Int16,z:Int16)
    func magnetometerData(x:Int16,y:Int16,z:Int16)
    func compass(bearing:Int16)
    func microbitEvent(type:Int16,value:Int16)
    func temperature(value:Int16)
}
/**
 Provide default dummy definitions for the MicrobitDelegate protocol
 to prevent unnecessary functions being implemeted in conforming classes.
 */
extension MicrobitDelegate {
    func logUpdated(_ log:[String]) {}
    func advertisementData(url:String,namespace:Int64,instance:Int32,RSSI:Int) {}
    func serviceAvailable(service:ServiceName) {}
    func uartReceived(message:String) {}
    func pinGet(pins:[UInt8:UInt8]) {}
    func accelerometerData(x:Int16,y:Int16,z:Int16) {}
    func magnetometerData(x:Int16,y:Int16,z:Int16) {}
    func compass(bearing:Int16) {}
    func microbitEvent(type:Int16,value:Int16) {}
    func temperature(value:Int16) {}
}
/**
 Services available from a micro:bit peripheral
 */
public enum ServiceName {
    case Event
    case DeviceInfo
    case Accelerometer
    case Magnetometer
    case Button
    case IOPin
    case LED
    case Temperature
    case UART
}

/**
 Magnetometer and Accelerometer reporting periods in milliseconds
 */
public enum PeriodType:UInt16 {
    case p1 = 1
    case p2 = 2
    case p5 = 5
    case p10 = 10
    case p20 = 20
    case p80 = 80
    case p160 = 160
    case p640 = 640
    case p1000 = 1000
}

public class Microbit: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    // MARK: Properties
    /**
     public property containing an instance of the class implementing the
     MicrobitDelegate protocol
     */
    public var delegate: MicrobitDelegate?
    /**
     This name must be provided when intializing an instance of Microbit class. It is used to scan for
     micro:bit peripheral.
     */
    public var deviceName:String
    /**
     property represents the microbit client i.e the apple device.
     corebluetooth knows this as the Central Manager.
     */
    private var centralManager : CBCentralManager!
    /**
     property repreesents the microbit computer
     corebluetooth knows this as a Peripheral
     */
    private var microbitPeripheral : CBPeripheral!
    /**
     flag is set to true by centralManagerDidUpdateState if bluetooth LE
     is available.
     The microbit Bluetooth API can only be use if this flag is true
     */
    private var bleON = false
    /**
     string buffer to hold diagnostic messages.
     Buffer holds a maximum of MAX_BUFFER_ENTRIES before oldest entry is removed
     */
    public var log = [String]()
    private let MAX_BUFFER_ENTRIES = 100
    
    /**
     public variables containg device information.
     This variables only contain information once the appropriate device information characteristic
     has been discovered. Therefore this variables should not be read until the MicrobitDelegate function
     serviceAvaialble:serviceName:DeviceInfo has been called.
     */
    public var modelNumber:String = "n/a"
    public var serialNumber:String = "n/a"
    public var firmwareRevision:String = "n/a"
    
    
    // MARK: GATT Profile
    var found = false
    // DEVICE INFORMATION
    let DeviceInfoUUID = CBUUID(string:"180A")
    // Read
    let ModelNumberCharacteristicUUID = CBUUID(string:"2A24")
    var modelNumberCharacteristic:CBCharacteristic?
    // Read
    let SerialNumberCharacteristicUUID = CBUUID(string:"2A25")
    var serialNumberCharacteristic:CBCharacteristic?
    // Read
    let FirmwareRevisionCharacteristicUUID = CBUUID(string:"2A26")
    var firmwareRevisionCharacteristic:CBCharacteristic?
    
    // ACCELEROMETER SERVICE
    let AccelerometerServiceUUID = CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    // Notify,Read
    let AccelerometerDataCharacteristicUUID = CBUUID(string:"E95DCA4B-251D-470A-A062-FA1922DFA9A8")
    var accelerometerDataCharacteristic:CBCharacteristic?
    // Write
    let AccelerometerPeriodCharacteristicUUID = CBUUID(string:"E95DFB24-251D-470A-A062-FA1922DFA9A8")
    var accelerometerPeriodCharacteristic:CBCharacteristic?
    
    var accelerationStore = Accelerations()
    
    // MARK: Initialization of class instance
    
    public override init() {
        print("init")
        self.deviceName = ""
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Core bluetooth Central Manager Delegate methods
    
    //////NEEDED////////////
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            print("central 0")
            bleON = true
            print("Bluetooth is available")
            updateLabel(newSentence: "Bluetooth is available")
        } else {
            bleON = false
            print("Bluetooth switched off or not initialized")
            updateLabel(newSentence: "Bluetooth switched off or not initialized")
        }
    }
    //NEEDED//
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("central Manager 1")
        var found = false
        var nameOfDeviceFound = "n/a"
        if let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? String {
            UserDefaults.standard.set(found, forKey: "found")
            print("Possible device detected: \(device)")
            updateLabel(newSentence: "Possible device detected: \(device)")
            nameOfDeviceFound = device
        }
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey]
            as? NSDictionary {
            print("advertisementData")
            serviceDataAnalyzer(serviceData: serviceData, RSSI: RSSI)
        }
        if (nameOfDeviceFound == deviceName) {
            //print("device found: \(nameOfDeviceFound)")
            print("OK Device \(nameOfDeviceFound) found - stop looking")
            updateLabel(newSentence: "OK Device \(nameOfDeviceFound) found - stop looking")
            found = true
            UserDefaults.standard.set(found, forKey: "found")
            // Stop scanning
            stopScanning()
            // Set as the periheral to use and establish connection
            microbitPeripheral = peripheral
            microbitPeripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
            
        } else {
            print("Looking for \(deviceName)")
            updateLabel(newSentence: "Looking for \(deviceName)")
        }
    }
    /////NEEDED///////
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("central 2")
        print("connected to microbit")
        log("Connected to \(deviceName)")
        peripheral.discoverServices(nil)
    }
    
    // MARK: Core bluetooth Perioheral Delegate methods
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("central 3")
        log("Looking for peripheral services")
        for service in peripheral.services! {
            let thisService = service as CBService
            log("Service UUID = \(thisService.uuid)")
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }
    
    ///////partly NEEDED/////////
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log("Discovering Characteristics")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            log("Characteristic UUID = \(thisCharacteristic.uuid)")
            
            switch thisCharacteristic.uuid {
            case ModelNumberCharacteristicUUID :
                print("Model Number Charateristic found")
                modelNumberCharacteristic  = thisCharacteristic
                microbitPeripheral.readValue(for: modelNumberCharacteristic!)
            case SerialNumberCharacteristicUUID :
                print("Serial Number Charateristic found")
                serialNumberCharacteristic  = thisCharacteristic
                microbitPeripheral.readValue(for: serialNumberCharacteristic!)
            case FirmwareRevisionCharacteristicUUID :
                print("Firmware Revision Charateristic found")
                firmwareRevisionCharacteristic  = thisCharacteristic
                delegate?.serviceAvailable(service: .DeviceInfo)
                microbitPeripheral.readValue(for: firmwareRevisionCharacteristic!)
            case AccelerometerDataCharacteristicUUID :
                print("Accelerometer data characteristic found")
                updateLabel(newSentence: "Accelerometer data characteristic found")
                accelerometerDataCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case AccelerometerPeriodCharacteristicUUID :
                print("Accelerometer period characteristic found")
                updateLabel(newSentence: "Accelerometer period characteristic found")
                accelerometerPeriodCharacteristic = thisCharacteristic
                delegate?.serviceAvailable(service: .Accelerometer)
            default:
                break
            }
        }
    }
    ///////Partly NEEDED//////
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case ModelNumberCharacteristicUUID :
            let dataBytes = characteristic.value!
            modelNumber = String(data: dataBytes, encoding: String.Encoding.utf8) ?? "n/a"
            print("Model number = \(modelNumber)")
            updateLabel(newSentence: "Model number = \(modelNumber)")
        case SerialNumberCharacteristicUUID :
            let dataBytes = characteristic.value!
            serialNumber = String(data: dataBytes, encoding: String.Encoding.utf8) ?? "n/a"
            print("Serial number = \(serialNumber)")
            updateLabel(newSentence: "Serial number = \(serialNumber)")
        case FirmwareRevisionCharacteristicUUID :
            let dataBytes = characteristic.value!
            firmwareRevision = String(data: dataBytes, encoding: String.Encoding.utf8) ?? "n/a"
            print("Firmware revision number = \(firmwareRevision)")
             updateLabel(newSentence: "Firmware revision number = \(firmwareRevision)")
        case AccelerometerDataCharacteristicUUID :
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
            delegate?.accelerometerData(x: accelerometerData.x, y: accelerometerData.y, z:accelerometerData.z)

            UserDefaults.standard.set(true, forKey: "boolean")
        default :
            break
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
        return (Double(accelerometerData.x),Double(accelerometerData.y),Double(accelerometerData.z))
    }
    
    // MARK: microbit API
    
    /**
     Starts a scan for bluetooth peripherals regardless of the services being advertised.
     The scan will stop once the device name (specified when the class was instantiated) is found.
     */
    func updateLabel(newSentence: String)
    {
        UserDefaults.standard.set(newSentence, forKey: "update")
    }
    public func startScanning()-> Bool {
        if bleON {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            print("looking for peripherals")
            updateLabel(newSentence: "looking for peripherals")
            return true
        }
        else
        {
            return false
        }
    }
    /**
     Stop scanning for bluetooth peripherals. This function will have no effect if a scan is not in
     progress
     */
    public func stopScanning() {
        if bleON {
            centralManager.stopScan()
            log("Stop scanning for peripherals")
        }
    }
    /**
     Disconnect from the bluetooth peripheral.
     */
    public func disconnect() {
        if bleON {
            if microbitPeripheral != nil {
                centralManager.cancelPeripheralConnection(microbitPeripheral)
                updateLabel(newSentence: "disconnected")
                log("Disconnect peripheral")
            } else {
                log("Microbit peripheral is not connected")            }
        }
    }
    public func buttonPress_Disconnect()
    {
        updateLabel(newSentence: "connect to bluetooth first")
    }
    
    /**
     Implements the Accelerometer Service - sets the frequency accelerometer data is reported.
     - parameters:
     - period: the interval in milliseconds between the accelerometer reporting data. Only specific values are acceptable as defined by PeriodType.
     */
    public func accelerometer(period:PeriodType) {
        print("\(period)")
        print("made it to period")
        guard let accelerometerPeriodCharacteristic = accelerometerPeriodCharacteristic else {return}
        let accelerometerPeriodData = toData(period.rawValue)
        microbitPeripheral.writeValue(accelerometerPeriodData, for: accelerometerPeriodCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    // MARK: Suppport utilities
    
    func toData<T>(_ value: T) -> Data {
        var value = value
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    
    func log(_ message:String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let date = Date()
        let dateString = formatter.string(from: date)
        log.append(dateString + " " + message)
        print(dateString + " " + message)
        if log.count > MAX_BUFFER_ENTRIES {
            log.remove(at: 0)
        }
        delegate?.logUpdated(log)
    }
    // Not used//
    func serviceDataAnalyzer(serviceData:NSDictionary,RSSI:NSNumber) {
        for data in serviceData {
            print("analyzer")
            let id = "\(data.key)"
            let dataBytes = data.value as? Data ?? Data(bytes:[0x00])
            var dataArray:[UInt8] = Array(repeating:0,count:dataBytes.count)
            dataBytes.copyBytes(to: &dataArray,count:dataArray.count)
            log("Service data: \(dataBytes.map { String(format: "%02x", $0) }.joined()),RSSI: \(RSSI)")
            if id == "FEAA" {
                dataBytes.withUnsafeBytes {(ptr: UnsafePointer<UInt8>) in
                    let type = Int(dataBytes[0])
                    var url = " "
                    var namespace:Int64 = 0
                    var instance:Int32 = 0
                    if type == 0 {
                        var rawPtr = UnsafeRawPointer(ptr + 4)
                        let typedPointer4 = rawPtr.bindMemory(to: Int64.self, capacity: 1)
                        namespace = Int64(bigEndian:typedPointer4.pointee)
                        rawPtr = UnsafeRawPointer(ptr + 14)
                        let typedPointer14 = rawPtr.bindMemory(to: Int32.self, capacity: 1)
                        instance = Int32(bigEndian:typedPointer14.pointee)
                    } else {
                        let text = dataBytes.subdata(in: 2..<dataBytes.count)
                        url = String(data: text, encoding: String.Encoding.utf8) ?? "Error"
                    }
                    let rssi = Int(truncating:RSSI)
                    log("Advertisement data - url: \(url), namespace: \(namespace), instance: \(instance), RSSI: \(rssi)")
                    delegate?.advertisementData(url: url, namespace: namespace, instance: instance, RSSI: rssi)
                }
            }
        }
    }
}

enum BluetoothConnectError: Error {
    case NoValueForCharacteristic
}


