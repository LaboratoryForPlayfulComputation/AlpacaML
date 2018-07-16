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
import CoreML
import CoreData

class MicrobitUIController: UIViewController, MicrobitDelegate, UITextFieldDelegate, ChartViewDelegate, CustomOverlayDelegate {
    var line1 = LineChartDataSet()
    var line2 = LineChartDataSet()
    var line3 = LineChartDataSet()
    var xColors = [UIColor]()
    var yColors = [UIColor]()
    var zColors = [UIColor]()
    var startingValue = 0.0
    var updatedValue = 0.0
    var isFirstVideo = true
    var videoSize = CGRect()
    
    @IBOutlet weak var Arrow: UIImageView!
    var middleTime = 0.0
    var recording = false
    @IBOutlet weak var chtChart: LineChartView!
    @IBOutlet weak var labelMessage: UILabel!
    
    @IBOutlet weak var updated: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    let Name:String = "sportsball" // Placeolder
    
    var timer = Timer()
    let smallScreen = AVPlayerViewController()
    var player = AVPlayer()
    let mediaUI = UIImagePickerController()
    var selectedTimestamp:Double = 0
    var isConnecting = false
    var accelerationObjects:[(Double,Double,Double)] = []
    
    var microbit = Microbit()
    
    var isConnectedToDevice = false
    var reset = false
    var periodType = PeriodType.p1
    var getVal = false
    var chartPressed = false
    var x = 0
    var y = 0
    var z = 0
    var gestureStartTime = 0
    var dragged = false
    
    var accelerationStore = CoreDataAcceleration()
    
