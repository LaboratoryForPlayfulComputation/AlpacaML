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
    func buttonPressed(button:String,action:MicrobitButtonType)
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
    func buttonPressed(button:String,action:MicrobitButtonType) {}
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
 Button states enumerated by the micro:bit button service
 */
public enum MicrobitButtonType:UInt8 {
    case Up
    case Down
    case Long
    case Invalid
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
}
/**
 Available events that can be detected by the micro:bit using control.onEvent
 */
public enum MicrobitEvent:Int16 {
    case MES_DEVICE_INFO_ID = 1103
    case MES_SIGNAL_STRENGTH_ID = 1101
    case MES_DPAD_CONTROLLER_ID = 1104
    case MES_BROADCAST_GENERAL_ID = 2000
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
    private var deviceName:String
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
    
    
    // MAGNETOMETER SERVICE
    let MagnetometerServiceUUID = CBUUID(string: "E95DF2D8-251D-470A-A062-FA1922DFA9A8")
    // Notify, Read
    let MagnetometerDataCharacteristicUUID = CBUUID(string:"E95DFB11-251D-470A-A062-FA1922DFA9A8")
    var magnetometerDataCharacteristic:CBCharacteristic?
    // Write
    let MagnetometerPeriodCharacteristicUUID = CBUUID(string: "E95D386C-251D-470A-A062-FA1922DFA9A8")
    var magnetometerPeriodCharacterictic:CBCharacteristic?
    // Notify, Read
    let MagnetometerBearingCharacteristicUUID = CBUUID(string: "E95D9715-251D-470A-A062-FA1922DFA9A8")
    var magnetometerBearingCharacteristic:CBCharacteristic?
    
    // BUTTON SERVICE
    let ButtonServiceUUID = CBUUID(string: "E95D9882-251D-470A-A062-FA1922DFA9A8")
    // Notify, Read
    let ButtonAStateCharacteristicUUID = CBUUID(string: "E95DDA90-251D-470A-A062-FA1922DFA9A8")
    var buttonAStateCharacteristic:CBCharacteristic?
    // Notify, Read
    let ButtonBStateCharacteristicUUID = CBUUID(string: "E95DDA91-251D-470A-A062-FA1922DFA9A8")
    var buttonBStateCharacteristic:CBCharacteristic?
    
    // IO PIN SERVICE
    let IOpinServiceUUID = CBUUID( string:"E95D127B-251D-470A-A062-FA1922DFA9A8")
    // Write
    let PinDataCharacteristicUUID = CBUUID(string: "E95D8D00-251D-470A-A062-FA1922DFA9A8")
    var pinDataCharacteristic:CBCharacteristic?
    // Write
    let PinADCharacteristicUUID = CBUUID(string: "E95D5899-251D-470A-A062-FA1922DFA9A8")
    var pinADCharacteristic:CBCharacteristic?
    // Notify, Read, Write
    let PinIOCharacteristicUUID = CBUUID(string: "E95DB9FE-251D-470A-A062-FA1922DFA9A8")
    var pinIOCharacteristic:CBCharacteristic?
    
    // LED SERVICE
    let LEDServiceUUID = CBUUID(string:"E95DD91D-251D-470A-A062-FA1922DFA9A8")
    // Read,Write
    let LEDMAtrixStateCharacteristicUUID = CBUUID(string:"E95D7B77-251D-470A-A062-FA1922DFA9A8")
    var ledMatrixStateCharacteristic:CBCharacteristic?
    // Write
    let LEDTextCharacteristicUUID = CBUUID(string:"E95D93EE-251D-470A-A062-FA1922DFA9A8")
    var ledTextCharacteristic:CBCharacteristic?
    // Write
    let ScrollingDelayCharacteristicUUID = CBUUID(string:"E95D0D2D-251D-470A-A062-FA1922DFA9A8")
    var scrollingDelayCharacteristic:CBCharacteristic?
    
    // EVENT SERVICE
    let EventServiceUUID = CBUUID(string: "E95D93AF-251D-470A-A062-FA1922DFA9A8")
    // Client Requirement - a list of events on the microbit that the client should be informed of
    // Write
    let ClientRequirementCharacteristicUUID = CBUUID(string: "E95D23C4-251D-470A-A062-FA1922DFA9A8")
    var clientRequirementCharacteristic:CBCharacteristic?
    // Microbit Event - an event occuring on the microbit that the client has requested
    // Notify,Read
    let MicrobitEventCharacteristicUUID = CBUUID(string: "E95D9775-251D-470A-A062-FA1922DFA9A8")
    var microbitEventCharacteristic:CBCharacteristic?
    // Client Event - Events (commands) issued on the client and sent to the microbit
    // Write
    let ClientEventCharacteristicUUID = CBUUID(string: "E95D5404-251D-470A-A062-FA1922DFA9A8")
    var clientEventCharacteristic:CBCharacteristic?
    
