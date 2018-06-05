//
//  ViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Varun Narayanswamy on 5/1/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//
import UIKit
import Foundation
import AVKit
import MobileCoreServices
import CoreBluetooth
import Charts

class MicrobitUIController: UIViewController, MicrobitDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //@IBOutlet weak var txtTextBox: UITextField!
    // hmmmmmmm
    @IBOutlet weak var chtChart: LineChartView!
    var numbers:[Double] = []
    //var microbit:Microbit = Microbit("BBC micro:bit [tizip]")
    //class ViewController: UIViewController {
    //find bluetooth
    //var observation: NSKeyValueObservation?
    //gepev
    var microbit = Microbit()
    var connected = false
    var periodType = PeriodType.p1
    var getVal = true
    var x = 0
    var y = 0
    var z = 0
    
    @IBOutlet weak var updated: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBAction func bluetooth(_ sender: UIButton)
    {
        microbit.deviceName = "BBC micro:bit [gipov]"
        if (connected == false)
        {
            //observation = microbit.observe(\Microbit.update, options: [.new])
            //{ [updated] microbit, _ in self.updated.text = microbit.update.text }
            print(self.connected)
            updated.text = "Hello"
            //microbitAccelerometer.delegate = self
            var exists = microbit.startScanning()
            //updated.text = microbit.update.text!
            print("done scanning")
            microbit.accelerometer(period: periodType)
            func accelerometerSet(period: PeriodType) {
                microbit.accelerometer(period: period)
            }
            sender.setTitle("Disconnect", for: .normal)
            DispatchQueue.global(qos: .userInitiated).async
                {
                    while (exists == true)
                    {
                        let words:String! = UserDefaults.standard.string(forKey: "update")
                        if (words == "Firmware revision number = 2.0.0-rc9--g")
                        {
                            print("break")
                            exists = false
                        }
                        else
                        {
                            DispatchQueue.main.sync {
                                self.updated.text = words
                            }
                        }
                        // let boolean = UserDefaults.standard.bool(forKey: "boolean")
                    }
                    self.updated.text = "You are Connected"
                    // Bounce back to the main thread to update the UI
            }
            connected = true
        }
        else
        {
            connected = false
            microbit.disconnect()
            self.updated.text = "Disconnected"
            sender.setTitle("Connect", for: .normal)
        }
        
    }
    
    @IBAction func record(_ sender: UIButton) {
        //let camera = UIImagePickerController()
        if (connected == false)
        {
            print("connect to bluetooth first")
            updated.text = "connect to bluetooth first"
            microbit.buttonPress_Disconnect()
        }
        else
        {
            
            self.getVal = true
            DispatchQueue.global(qos: .userInitiated).async {
                while (self.getVal == true)
                {
                    self.x = UserDefaults.standard.integer(forKey: "xData")
                    self.y = UserDefaults.standard.integer(forKey: "yData")
                    self.z = UserDefaults.standard.integer(forKey: "zData")
                    //  var boolean = UserDefaults.standard.bool(forKey: "boolean")
                    print(self.x,self.y,self.z)
                    let x_val = self.x
                    let y_val = self.y
                    let z_val = self.z
                    let added = x_val*x_val + y_val*y_val + z_val*z_val
                    print(added)
                    let Acc = sqrt(Double(added))
                    print("total acceleration \(Acc)")
                    self.numbers.append(Acc)
                    DispatchQueue.main.sync {
                        self.updateGraph()
                    }
                }
                // Bounce back to the main thread to update the UI
            }
        }
    }

    /*@IBAction func Video(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            let video = UIImagePickerController()
            video.delegate = self
            video.sourceType = .camera
            video.mediaTypes = [kUTTypeMovie as String]
            video.allowsEditing = true
            video.showsCameraControls = true
            self.present(video, animated: true, completion: nil)
        }
        else
        {
            print("camera is not available")
        }
        //let CameraView = VideoRecorder()
        //self.present(CameraView, animated: true, completion: nil)
    }
  */

    
    
    @IBAction func stop(_ sender: UIButton) {
        print("stop")
        self.getVal = false
    }
    
    @IBAction func reset(_ sender: UIButton) {
        self.numbers = [0]
        self.updateGraph()
        self.getVal = false
    }
    
    @IBAction func Save(_ sender: UIButton) {
        self.getVal = false
        let newImage:UIImage! = chtChart.getChartImage(transparent: false)
        let image = UIImagePNGRepresentation(newImage)
        let compressed = UIImage(data: image!)
        UIImageWriteToSavedPhotosAlbum(compressed!, nil, nil, nil)
        
        let alert = UIAlertController(title: "saved", message: "your graph has been saved", preferredStyle: .alert)
        let AlertMenu = UIAlertAction(title: "ok", style: .default, handler: nil)
        alert.addAction(AlertMenu)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  deviceName.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateGraph(){
        
        var lineChartEntry  = [ChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        
        
        //here is the for loop
        for i in 0..<self.numbers.count {
            let value = ChartDataEntry(x: Double(i), y: self.numbers[i]) // here we set the X and Y status in a data chart entry
            lineChartEntry.append(value) // here we add it to the data set
        }
        
        let line1 = LineChartDataSet(values: lineChartEntry, label: "Number") //Here we convert lineChartEntry to a LineChartDataSet
        line1.colors = [NSUIColor.blue] //Sets the colour to blue
        
        let data = LineChartData() //This is the object that will be added to the chart
        data.addDataSet(line1) //Adds the line to the dataSet
        
        if(numbers.count > 200 ){
            numbers.remove(at: 0)
        }
        
        chtChart.data = data //finally - it adds the chart data to the chart and causes an update
        chtChart.chartDescription?.text = "Acceleration" // Here we set the description for the graph
        
    }
    
}
/*extension MicrobitUIController: UITextFieldDelegate
 {
 func textFieldShouldReturn(_ textField: UITextField) -> Bool {
 textField.resignFirstResponder()
 return true
 }
 }*/


