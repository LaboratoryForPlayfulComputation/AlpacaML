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
    var first_video = true
    var video_size = CGRect()
    @IBOutlet weak var Arrow: UIImageView!
     var middle_time = 0.0
    var recording = false
    @IBOutlet weak var chtChart: LineChartView!
    var i = 0
    var timer = Timer()
    let small_screen = AVPlayerViewController()
    var player = AVPlayer()
    let mediaUI = UIImagePickerController()
    var timestamp:Double = 0
    var is_connecting = false
    var X_acc:[Double] = []
    var Y_acc:[Double] = []
    var Z_acc:[Double] = []
    var microbit = Microbit()
    var connected_to_device = false
    var reset = false
    var periodType = PeriodType.p1
    var getVal = false
    var chart_pressed = false
    var x = 0
    var y = 0
    var z = 0
    var gesture_name = ""
    var gesture_start_time = 0
    var gesture_end_time = 0
    var dragged = false
    var change_background = false
    
    func didCancel(overlayView: CustomOverlayView) {
        mediaUI.cameraOverlayView?.removeFromSuperview()
        mediaUI.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true)
        {
            print("recording")
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MicrobitUIController.graphing), userInfo: nil, repeats: true)
            mediaUI.startVideoCapture()
            recording = true
        }
        else
        {
            print("stop recording")
            mediaUI.stopVideoCapture()
            timer.invalidate()
            recording = false
            mediaUI.dismiss(animated: true, completion: nil)
            Arrow.isHidden = false
        }
    }
    
    @objc func graphing(){
        DispatchQueue.global(qos: .userInitiated).async {
                self.x = UserDefaults.standard.integer(forKey: "xData")
                self.y = UserDefaults.standard.integer(forKey: "yData")
                self.z = UserDefaults.standard.integer(forKey: "zData")
                print(self.x,self.y,self.z)
                let x_val = Double(self.x)
                let y_val = Double(self.y)
                let z_val = Double(self.z)
                self.X_acc.append(x_val)
                self.Y_acc.append(y_val)
                self.Z_acc.append(z_val)
                DispatchQueue.main.sync {
                    self.updateGraph()
                }
            }
    }
    
    
    @IBOutlet weak var updated: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
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
                    DispatchQueue.main.sync {
                        self.updated.text = "You are Connected"
                    }
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
    
    @IBAction func Video(_ sender: AnyObject) {
        X_acc = [0]
        Y_acc = [0]
        Z_acc = [0]
        if (connected_to_device == false)
        {
            print("connect to bluetooth first")
            updated.text = "connect to bluetooth first"
            microbit.buttonPress_Disconnect()
            X_acc = [0]
            Y_acc = [0]
            Z_acc = [0]
        } else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                if (first_video == true){
                    video_size = mediaUI.view.frame
                    first_video = false
                }
                let customViewController = CustomOverlayViewController()
                let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
                customView.frame = video_size
                customView.delegate = self
                mediaUI.sourceType = .camera
                mediaUI.showsCameraControls = false
                mediaUI.cameraOverlayView = customView
                mediaUI.mediaTypes = [kUTTypeMovie as String]
                mediaUI.allowsEditing = true
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: {self.mediaUI.cameraOverlayView = customView})
                print("end of video")
            } else {
                print("camera is not available")
            }
    }
    
    @IBAction func reset(_ sender: UIButton) {
        self.X_acc = [0]
        self.Y_acc = [0]
        self.Z_acc = [0]
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
        Arrow.isHidden = true
        let DoubleTap =  UILongPressGestureRecognizer(target: self, action: #selector(MicrobitUIController.segment(_:)))
        DoubleTap.minimumPressDuration = 1
        chtChart.addGestureRecognizer(DoubleTap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func segment(_ sender: UITapGestureRecognizer)
    {
        let held_val = sender.location(in: chtChart)
        let held_val_graph: CGPoint = self.chtChart.valueForTouchPoint(point: held_val, axis: .right)
        let touchPoint = sender.location(in: self.view)
        
        /*if held_vals.contains(touchPoint) {
            //chtChart.drawGridBackgroundEnabled = true
            //chtChart.gridBackgroundColor = UIColor.orange
            
            
            //chtChart.backgroundColor = UIColor.orange
        }*/
        //chtChart.backgroundColor = UIColor.orange
        print("held\(held_val_graph)")
    }
    
    
/*    func panDetected(_ sender: UITapGestureRecognizer){
        let touchPoint = sender.location(in: self.view)
        
        if chtChart.frame.contains(touchPoint){
            chtChart.gridBackgroundColor = UIColor.orange
            chtChart.drawGridBackgroundEnabled = true

        }
        chtChart.drawGridBackgroundEnabled = false

    }*/
    
    func updateGraph(){
        
        var XChartEntry  = [ChartDataEntry]()
        var YChartEntry = [ChartDataEntry]()
        var ZChartEntry = [ChartDataEntry]()
        for i in 0..<self.X_acc.count {
            let x_value = ChartDataEntry(x: Double(i), y: self.X_acc[i])
            let y_value = ChartDataEntry(x:Double(i), y: self.Y_acc[i])
            let z_value = ChartDataEntry(x:Double(i), y: self.Z_acc[i])
            XChartEntry.append(x_value)
            YChartEntry.append(y_value)
            ZChartEntry.append(z_value)
        }
        let line1 = LineChartDataSet(values: XChartEntry, label: "X values")
        let line2 = LineChartDataSet(values: YChartEntry, label: "Y values")
        let line3 = LineChartDataSet(values: ZChartEntry, label: "Z values")
        line1.highlightEnabled = true
        line1.drawCirclesEnabled = false
        line1.colors = [NSUIColor.blue]
        line1.drawValuesEnabled = false
        line2.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.colors = [NSUIColor.red]
        line3.drawValuesEnabled = false
        line3.drawCirclesEnabled = false
        line3.colors = [NSUIColor.green]
        chtChart.setVisibleXRangeMaximum(20)
        let data = LineChartData()
        data.addDataSet(line1)
        data.addDataSet(line2)
        data.addDataSet(line3)
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
    

    
    
    func ending_menu(){
        NotificationCenter.default.addObserver(self, selector: #selector(MicrobitUIController.rotated_video), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        DispatchQueue.global(qos: .userInitiated).async{
            while (self.getVal == false){
                let duration = self.player.currentItem!.asset.duration
                let current_time = self.player.currentTime()
                let current_time_seconds = CMTimeGetSeconds(current_time)
                let length_seconds = CMTimeGetSeconds(duration)
                let int_length_seconds = Int64(length_seconds)
                if (self.chart_pressed == true) {
                    let userSelection = UserDefaults.standard.integer(forKey: "timestamp")
                    let input_time = Int64(userSelection)
                    self.chart_pressed = false
                    if (input_time>=int_length_seconds){
                        print(int_length_seconds)
                        self.player.seek(to: duration)
                    } else {
                        let time = CMTime(value: input_time, timescale: 1)
                        self.player.seek(to: time)
                    }
                } else {
                    let rangeMid = Double(current_time_seconds)*10
                    let rangeMax = Double(rangeMid)+10
                    let rangeMin = Double(rangeMid)-10
                    if(self.player.timeControlStatus == AVPlayerTimeControlStatus.playing){
                        DispatchQueue.main.sync {
                            let chart_left = self.chtChart.center.x - self.chtChart.frame.size.width/2
                            if (rangeMin<0) {
                                self.chtChart.moveViewToX(0)
                                self.Arrow.center = CGPoint(x: 100*current_time_seconds + Double(chart_left) + Double(self.chtChart.frame.width/6), y: Double(self.Arrow.center.y))
                            } else if (rangeMax>10*length_seconds){
                                self.Arrow.center = CGPoint(x: 100*(current_time_seconds-self.middle_time) + Double(self.chtChart.center.x), y: Double(self.Arrow.center.y))
                                print(UIScreen.main.bounds.width)
                                print(self.chtChart.frame.width/6)
                                print(self.chtChart.frame.width)
                            } else {
                                self.middle_time = current_time_seconds
                                self.chtChart.moveViewToX(rangeMin)
                                self.chtChart.setVisibleXRangeMaximum(rangeMax-rangeMin+1)
                                self.Arrow.center = CGPoint(x: self.chtChart.center.x, y: self.Arrow.center.y)
                                print(self.Arrow.center)
                                self.chtChart.bringSubview(toFront: self.Arrow)
                            }
                        }
                    }
                }
                self.gesture_start_time = Int(int_length_seconds)
                //self.gesture_end_time = Int(end_time)
                print(self.gesture_start_time,self.gesture_end_time)

                /*if(int_length_seconds != -1){
                    if(self.chart_pressed == true){
                        let userSelection = UserDefaults.standard.integer(forKey: "timestamp")
                        let end_time = Int64(userSelection)
                    //}
                    //let i = int_length_seconds
                        for i in int_length_seconds..<end_time{
                            self.gesture_name = "user input"
                        }
                        
                        self.gesture_start_time = Int(int_length_seconds)
                        self.gesture_end_time = Int(end_time)
                        print(self.gesture_start_time,self.gesture_end_time)

                            
                        
                    }
                }*/
            }
        }
    }
    @objc func rotated_video() -> Bool {
        let chart_left = chtChart.center.x - chtChart.frame.size.width/2
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            
            small_screen.view.frame = CGRect(x:0, y:chtChart.center.y - chtChart.frame.height/2, width: chart_left-10, height: UIScreen.main.bounds.height - chtChart.frame.size.height - 10)
            return true
        }
        
        else if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            small_screen.view.frame = CGRect (x:0, y:50, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/2-50)
            return false
        }
        else
        {
            guard let window = self.view.window
                else {return false}
            if (window.frame.width>window.frame.height)
            {
                print("width")
                small_screen.view.frame = CGRect(x:0, y:chtChart.center.y - chtChart.frame.height/2, width: chart_left-10, height: UIScreen.main.bounds.height - chtChart.frame.size.height - 10)
                return true
            }
            else
            {
                print("height")
                small_screen.view.frame = CGRect (x:0, y:50, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/2-50)
                return false
            }
        }
    }
}

extension MicrobitUIController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerControllerMediaURL] as? NSURL
            else { return }
        player = AVPlayer(url: url as URL)
        small_screen.player = player
        self.addChildViewController(small_screen)
        self.view.addSubview(small_screen.view)
        small_screen.didMove(toParentViewController: self)
        ending_menu()
    }
}

extension MicrobitUIController: UINavigationControllerDelegate {
}

extension UIImagePickerController
{
    override open var shouldAutorotate: Bool {
        return true
    }
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
}