    // MARK: View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chtChart.delegate = self
        Arrow.isHidden = true
        let LongTap =  UILongPressGestureRecognizer(target: self, action: #selector(MicrobitUIController.segment(_:)))
        LongTap.minimumPressDuration = 1
        chtChart.addGestureRecognizer(LongTap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK : Bluetooth
    
    @IBAction func bluetooth(_ sender: UIButton) {
        microbit.deviceName = "BBC micro:bit [gepev]"
        if (isConnectedToDevice == false) {
            print(self.isConnectedToDevice)
            updated.text = "Hello"
            isConnecting = microbit.startScanning()
            print("done scanning")
            microbit.accelerometer(period: periodType)
            func accelerometerSet(period: PeriodType) {
                microbit.accelerometer(period: period)
            }
            sender.setTitle("Disconnect", for: .normal)
            DispatchQueue.global(qos: .userInitiated).async {
                while (self.isConnecting == true) {
                    let words:String! = UserDefaults.standard.string(forKey: "update")
                    if (words == "Firmware revision number = 2.0.0-rc9--g") {
                        print("break")
                        self.isConnecting = false
                    } else {
                        DispatchQueue.main.sync {
                            self.updated.text = words
                        }
                    }
                }
                DispatchQueue.main.sync {
                    self.updated.text = "You are Connected"
                }
            }
            isConnectedToDevice = true
        } else {
            isConnecting = false
            isConnectedToDevice = false
            microbit.disconnect()
            self.updated.text = "Disconnected"
            sender.setTitle("Connect", for: .normal)
        }
    }
    
    // MARK: Video Functions
    
    func didCancel(overlayView: CustomOverlayView) {
        mediaUI.cameraOverlayView?.removeFromSuperview()
        mediaUI.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true) {
            print("recording")
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MicrobitUIController.readAndSaveAccelerationData), userInfo: nil, repeats: true)
            mediaUI.startVideoCapture()
            recording = true
        } else {
            print("stop recording")
            mediaUI.stopVideoCapture()
            timer.invalidate()
            recording = false
            mediaUI.dismiss(animated: true, completion: nil)
            Arrow.isHidden = false
        }
    }
    
    @objc func readAndSaveAccelerationData() {
        do {
            let acceleration = try self.microbit.getAccelerometerDataFromMicrobit()
            self.accelerationStore.save(x: acceleration.0,y: acceleration.1,z: acceleration.2, timestamp: NSDate().timeIntervalSinceReferenceDate,sport: self.Name, id: 1)
            self.accelerationObjects.append(acceleration)
        } catch {
            print("No data available from microbit: \(error)")
        }
    }
    
    // MARK: UI Components
    
    @IBAction func Video(_ sender: AnyObject) {
        if (isConnectedToDevice == false) {
            print("connect to bluetooth first")
            updated.text = "connect to bluetooth first" // TODO: [AZ] this should probably be an alert
            microbit.buttonPress_Disconnect()
        } else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            if (isFirstVideo == true) {
                videoSize = mediaUI.view.frame
                isFirstVideo = false
            }
            let customViewController = CustomOverlayViewController()
            let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
            customView.frame = videoSize
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
    
    // TODO: [AZ] do we need a reset button?
    @IBAction func reset(_ sender: UIButton) {
        self.accelerationObjects = [(0.0,0.0,0.0)]
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
    
    // MARK : Graphing functions
    
    @objc func segment(_ sender: UITapGestureRecognizer) {
        let highlighted_label = UIView()
        highlighted_label.isHidden = false
        highlighted_label.backgroundColor = UIColor.blue
        highlighted_label.alpha = 0.5
        
        chtChart.addSubview(highlighted_label)
        chtChart.backgroundColor = UIColor.clear
        
        let held_val = sender.location(in: chtChart)
        var held_val_graph: CGPoint = self.chtChart.valueForTouchPoint(point: held_val, axis: .right)
        let highlight = Highlight(x: Double(held_val_graph.x), dataSetIndex: Int(held_val_graph.x), stackIndex: Int(held_val_graph.x))
        chtChart.highlightValue(highlight)
        if (Double(held_val_graph.x) <= chtChart.lowestVisibleX){
            print("left side")
            chtChart.moveViewToX(chtChart.lowestVisibleX-0.5)
        } else if (Double(held_val_graph.x) >= chtChart.highestVisibleX){
            print("right side")
            chtChart.moveViewToX(chtChart.lowestVisibleX+0.5)
        }
        
        if(sender.state == UIGestureRecognizerState.began){
            held_val_graph = self.chtChart.valueForTouchPoint(point: held_val, axis: .right)
            startingValue = Double(held_val_graph.x)
            self.xColors[Int(self.startingValue)] = UIColor.purple
            self.yColors[Int(self.startingValue)] = UIColor.purple
            self.zColors[Int(self.startingValue)] = UIColor.purple
            self.line1.setColors(self.xColors, alpha: 1)
            self.line2.setColors(self.yColors, alpha: 1)
            self.line3.setColors(self.zColors, alpha: 1)
            print("start \(startingValue)")
        } else if(sender.state == UIGestureRecognizerState.changed){
            //highlighted_label.isHidden = false
            held_val_graph = self.chtChart.valueForTouchPoint(point: held_val, axis: .right)
            updatedValue = Double(held_val_graph.x)
            self.xColors[Int(self.updatedValue)] = UIColor.purple
            self.yColors[Int(self.updatedValue)] = UIColor.purple
            self.zColors[Int(self.updatedValue)] = UIColor.purple
            self.line1.setColors(self.xColors, alpha: 1)
            self.line2.setColors(self.yColors, alpha: 1)
            self.line3.setColors(self.zColors, alpha: 1)
            highlighted_label.center.x = CGFloat(updatedValue - startingValue)
            highlighted_label.frame.size.height = chtChart.frame.size.height
            print("update \(updatedValue)")
        } else if(sender.state == UIGestureRecognizerState.ended){
            print("S-\(startingValue) && E- \(updatedValue)")
        }


    func updateGraph(){
        
        var XChartEntry  = [ChartDataEntry]()
        var YChartEntry = [ChartDataEntry]()
        var ZChartEntry = [ChartDataEntry]()
        
        for i in 0..<self.accelerationObjects.count {
            let x_value = ChartDataEntry(x: Double(i), y: accelerationObjects[i].0)
            let y_value = ChartDataEntry(x: Double(i), y: accelerationObjects[i].1)
            let z_value = ChartDataEntry(x: Double(i), y: accelerationObjects[i].2)
            let blue = UIColor.blue
            let red = UIColor.red
            let green = UIColor.green
            xColors.append(blue)
            yColors.append(red)
            zColors.append(green)
            XChartEntry.append(x_value)
            YChartEntry.append(y_value)
            ZChartEntry.append(z_value)
        }
        
        // make sure lets ok here
        line1 = LineChartDataSet(values: XChartEntry, label: "X values")
        line1.highlightEnabled = true
        line1.drawCirclesEnabled = false
        line1.colors = [NSUIColor.blue]
        line1.drawValuesEnabled = false
        
        line2 = LineChartDataSet(values: YChartEntry, label: "Y values")
        line2.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.colors = [NSUIColor.red]
        
        line3 = LineChartDataSet(values: ZChartEntry, label: "Z values")
        line3.drawValuesEnabled = false
        line3.drawCirclesEnabled = false
        line3.colors = [NSUIColor.green]
        
        chtChart.setVisibleXRangeMaximum(20)
        chtChart.scaleYEnabled = false
        
        let data = LineChartData()
        data.addDataSet(line1)
        data.addDataSet(line2)
        data.addDataSet(line3)
        chtChart.data = data
        chtChart.chartDescription?.text = "Acceleration"
    }
    
    public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        chartPressed = true
        selectedTimestamp = entry.x/10
        let rounded_time = Double(round(selectedTimestamp))
        UserDefaults.standard.set(rounded_time, forKey: "timestamp_selected")
    }
    
    func ending_menu() {
        smallScreen.view.frame = CGRect (x:0, y:50, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/2-50)
        DispatchQueue.global(qos: .userInitiated).async{
            while (self.getVal == false){ // this is always false- why?
                let duration = self.player.currentItem!.asset.duration
                let current_time_seconds = CMTimeGetSeconds(self.player.currentTime())
                let length_seconds = CMTimeGetSeconds(duration)
                let int_length_seconds = Int64(length_seconds)
                
                if (self.chartPressed == true) {
                    let userSelection = UserDefaults.standard.integer(forKey: "timestamp_selected")
                    let input_time = Int64(userSelection)
                    self.chartPressed = false
                    if (input_time >= int_length_seconds) {
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
                                self.Arrow.center = CGPoint(x: 100*(current_time_seconds-self.middleTime) + Double(self.chtChart.center.x), y: Double(self.Arrow.center.y))
                            } else {
                                self.middleTime = current_time_seconds
                                self.chtChart.moveViewToX(rangeMin)
                                self.chtChart.setVisibleXRangeMaximum(21)
                                self.Arrow.center = CGPoint(x: self.chtChart.center.x, y: self.Arrow.center.y)
                                self.chtChart.bringSubview(toFront: self.Arrow)
                            }
                        }
                    }
                }
                self.gestureStartTime = Int(int_length_seconds)
            }
        }
    }
}

extension MicrobitUIController: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerControllerMediaURL] as? NSURL
            else { return }
        player = AVPlayer(url: url as URL)
        smallScreen.player = player
        self.addChildViewController(smallScreen)
        self.view.addSubview(smallScreen.view)
        smallScreen.didMove(toParentViewController: self)
        updateGraph()
        let fetchResult = accelerationStore.fetch(sport: Name)
        print("There are this many records in the database \(fetchResult.count)")
        let numberOne = fetchResult[fetchResult.count - 10]
        print("It looks like this: id \(numberOne.id), sport \(String(describing: numberOne.sport)), timestamp \(numberOne.timestamp), x \(numberOne.xAcceleration), y \(numberOne.yAcceleration), z \(numberOne.zAcceleration)")
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