    // TEMPERATURE SERVICE
    let TempertureServiceUUID = CBUUID(string:"E95D6100-251D-470A-A062-FA1922DFA9A8")
    // Notify,Read
    let TemperatureCharacteristicUUID = CBUUID(string:"E95D9250-251D-470A-A062-FA1922DFA9A8")
    var temperatureCharacteristic:CBCharacteristic?
    // Write
    let TemperaturePeriodCharacteristicUUID = CBUUID(string:"E95D1B25-251D-470A-A062-FA1922DFA9A8")
    var temperaturePeriodCharacteristic:CBCharacteristic?
    
    // UART SERVICE
    let UARTServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    // RX - Send data to microbit
    // Write
    let UART_RX_CharacteristicUUID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    var uartRXcharacteristic:CBCharacteristic?
    // TX - Receive data from the microbit
    // Notify, Read
    let UART_TX_CharacteristicUUID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    var uartTXcharacteristic:CBCharacteristic?
    
    
    
    
    
    
    
    // MARK: Initialization of class instance
    
    public init(_ deviceName:String) {
        print("init")
        self.deviceName = deviceName
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
            case ClientRequirementCharacteristicUUID :
                print("Writing to the client requirements characteristic")
                clientRequirementCharacteristic  = thisCharacteristic
                delegate?.serviceAvailable(service: .Event)
                // write a value to force pairing
                registerEvents(events:[9010])
                
            case ClientEventCharacteristicUUID :
                print("Client Event Characteristic Found")
                clientEventCharacteristic = thisCharacteristic
            case MicrobitEventCharacteristicUUID :
                print("Microbit event characteristic found")
                clientRequirementCharacteristic  = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case UART_RX_CharacteristicUUID :
                print("UART RX characteristic found")
                uartRXcharacteristic = thisCharacteristic
            case UART_TX_CharacteristicUUID :
                print("UART TX characteristic found")
                uartTXcharacteristic = thisCharacteristic
                delegate?.serviceAvailable(service: .UART)
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case LEDTextCharacteristicUUID :
                print("LED text characteristic found")
                ledTextCharacteristic = thisCharacteristic
            case ScrollingDelayCharacteristicUUID :
                print("LED scrolling text characteristic found")
                scrollingDelayCharacteristic = thisCharacteristic
            case LEDMAtrixStateCharacteristicUUID :
                print("LED matrix state characteristic found")
                ledMatrixStateCharacteristic = thisCharacteristic
                delegate?.serviceAvailable(service: .LED)
            case PinADCharacteristicUUID :
                print("Pin Analogue/Digital configuration characteristic found")
                pinADCharacteristic = thisCharacteristic
            case PinIOCharacteristicUUID :
                print("Pin Input/Output configuration characteristic found")
                pinIOCharacteristic = thisCharacteristic
            case PinDataCharacteristicUUID :
                print("Pin Data characteristic found")
                pinDataCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
                delegate?.serviceAvailable(service: .IOPin)
            case ButtonAStateCharacteristicUUID :
                print("Button A state characteristic found")
                buttonAStateCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case ButtonBStateCharacteristicUUID :
                print("Button B state characteristic found")
                buttonBStateCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
                delegate?.serviceAvailable(service: .Button)
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
            case MagnetometerDataCharacteristicUUID :
                print("Magnetometer data characteristic found")
                magnetometerDataCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case MagnetometerPeriodCharacteristicUUID :
                print("Magnetometer period characteristic found")
                magnetometerPeriodCharacterictic = thisCharacteristic
            case MagnetometerBearingCharacteristicUUID :
                print("Magnetometer bearing characteristic found")
                magnetometerBearingCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
                delegate?.serviceAvailable(service: .Magnetometer)
            case TemperatureCharacteristicUUID :
                print("Temperature reading characteristic found")
                temperatureCharacteristic = thisCharacteristic
                microbitPeripheral.setNotifyValue(true, for: thisCharacteristic)
            case TemperaturePeriodCharacteristicUUID :
                print("Temperature period characteristic found")
                temperaturePeriodCharacteristic = thisCharacteristic
                delegate?.serviceAvailable(service: .Temperature)
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
        case UART_TX_CharacteristicUUID :
            let dataBytes = characteristic.value!
            let dataString = String(data: dataBytes, encoding: String.Encoding.utf8) ?? "Error reading message"
            print("UART_TX")
            delegate?.uartReceived(message: dataString)
        case PinDataCharacteristicUUID:
            let dataBytes = characteristic.value!
            var values = [UInt8:UInt8]()
            print("Pin")
            let sequence = stride(from: 0, to: dataBytes.count, by: 2)
            for element in sequence {
                values[dataBytes[element]] = dataBytes[element + 1]
            }
            delegate?.pinGet(pins: values)
        case ButtonAStateCharacteristicUUID :
            print("button")
            let dataBytes = characteristic.value!
            delegate?.buttonPressed(button: "A",action:MicrobitButtonType(rawValue: dataBytes[0])!)
        case ButtonBStateCharacteristicUUID :
            print("buttonB")
            let dataBytes = characteristic.value!
            delegate?.buttonPressed(button: "B",action:MicrobitButtonType(rawValue: dataBytes[0]) ?? MicrobitButtonType.Invalid)
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
            UserDefaults.standard.set(accelerometerData.x, forKey: "xData")
            UserDefaults.standard.set(accelerometerData.y, forKey: "yData")
            UserDefaults.standard.set(accelerometerData.z, forKey: "zData")
            UserDefaults.standard.set(true, forKey: "boolean")
        case MagnetometerDataCharacteristicUUID :
            print("magnet")
            struct MagnetometerData {
                let x: Int16
                let y: Int16
                let z: Int16
            }
            let dataBytes = characteristic.value!
            let magnetometerData = dataBytes.withUnsafeBytes {(int16Ptr: UnsafePointer<Int16>)-> MagnetometerData in
                MagnetometerData(x: Int16(littleEndian: int16Ptr[0]),
                                 y: Int16(littleEndian: int16Ptr[1]),
                                 z: Int16(littleEndian: int16Ptr[2]))
            }
            delegate?.magnetometerData(x: magnetometerData.x, y: magnetometerData.y, z:magnetometerData.z)
        case MagnetometerBearingCharacteristicUUID :
            print("bearing")
            let dataBytes = characteristic.value!
            let magnetometerBearing = dataBytes.withUnsafeBytes{(int16Ptr:UnsafePointer<Int16>)-> Int16 in Int16(littleEndian:int16Ptr[0])}
            delegate?.compass(bearing:magnetometerBearing)
        case MicrobitEventCharacteristicUUID :
            print("event")
            struct Event {
                let type:  Int16
                let value: Int16
            }
            let dataBytes = characteristic.value!
            let eventData = dataBytes.withUnsafeBytes{(uint16ptr:UnsafePointer<Int16>)->Event in
                Event(type: Int16(littleEndian:uint16ptr[0]),
                      value:Int16(littleEndian:uint16ptr[1]))
            }
            delegate?.microbitEvent(type: eventData.type, value: eventData.value)
        case TemperatureCharacteristicUUID :
            print("temp")
            let temperature = characteristic.value!
            delegate?.temperature(value: Int16(temperature[0]))
        default :
            break
        }
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
     Implements the LED Service - text and scrolling delay.
     - parameters:
     - message: a string to be scrolled across the micro:bit led matrix
     - scrollRate : an integer (0 - 32768) milliseconds speed the text is scrolled.
     */
    public func ledText(message:String,scrollRate:Int16) {
        guard let scrollingDelayCharacteristic = scrollingDelayCharacteristic else {return}
        guard let ledTextCharacteristic = ledTextCharacteristic else {return}
        let scrollRateData = toData(scrollRate)
        if let messageData = message.data(using: String.Encoding.utf8){
            microbitPeripheral.writeValue(scrollRateData, for: scrollingDelayCharacteristic, type: CBCharacteristicWriteType.withResponse)
            microbitPeripheral.writeValue(messageData, for: ledTextCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    /**
     Implements the LED Service - matrix state
     - parameters:
     - matrix: an array of 5 UInt8 bytes. The first 5 bits of each byte represents the leds in each row
     */
    public func ledWrite(matrix:[UInt8]) {
        guard let ledMatrixStateCharacteristic = ledMatrixStateCharacteristic else {return}
        let data = Data(bytes:matrix)
        microbitPeripheral.writeValue(data, for: ledMatrixStateCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the UART Service - sends a text string
     - parameters:
     - message: a string containing a maximum of 20 characters to be sent to the micro:bit
     */
    public func uartSend(message:String) {
        guard let uartRXcharacteristic = uartRXcharacteristic else {return}
        if let messageData = message.data(using:String.Encoding.utf8) {
            microbitPeripheral.writeValue(messageData, for: uartRXcharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    /**
     Implements the Pin IO Service - AD Configuration
     - parameters:
     - analougePins: a dictionary of UInt8:Bool pairs. Each pair indicates if a pin is to be configured
     as analouge (true) of digital (false). Only pins 0, 1, 2, 3, 4 and 10 have AD converters.
     */
    public func pinConfigure(analougePins:[UInt8:Bool]) {
        guard let pinADCharacteristic = pinADCharacteristic else {return}
        var adPatternData = Data(bytes:[0x00,0x00,0x00,0x00])
        for pin in analougePins {
            if pin.value == true {
                if pin.key < 8 {
                    adPatternData[0] =  adPatternData[0] + (1 << (pin.key))
                } else if pin.key >= 8 && pin.key < 16 {
                    adPatternData[1] =  adPatternData[1] + (1 << (pin.key - 8))
                } else {
                    adPatternData[2] =  adPatternData[2] + (1 << (pin.key - 16))
                }
            }
        }
        microbitPeripheral.writeValue(adPatternData, for: pinADCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the Pin IO Service - IO Configuration
     - parameters:
     - readPins: a dictionary of UInt8:Bool pairs. Each pair indicates if a pin is to be configured as write (true) or read (false). A maximum of 18 pins can be configured.
     */
    public func pinConfigure(readPins:[UInt8:Bool]) {
        guard let pinIOCharacteristic = pinIOCharacteristic else {return}
        var ioPatternData = Data(bytes:[0x00,0x00,0x00,0x00])
        for pin in readPins {
            if pin.value == true {
                if pin.key < 8 {
                    ioPatternData[0] =  ioPatternData[0] + (1 << (pin.key))
                } else if pin.key >= 8 && pin.key < 16 {
                    ioPatternData[1] =  ioPatternData[1] + (1 << (pin.key - 8))
                } else {
                    ioPatternData[2] =  ioPatternData[2] + (1 << (pin.key - 16))
                }
            }
        }
        microbitPeripheral.writeValue(ioPatternData, for: pinIOCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the PIN IO Service - Data write
     - parameters:
     - pinValues: a dictionary of UInt8:UInt8 pairs. Each pair represents the value to be written to a given pin. If the pin is configured as digital, only values 0 and 1 should be used. If the pin is configured as analogue values 0 - 255 can be used.
     */
    public func pinSet(pinValues:[UInt8:UInt8]) {
        guard let pinDataCharacteristic = pinDataCharacteristic else {return}
        var valuesArray = [UInt8]()
        for pin in pinValues {
            valuesArray.append(pin.key)
            valuesArray.append(pin.value)
        }
        let pinValuesData = Data(bytes:valuesArray)
        microbitPeripheral.writeValue(pinValuesData, for: pinDataCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the Accelerometer Service - sets the frequency accelerometer data is reported.
     - parameters:
     - period: the interval in milliseconds between the accelerometer reporting data. Only specific values are acceptable as defined by PeriodType.
     */
    public func accelerometer(period:PeriodType) {
        print("made it to period")
        guard let accelerometerPeriodCharacteristic = accelerometerPeriodCharacteristic else {return}
        let accelerometerPeriodData = toData(period.rawValue)
        microbitPeripheral.writeValue(accelerometerPeriodData, for: accelerometerPeriodCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the Magnetometer Service - sets the frequency magnetometer data is reported.
     - parameters:
     - period: the interval in milliseconds between the magnetometer reporting data. Only specific values are acceptable as defined by PeriodType.
     */
    public func magnetometer(period:PeriodType) {
        guard let magnetometerPeriodCharacteristic = magnetometerPeriodCharacterictic else {return}
        let magnetometerPeriodData = toData(period.rawValue)
        microbitPeripheral.writeValue(magnetometerPeriodData, for: magnetometerPeriodCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the Temperature Service - sets the frequency temperature data is reported.
     - parameters:
     - period: the interval in milliseconds between temperature readings being sent from the micro:bit. A value in the range(0 - 65535) is acceptable.
     */
    public func temperature(period:UInt16) {
        guard let temperaturePeriodCharacteristic = temperaturePeriodCharacteristic else {return}
        let temperaturePeriodData = toData(period)
        microbitPeripheral.writeValue(temperaturePeriodData, for: temperaturePeriodCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    /**
     Implements the Event Service - Client Requirements
     - parameters:
     - events: an array of events in the range 0 - 32,768 that the swift application will listen for.
     */
    public func registerEvents(events:[Int16]) {
        guard let clientRequirementCharacteristic = clientRequirementCharacteristic else {return}
        for event in events {
            var eventData = toData(event)
            eventData.append(contentsOf: [0x00,0x00])
            microbitPeripheral.writeValue(eventData, for: clientRequirementCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    /**
     Implements the Event Service - Client Event
     - parameters:
     - event: an Event that the micro:bit is listening for
     - value: the value associated with the event
     */
    public func raiseEvent(event:MicrobitEvent,value:UInt16) {
        guard let clientEventCharacteristic = clientEventCharacteristic else {return}
        var eventData = toData(event.rawValue)
        eventData.append(toData(value))
        microbitPeripheral.writeValue(eventData, for: clientEventCharacteristic, type: CBCharacteristicWriteType.withResponse)
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




