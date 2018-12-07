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
    var sport = ""
    var action = ""
    let dtw = DTW()
    var previousClassification: String = "None"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Test \(sport)"
        self.lineChart.delegate = self
        self.segmentList = segmentStore.fetch(sport: sport, gesture: action, trainingSet: true)
        let min_ts = accelerationStore.getMinTimestamp()
        for segment in segmentList {
            let adjustedStart = segment.start_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD + min_ts
            let adjustedStop = segment.stop_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD + min_ts
            let accelerations = self.accelerationStore.fetch(sport: sport, start_ts: adjustedStart, stop_ts: adjustedStop)
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
    }
    
    func classifyChunk() {
        DispatchQueue.global(qos: .userInitiated).async {
            let maxIndex = self.newAccelerations.count - 1
            let test = self.newAccelerations[(maxIndex-self.chunkSize)..<maxIndex]
            let classification = self.dtw.classify(test: Array(test))
            DispatchQueue.main.async {
                if classification.starts(with: "None") || (classification == self.previousClassification) {
                    self.classificationLabel.text = ""
                    self.previousClassification = classification
                } else {
                    self.classificationLabel.text = classification
                    let speechText = classification.split(separator: " ")[0].lowercased()
                    let utterance = AVSpeechUtterance(string: speechText)
                    let synthesizer = AVSpeechSynthesizer()
                    synthesizer.speak(utterance)
                    self.previousClassification = classification
                }
            }
        }
        // make it also talk
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
                    //accelerationStore.save(x: acceleration.0, y: acceleration.1, z: acceleration.2, timestamp: NSDate().timeIntervalSinceReferenceDate, sport: sport, id: 1)
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
