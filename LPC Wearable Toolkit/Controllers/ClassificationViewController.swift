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
import AVFoundation

class ClassificationViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    var accelerationStore = Accelerations()
    var segmentStore = Segments()
    var segmentList:[Segment]!
    var isCapturing = false
    
    var newAccelerations: [(Double,Double,Double)] = []
    var xAccelerations: [ChartDataEntry]!
    var yAccelerations: [ChartDataEntry]!
    var zAccelerations: [ChartDataEntry]!
    var isRecording = false
    var chunkSize = 0
    var model:Model?
    let dtw = DTW()
    var previousClassification: String = "None"
    var labels:Array<String>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Test \(model?.name ?? "")"
        self.lineChart.delegate = self
        self.segmentList = segmentStore.fetch(model: model!, trainingSet: true)
        labels = model?.labels
        for segment in segmentList {
            let video = segment.video
            let min_ts = video?.min_ts
            let adjustedStart = segment.start_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD + min_ts!
            let adjustedStop = segment.stop_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD + min_ts!
            let accelerations = self.accelerationStore.fetch(model: model!, start_ts: adjustedStart, stop_ts: adjustedStop)
            let accelerationAsDoubles = accelerations.map({acc in return (acc.xAcceleration, acc.yAcceleration, acc.zAcceleration)})
            dtw.addToTrainingSet(label: segment.rating!, data: accelerationAsDoubles)
        }
        chunkSize = Int(self.getMaxSegmentLength())
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateValueFor(_:)), name: BluetoothNotification.didUpdateValueFor.notification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toggleDataCapture(_ sender: UIButton) {
        isCapturing = !isCapturing
        if (isCapturing) {
            if !BluetoothStore.shared.isMicrobitConnected() {
                let alert = UIAlertController(title: "Bluetooth disconnected", message: "AlpacaML detects that your sensor is no longer connected. Please quit the app to reconnect.", preferredStyle: .alert)
            
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                sender.setTitle("Stop", for: .normal)
                sender.backgroundColor = UIColor(red: 255/255.0, green: 123/255.0, blue: 51/255.0, alpha: 1.0)
            }
        } else {
            sender.setTitle("Go", for: .normal)
            sender.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
        }
    }
    
    // skip max length until next identification, add threshold?
    func classifyChunk() {
        DispatchQueue.global(qos: .userInitiated).async {
            let maxIndex = self.newAccelerations.count - 1
            let test = self.newAccelerations[(maxIndex-self.chunkSize)..<maxIndex]
            let classification = self.dtw.classify(test: Array(test))
            DispatchQueue.main.async {
                let classified = classification.split(separator: "|")[0].lowercased()
                if classified.starts(with: "none") || (classified == self.previousClassification) {
                    self.classificationLabel.text = ""
                    self.previousClassification = classified
                } else {
                    // speak classifications and send them as WebRTC messages
                    self.classificationLabel.text = classification // yes I think we do want to show the full string. right? for now
                    // send a message via WebRTC
                    self.sendWebRTCData(dataToSend: String(classification.split(separator: "|")[0]))
                    // speak the classification
                    let utterance = AVSpeechUtterance(string: classified)
                    let synthesizer = AVSpeechSynthesizer()
                    synthesizer.speak(utterance)
                    self.previousClassification = classified
                }
            }
        }
    }
    
    func sendWebRTCData(dataToSend: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.webRTCClient.sendData(dataToSend.data(using: .utf8)!)
    }
    
    @IBAction func sendAMessageDidTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Send a message to your Scratch project",
                                      message: "This mimics the messages your gestures will send.",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Message to send"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
            guard let msg = alert.textFields?.first?.text else {
                return
            }
            self!.sendWebRTCData(dataToSend: msg)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK - Chart functions
    
    private func updateChart() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.xAccelerations = [ChartDataEntry]()
            self.yAccelerations = [ChartDataEntry]()
            self.zAccelerations = [ChartDataEntry]()
            
            for i in 0..<self.newAccelerations.count {
                self.xAccelerations.append(ChartDataEntry(x: Double(i), y: self.newAccelerations[i].0))
                self.yAccelerations.append(ChartDataEntry(x: Double(i), y: self.newAccelerations[i].1))
                self.zAccelerations.append(ChartDataEntry(x: Double(i), y: self.newAccelerations[i].2))
            }
            
            let xline = LineChartDataSet(values: self.xAccelerations, label: "X Values")
            xline.drawCirclesEnabled = false
            xline.colors = [NSUIColor.black]
            xline.drawValuesEnabled = false
            
            let yline = LineChartDataSet(values: self.yAccelerations, label: "Y Values")
            yline.drawValuesEnabled = false
            yline.drawCirclesEnabled = false
            yline.colors = [NSUIColor.blue]
            
            let zline = LineChartDataSet(values: self.zAccelerations, label: "Z Values")
            zline.drawValuesEnabled = false
            zline.drawCirclesEnabled = false
            zline.colors = [NSUIColor.cyan]
            
            let data = LineChartData()
            data.addDataSet(xline)
            data.addDataSet(yline)
            data.addDataSet(zline)
            DispatchQueue.main.async {
                self.lineChart.data = data
                self.lineChart.setVisibleXRangeMaximum(50)
                self.lineChart.chartDescription?.text = "Acceleration"
                
                self.lineChart.data?.notifyDataChanged()
                self.lineChart.notifyDataSetChanged()
                
                self.lineChart.moveViewToX(Double(self.newAccelerations.count - 25))
            }
        }
    }
    
    @objc func onDidUpdateValueFor(_ notification: Notification) {
        if isCapturing {
            if let userInfo = notification.userInfo {
                if let accelerations = userInfo["acceleration"] as? [(Double, Double, Double)] {
                    newAccelerations.append(contentsOf: accelerations)
                    // TODO: what do we want to save from here?
                    //accelerationStore.save(x: acceleration.0, y: acceleration.1, z: acceleration.2, timestamp: NSDate().timeIntervalSinceReferenceDate, sport: sport,  id: 1)
                    updateChart()
                    if newAccelerations.count > chunkSize {
                        classifyChunk()
                    }
                }
            }
        }
    }
    
    // MARK - Gesture recognition code
    
    func getMaxSegmentLength() -> Double {
        let longest = segmentList.max(by: {g1, g2 in (g1.stop_ts - g1.start_ts) < (g2.stop_ts - g2.start_ts)} )
        print("Start: \(String(describing: longest?.start_ts)), Stop: \(String(describing: longest?.stop_ts))")
        return (longest?.stop_ts)! - (longest?.start_ts)!
    }
    
}
