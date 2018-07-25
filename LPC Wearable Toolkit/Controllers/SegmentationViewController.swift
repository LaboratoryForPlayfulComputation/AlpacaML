//
//  SegmentationViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/20/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import Charts
import AVKit

class SegmentationViewController: UIViewController, ChartViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var goodButton: UIButton!
    @IBOutlet weak var badButton: UIButton!
    
    var videoStore = Videos()
    var accelerationStore = Accelerations()
    var accelerationObjects: [(Double, Double, Double)] = []
    var gestureStore = Gestures()
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    let smallScreen = AVPlayerViewController()
    var timeObserverToken: Any?
    var levelObserverToken: Any?
    let ACCELEROMETER_PERIOD = 10.0
    
    var xAccelerationLine = LineChartDataSet()
    var yAccelerationLine = LineChartDataSet()
    var zAccelerationLine = LineChartDataSet()
    var pointsSelected:[Double] = []
    var totalGesturesSelected = 0
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // Make a user settings variable for sports, or allow user to put it in, or pass it around.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lineChart.delegate = self
        let accels = accelerationStore.managedAccelerations // make sure these are ordered by timestamp. This is implemented, but need to verify.
        for accel in accels {
            accelerationObjects.append((accel.xAcceleration, accel.yAcceleration, accel.zAcceleration))
        }
        
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(handleLongPress(recognizer:)))
        recognizer.minimumPressDuration = 1
        recognizer.delegate = self
        lineChart.addGestureRecognizer(recognizer)
        lineChart.scaleYEnabled = false
        
        prepareToPlay()
        updateGraph()
        startObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopObservers()
    }
    
    @IBAction func classifyGestureGood(_ sender: UIButton) {
        totalGesturesSelected = totalGesturesSelected + 1
        gestureStore.save(id: Int64(totalGesturesSelected), gesture: "Gesture", rating: "Good", sport: "Sportball", start_ts: pointsSelected[0], stop_ts: pointsSelected[1])
        // change color of highlighted portion to green
        let start = Int(round(pointsSelected[0]))
        let stop = Int(round(pointsSelected[1]))
        doHighlight(dataSet: xAccelerationLine, color: UIColor.green, start: start, stop: stop)
        doHighlight(dataSet: yAccelerationLine, color: UIColor.green, start: start, stop: stop)
        doHighlight(dataSet: zAccelerationLine, color: UIColor.green, start: start, stop: stop)
        
        pointsSelected = []
        goodButton.isEnabled = false
        badButton.isEnabled = false
        print("How many gestures in database: \(gestureStore.fetchAll().count)")
    }
    
    @IBAction func classifyGestureBad(_ sender: UIButton) {
        totalGesturesSelected = totalGesturesSelected + 1
        gestureStore.save(id: Int64(totalGesturesSelected), gesture: "Gesture", rating: "Bad", sport: "Sportball", start_ts: pointsSelected[0], stop_ts: pointsSelected[1])
        let start = Int(round(pointsSelected[0]))
        let stop = Int(round(pointsSelected[1]))
        doHighlight(dataSet: xAccelerationLine, color: UIColor.red, start: start, stop: stop)
        doHighlight(dataSet: yAccelerationLine, color: UIColor.red, start: start, stop: stop)
        doHighlight(dataSet: zAccelerationLine, color: UIColor.red, start: start, stop: stop)
        
        pointsSelected = []
        goodButton.isEnabled = false
        badButton.isEnabled = false
        print("How many gestures in database: \(gestureStore.fetchAll().count)")
    }
    
    // MARK: Video functions
    
    func prepareToPlay() {
        // get url
        let urlString = videoStore.fetch(sport: "Sportsball")[0].url
        print(urlString ?? "No URL")
        let url = URL(string: urlString!)
        asset = AVAsset(url: url!)
        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
        player = AVPlayer(playerItem: playerItem)
        
        smallScreen.player = player
        self.addChildViewController(smallScreen)
        self.view.addSubview(smallScreen.view)
        smallScreen.didMove(toParentViewController: self)
        smallScreen.view.frame = CGRect (x:0, y:50, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/2-50)
    }
    
    // https://github.com/rdio/hello-ios-swift/blob/master/HelloSwift/HelloViewController.swift
    func startObservers() {
        if (timeObserverToken == nil) {
            let timeScale = CMTimeMake(1, Int32(ACCELEROMETER_PERIOD))
        
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: timeScale, queue: .main) {
                [weak self] time in
                    self?.setChartValues(seconds: Double(CMTimeGetSeconds(time)))
            }
        }
    }
    
    func stopObservers() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    // MARK: Chart functions
    
    func updateGraph() {
        var XChartEntry  = [ChartDataEntry]()
        var YChartEntry = [ChartDataEntry]()
        var ZChartEntry = [ChartDataEntry]()
        
        for i in 0..<self.accelerationObjects.count {
            XChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].0))
            YChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].1))
            ZChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].2))
        }
        
        // make sure lets ok here
        xAccelerationLine = LineChartDataSet(values: XChartEntry, label: "X values")
        xAccelerationLine.highlightEnabled = true
        xAccelerationLine.drawCirclesEnabled = false
        xAccelerationLine.colors = [NSUIColor.black]
        xAccelerationLine.drawValuesEnabled = false
        xAccelerationLine.setDrawHighlightIndicators(true)
        xAccelerationLine.drawHorizontalHighlightIndicatorEnabled = false
        xAccelerationLine.highlightColor = .magenta
        xAccelerationLine.highlightLineWidth = 2
        
        yAccelerationLine = LineChartDataSet(values: YChartEntry, label: "Y values")
        yAccelerationLine.drawValuesEnabled = false
        yAccelerationLine.drawCirclesEnabled = false
        yAccelerationLine.colors = [NSUIColor.blue]
        
        zAccelerationLine = LineChartDataSet(values: ZChartEntry, label: "Z values")
        zAccelerationLine.drawValuesEnabled = false
        zAccelerationLine.drawCirclesEnabled = false
        zAccelerationLine.colors = [NSUIColor.cyan]

        let data = LineChartData()
        data.addDataSet(xAccelerationLine)
        data.addDataSet(yAccelerationLine)
        data.addDataSet(zAccelerationLine)
        lineChart.data = data
        lineChart.setVisibleXRangeMaximum(20)
        lineChart.chartDescription?.text = "Acceleration"
    }
    
    public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let duration = self.player.currentItem!.asset.duration
        let length_seconds = CMTimeGetSeconds(duration)
        let selectedTimestamp = entry.x/ACCELEROMETER_PERIOD
        print("Chart value selected: \(selectedTimestamp)")
        if (selectedTimestamp >= length_seconds) {
            self.player.seek(to: duration)
        } else {
            let time = CMTime(value: CMTimeValue(selectedTimestamp), timescale: 1)
            self.player.seek(to: time)
        }
    }
    
    func setChartValues(seconds: Double) {
        let chartIndex = Double(round(seconds*10))
        if Int(chartIndex) < accelerationObjects.count {
            lineChart.highlightValue(x: chartIndex, y: accelerationObjects[Int(chartIndex)].0 , dataSetIndex: 0, callDelegate: false)
            lineChart.moveViewToX(max(0, chartIndex - 10))
        }
    }
    
    // MARK - Gesture recognition functions
    
     // I've decided that if the user tries to select more than 2 points, we'll just keep the first and latest
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let screenCoordinates = recognizer.location(in: lineChart)
        let chartValue: CGPoint = self.lineChart.valueForTouchPoint(point: screenCoordinates, axis: .right)
        pointsSelected.append(Double(chartValue.x))
        
        if pointsSelected.count > 2 {
            pointsSelected.remove(at: 1)
        }
        if pointsSelected.count == 2 {
            goodButton.isEnabled = true
            badButton.isEnabled = true
            let start = Int(round(pointsSelected[0]))
            let stop = Int(round(pointsSelected[1]))
            doHighlight(dataSet: xAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
            doHighlight(dataSet: yAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
            doHighlight(dataSet: zAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
        } else {
            let start = Int(round(pointsSelected[0]))
            let stop = Int(round(pointsSelected[0])) + 5
            doHighlight(dataSet: xAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
            doHighlight(dataSet: yAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
            doHighlight(dataSet: zAccelerationLine, color: UIColor.magenta, start: start, stop: stop)
        }
    }
    
    // This code only highlights the latest gesture FYI
    func doHighlight(dataSet: LineChartDataSet, color: UIColor, start: Int, stop: Int) {
        var newColors = [UIColor] (repeating: dataSet.colors[0], count: dataSet.entryCount)
        for i in start...stop { // doesn't account for all versions of messing up
            newColors[i] = color
        }
        dataSet.setColors(newColors, alpha: 1)
        lineChart.data?.notifyDataChanged()
        lineChart.notifyDataSetChanged()
    }
}
