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

class MicrobitUIController: UIViewController, MicrobitDelegate, UITextFieldDelegate, ChartViewDelegate, CustomOverlayDelegate {
    
    var recording = false
    @IBOutlet weak var chtChart: LineChartView!
    var i = 0
    var timer = Timer()
    var player = AVPlayer()
    let mediaUI = UIImagePickerController()
    var timestamp:Double = 0
    var is_connecting = false
    var numbers:[Double] = []
    var microbit = Microbit()
    var connected_to_device = false
    var reset = false
    var periodType = PeriodType.p1000
    var getVal = false
    var chart_pressed = false
    var x = 0
    var y = 0
    var z = 0
    
    func didCancel(overlayView: CustomOverlayView) {
        mediaUI.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true)
        {
            print("recording")
            mediaUI.startVideoCapture()
            recording = true
            /*DispatchQueue.global(qos: .userInitiated).async {
                while (self.getVal == true)
                {
                    self.x = UserDefaults.standard.integer(forKey: "xData")
                    self.y = UserDefaults.standard.integer(forKey: "yData")
                    self.z = UserDefaults.standard.integer(forKey: "zData")
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
                        print(self.i)
                        self.i = self.i + 1
                    }
                }
            }*/
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MicrobitUIController.graphing), userInfo: nil, repeats: true)
        }
        else
        {
            print("stop recording")
            mediaUI.stopVideoCapture()
            //getVal = false
            timer.invalidate()
            recording = false
        }
    }
    
    @objc func graphing(){
        DispatchQueue.global(qos: .userInitiated).async {
                self.x = UserDefaults.standard.integer(forKey: "xData")
                self.y = UserDefaults.standard.integer(forKey: "yData")
                self.z = UserDefaults.standard.integer(forKey: "zData")
                print(self.x,self.y,self.z)
                let x_val = self.x
                let y_val = self.y
                let z_val = self.z
                let added = x_val*x_val + y_val*y_val + z_val*z_val
                //print(added)
                let Acc = sqrt(Double(added))
                print("total acceleration \(Acc)")
                self.numbers.append(Acc)
                DispatchQueue.main.sync {
                    self.updateGraph()
                    //print(self.i)
                    //self.i = self.i + 1
                }
            }
    }
    
    
    @IBOutlet weak var updated: UILabel!
    @IBAction func bluetooth(_ sender: UIButton)
    {
        microbit.deviceName = "BBC micro:bit [gipov]"
        if (connected_to_device == false)
        {
            print(self.connected_to_device)
            updated.text = "Hello"
            is_connecting = microbit.startScanning()
            print("done scanning")
            microbit.accelerometer(period: periodType)
            func accelerometerSet(period: PeriodType) {
                microbit.accelerometer(period: period)
            }
            sender.setTitle("Disconnect", for: .normal)
            DispatchQueue.global(qos: .userInitiated).async
                {
                    while (self.is_connecting == true)
                    {
                        let words:String! = UserDefaults.standard.string(forKey: "update")
                        if (words == "Firmware revision number = 2.0.0-rc9--g")
                        {
                            print("break")
                            self.is_connecting = false
                        }
                        else
                        {
                            DispatchQueue.main.sync {
                                self.updated.text = words
                            }
                        }
                    }
                    self.updated.text = "You are Connected"
            }
            connected_to_device = true
        }
        else
        {
            is_connecting = false
            connected_to_device = false
            microbit.disconnect()
            self.updated.text = "Disconnected"
            sender.setTitle("Connect", for: .normal)
        }
        
    }
    
    @IBAction func record(_ sender: UIButton) {
        
        //NC.default.addObserver(self, selector: @selector("pressed"), name: Notification.Name("_UIImagePickerControllerUserDidCaptureItem"), object: nil)
        func pressed()
        {
            print("pressed")
        }
        if (connected_to_device == false)
        {
            print("connect to bluetooth first")
            updated.text = "connect to bluetooth first"
            microbit.buttonPress_Disconnect()
        }
        /*else
        {
            
            self.getVal = true
            DispatchQueue.global(qos: .userInitiated).async {
                while (self.getVal == true)
                {
                    self.x = UserDefaults.standard.integer(forKey: "xData")
                    self.y = UserDefaults.standard.integer(forKey: "yData")
                    self.z = UserDefaults.standard.integer(forKey: "zData")
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
                        print(self.i)
                        self.i = self.i + 1
                    }
                }
            }
        }*/
    }
    
    @IBAction func Video(_ sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            //VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
            //let customView = CustomOverlayView()
            let customViewController = CustomOverlayViewController(nibName:"CustomOverlayViewController", bundle: nil)
            let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
            customView.frame = mediaUI.view.frame
            customView.delegate = self
            mediaUI.sourceType = .camera
            mediaUI.showsCameraControls = false
            mediaUI.cameraOverlayView = customView
            mediaUI.mediaTypes = [kUTTypeMovie as String]
            mediaUI.allowsEditing = true
            mediaUI.delegate = self
            self.present(mediaUI, animated: true, completion: {self.mediaUI.cameraOverlayView = customView})
            print("end of video")
        }
        else
        {
            print("camera is not available")
        }
    }
    
    @IBAction func stop(_ sender: UIButton) {
        print("stop")
        self.getVal = false
        DispatchQueue.global(qos: .userInitiated).async{
            //print("here")
            while (self.getVal == false){
                //var previous_time:Double = 0
                let duration = self.player.currentItem!.asset.duration
                let current_time = self.player.currentTime()
                let current_time_seconds = CMTimeGetSeconds(current_time)
                //qiocl
                //let current_time_double = Double(current_time_seconds)
                let length_seconds = CMTimeGetSeconds(duration)
                let int_length_seconds = Int64(length_seconds)
                if (self.chart_pressed == true)
                {
                    print("here")
                    let userSelection = UserDefaults.standard.integer(forKey: "timestamp")
                    let input_time = Int64(userSelection)
                    //print("in dispatchqueue")
                    self.chart_pressed = false
                    //print("getVal loop")
                    if (input_time>=int_length_seconds){
                        print(int_length_seconds)
                        print("why")
                        self.player.seek(to: duration)
                    }
                    else{
                            let time = CMTime(value: input_time, timescale: 1)
                            print("time: \(input_time)")
                            self.player.seek(to: time)

                    }
                }
                else
                {
                    let rangeMid = Double(current_time_seconds)*10
                    let rangeMax = Double(rangeMid)+10 //Double(self.secondsRange)
                    let rangeMin = Double(rangeMid)-10 //Double(self.secondsRange)
                 //   let start = self.numbers[Int(rangeMin)]
                 //   let end = self.numbers[Int(rangeMax)]
                    if(self.player.timeControlStatus == AVPlayerTimeControlStatus.playing){
                        DispatchQueue.main.sync {
                            if (rangeMin<0)
                            {
                                self.chtChart.moveViewToX(0)
                            }
                            else
                            {
                                self.chtChart.moveViewToX(rangeMin)
                                self.chtChart.setVisibleXRangeMaximum(rangeMax-rangeMin)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func reset(_ sender: UIButton) {
        self.numbers = [0]
        self.updateGraph()
        self.getVal = false
        reset = true
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
        chtChart.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(tap_record(notification:)), name: .AVCaptureSessionWasInterrupted, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateGraph(){
        
        var lineChartEntry  = [ChartDataEntry]()
        for i in 0..<self.numbers.count {
            let value = ChartDataEntry(x: Double(i), y: self.numbers[i])
            lineChartEntry.append(value)
        }
        let line1 = LineChartDataSet(values: lineChartEntry, label: "Number")
        line1.setDrawHighlightIndicators(false)
        line1.colors = [NSUIColor.blue]
        chtChart.setVisibleXRangeMaximum(20)
        let data = LineChartData()
        data.addDataSet(line1)
        chtChart.data = data
        chtChart.chartDescription?.text = "Acceleration"
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        chart_pressed = true
        timestamp = entry.x/10
        let rounded_time = Double(round(timestamp))
        print("\(rounded_time)")
        UserDefaults.standard.set(rounded_time, forKey: "timestamp")
    }
    @objc func tap_record(notification: NSNotification) {
        print("pressed")
    }
    
}









extension MicrobitUIController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        print("finished")
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerControllerMediaURL] as? NSURL//,
           // UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
            else { return }
        
        // Handle a movie capture
        //UISaveVideoAtPathToSavedPhotosAlbum(url.path!, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        
        player = AVPlayer(url: url as URL)
        let small_screen = AVPlayerViewController()
        small_screen.view.frame = CGRect (x:0, y:50, width:320, height:250)
        small_screen.player = player
        self.addChildViewController(small_screen)
        self.view.addSubview(small_screen.view)
        small_screen.didMove(toParentViewController: self)
        print("before while loop")
    }
}

extension MicrobitUIController: UINavigationControllerDelegate {
}




