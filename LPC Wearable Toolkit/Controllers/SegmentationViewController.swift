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
import MobileCoreServices
import Photos

class SegmentationViewController: UIViewController, ChartViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CustomOverlayDelegate {
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var goodButton: UIButton!
    @IBOutlet weak var badButton: UIButton!
    @IBOutlet weak var noneButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    
    var videoCaptureController: UIImagePickerController!
    var videoStore = Videos()
    var accelerationStore = Accelerations()
    var accelerationObjects: [Acceleration] = []
    var segmentStore = Segments()
    var recording = false
    var timer = Timer()
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    let smallScreen = AVPlayerViewController()
    var timeObserverToken: Any?
    var levelObserverToken: Any?
    
    var xAccelerationLine = LineChartDataSet()
    var yAccelerationLine = LineChartDataSet()
    var zAccelerationLine = LineChartDataSet()
    var xColors: [UIColor]!
    var yColors: [UIColor]!
    var zColors: [UIColor]!
    var pointsSelected:[Double] = []
    var totalGesturesSelected = 0
    
    var hasVideo = false
    var sport = ""
    var action = ""
    var savedVideo:Video!
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // Make a user settings variable for sports, or allow user to put it in, or pass it around.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Train \(sport)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // maybe an issue for current setup?
        stopObservers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "library" ) {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! LibraryCollectionViewController
            print("Selected sport: \(sport)")
            destinationViewController.sport = sport
        }
    }
 
    @IBAction func labelSegmentGood(_ sender: UIButton) {
        totalGesturesSelected = totalGesturesSelected + 1
        segmentStore.save(id: Int64(totalGesturesSelected), gesture: action, rating: "Good", sport: sport, start_ts: pointsSelected[0], stop_ts: pointsSelected[1], inTrainingSet: true, video: savedVideo)
        // change color of highlighted portion to green
        let start = Int(round(pointsSelected[0]))
        let stop = Int(round(pointsSelected[1]))
        doHighlight(color: UIColor.green, start: start, stop: stop)
        
        pointsSelected = []
        goodButton.isEnabled = false
        badButton.isEnabled = false
        noneButton.isEnabled = false
        print("How many gestures in database: \(segmentStore.fetchAll().count)")
    }
    
    @IBAction func labelSegmentNone(_ sender: UIButton) {
        totalGesturesSelected = totalGesturesSelected + 1
        segmentStore.save(id: Int64(totalGesturesSelected), gesture: action, rating: "None", sport: sport, start_ts: pointsSelected[0], stop_ts: pointsSelected[1], inTrainingSet: true, video: savedVideo)
        let start = Int(round(pointsSelected[0]))
        let stop = Int(round(pointsSelected[1]))
        doHighlight(color: UIColor.brown, start: start, stop: stop)
        
        pointsSelected = []
        goodButton.isEnabled = false
        badButton.isEnabled = false
        noneButton.isEnabled = false
        print("How many gestures in database: \(segmentStore.fetchAll().count)")
    }
    
    @IBAction func labelSegmentBad(_ sender: UIButton) {
        totalGesturesSelected = totalGesturesSelected + 1
        segmentStore.save(id: Int64(totalGesturesSelected), gesture: action, rating: "Bad", sport: sport, start_ts: pointsSelected[0], stop_ts: pointsSelected[1], inTrainingSet: true, video: savedVideo)
        let start = Int(round(pointsSelected[0]))
        let stop = Int(round(pointsSelected[1]))
        doHighlight(color: UIColor.red, start: start, stop: stop)
        
        pointsSelected = []
        goodButton.isEnabled = false
        badButton.isEnabled = false
        noneButton.isEnabled = false
        print("How many gestures in database: \(segmentStore.fetchAll().count)")
    }
    
    
    // MARK: Video functions
    
    func prepareToPlay(urlString: String) {
        // get url
        print(urlString )
        let url = URL(string: urlString)
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
            let timeScale = CMTimeMake(1, Int32(BluetoothStore.shared.ACCELEROMETER_PERIOD))
            
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
    
    @IBAction func captureData(_ sender: UIButton) {
        if !BluetoothStore.shared.isMicrobitConnected() {
            // do popover
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            videoCaptureController = UIImagePickerController()
            let customViewController = CustomOverlayViewController()
            let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
            customView.frame = videoCaptureController.view.frame
            customView.delegate = self
            videoCaptureController.sourceType = .camera
            videoCaptureController.showsCameraControls = false
            videoCaptureController.mediaTypes = [kUTTypeMovie as String]
            videoCaptureController.delegate = self
            videoCaptureController.videoMaximumDuration = 600.0
            
            videoCaptureController.cameraOverlayView = customView
            present(videoCaptureController, animated: true, completion: {self.videoCaptureController.cameraOverlayView = customView})
        } else {
            print("Camera is not available")
        }
    }
    
    // tutorial: https://stackoverflow.com/questions/29482738/swift-save-video-from-nsurl-to-user-camera-roll
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL
        var finalURL = ""
        if let url = urlOfVideo {
        PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)}, completionHandler: {saved, error in
                if saved {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                    PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                        let newObj = avurlAsset as! AVURLAsset
                        print("Old URL: \(url.absoluteString ?? "")")
                        print("New URL: \(newObj.url.absoluteString)")
                        finalURL = newObj.url.absoluteString
                        self.savedVideo = self.videoStore.save(name: self.sport, url: finalURL, accelerations: self.accelerationObjects)
                    })
                } else if error != nil {
                    let alertController = UIAlertController(title: "Your video was not saved", message: error.unsafelyUnwrapped.localizedDescription, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            })

            // [AZ] NOTE: We are using finalURL here, but I saw some stuff on stack overflow that suggested this url might change. not sure if true.
            
            videoButton.isHidden = true
            libraryButton.isHidden = true
            importButton.isHidden = true
            
            prepareGraph()
            prepareToPlay(urlString: url.absoluteString!)
            updateGraph()
            startObservers()
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func didCancel(overlayView: CustomOverlayView) {
        videoCaptureController.cameraOverlayView?.removeFromSuperview()
        videoCaptureController.stopVideoCapture()
        timer.invalidate()
        videoCaptureController.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true) {
            timer = Timer.scheduledTimer(timeInterval: 1.0/BluetoothStore.shared.ACCELEROMETER_PERIOD, target: self, selector: #selector(self.readAndSaveAccelerationData), userInfo: nil, repeats: true)
            videoCaptureController.startVideoCapture()
            recording = true
        } else {
            videoCaptureController.stopVideoCapture()
            timer.invalidate()
            recording = false
            videoCaptureController.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func readAndSaveAccelerationData() {
        do {
            let acceleration = try BluetoothStore.shared.getAccelerometerDataFromMicrobit()
            print(acceleration)
            let acc_obj = self.accelerationStore.save(x: acceleration.0,y: acceleration.1,z: acceleration.2, timestamp: NSDate().timeIntervalSinceReferenceDate,sport: sport)
            
            self.accelerationObjects.append(acc_obj!)
        } catch {
            print("No data available from microbit: \(error)")
        }
    }
    
    // MARK: Chart functions
    
    func prepareGraph() {
        self.lineChart.delegate = self
        print("previous accels.lngth \(accelerationObjects.count)")
        
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(handleLongPress(recognizer:)))
        recognizer.minimumPressDuration = 1
        recognizer.delegate = self
        lineChart.addGestureRecognizer(recognizer)
        lineChart.scaleYEnabled = false
    }
    
    func updateGraph() {
        var XChartEntry  = [ChartDataEntry]()
        var YChartEntry = [ChartDataEntry]()
        var ZChartEntry = [ChartDataEntry]()
        
        for i in 0..<self.accelerationObjects.count {
            XChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].xAcceleration))
            YChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].yAcceleration))
            ZChartEntry.append(ChartDataEntry(x: Double(i), y: accelerationObjects[i].zAcceleration))
        }
        
        // make sure lets ok here
        xAccelerationLine = LineChartDataSet(values: XChartEntry, label: "X values")
        xAccelerationLine.highlightEnabled = true
        xAccelerationLine.drawCirclesEnabled = false
        xAccelerationLine.colors = [NSUIColor.black]
        xColors = [UIColor] (repeating: NSUIColor.black, count: accelerationObjects.count)
        xAccelerationLine.drawValuesEnabled = false
        xAccelerationLine.setDrawHighlightIndicators(true)
        xAccelerationLine.drawHorizontalHighlightIndicatorEnabled = false
        xAccelerationLine.highlightColor = .magenta
        xAccelerationLine.highlightLineWidth = 2
        
        yAccelerationLine = LineChartDataSet(values: YChartEntry, label: "Y values")
        yAccelerationLine.drawValuesEnabled = false
        yAccelerationLine.drawCirclesEnabled = false
        yAccelerationLine.colors = [NSUIColor.blue]
        yColors = [UIColor] (repeating: NSUIColor.blue, count: accelerationObjects.count)
        
        zAccelerationLine = LineChartDataSet(values: ZChartEntry, label: "Z values")
        zAccelerationLine.drawValuesEnabled = false
        zAccelerationLine.drawCirclesEnabled = false
        zAccelerationLine.colors = [NSUIColor.cyan]
        zColors = [UIColor] (repeating: NSUIColor.cyan, count: accelerationObjects.count)
        
        let data = LineChartData()
        data.addDataSet(xAccelerationLine)
        data.addDataSet(yAccelerationLine)
        data.addDataSet(zAccelerationLine)
        lineChart.data = data
        lineChart.setVisibleXRangeMaximum(2*BluetoothStore.shared.ACCELEROMETER_PERIOD)
        lineChart.chartDescription?.text = "Acceleration"
    }
    
    public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let duration = self.player.currentItem!.asset.duration
        let length_seconds = CMTimeGetSeconds(duration)
        let selectedTimestamp = entry.x/BluetoothStore.shared.ACCELEROMETER_PERIOD
        print("Chart value selected: \(selectedTimestamp)")
        if (selectedTimestamp >= length_seconds) {
            self.player.seek(to: duration)
        } else {
            let time = CMTime(value: CMTimeValue(selectedTimestamp), timescale: 1)
            self.player.seek(to: time)
        }
    }
    
    func setChartValues(seconds: Double) {
        let chartIndex = Double(round(seconds*BluetoothStore.shared.ACCELEROMETER_PERIOD))
        if Int(chartIndex) < accelerationObjects.count {
            lineChart.highlightValue(x: chartIndex, y: accelerationObjects[Int(chartIndex)].xAcceleration , dataSetIndex: 0, callDelegate: false)
            lineChart.moveViewToX(max(0, chartIndex - BluetoothStore.shared.ACCELEROMETER_PERIOD))
        }
    }
    
    // MARK - Gesture recognition functions
    
    // I've decided that if the user tries to select more than 2 points, we'll just keep the first and latest
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let screenCoordinates = recognizer.location(in: lineChart)
        let chartValue: CGPoint = self.lineChart.valueForTouchPoint(point: screenCoordinates, axis: .right)
        print("Chart value: \(chartValue)")
        pointsSelected.append(Double(chartValue.x))
        if pointsSelected.count > 2 {
            pointsSelected.remove(at: 1)
        }
        if pointsSelected.count == 2 {
            pointsSelected.sort()
            goodButton.isEnabled = true
            badButton.isEnabled = true
            noneButton.isEnabled = true
            let start = Int(round(pointsSelected[0]))
            let stop = Int(round(pointsSelected[1]))
            doHighlight(color: UIColor.magenta, start: start, stop: stop)
        } else {
            let start = Int(round(pointsSelected[0]))
            let stop = Int(round(pointsSelected[0])) + 5
            doHighlight(color: UIColor.magenta, start: start, stop: stop)
        }
    }
    
    func doHighlight(color: UIColor, start: Int, stop: Int) {
        for i in start...stop {
            xColors[i] = color
            yColors[i] = color
            zColors[i] = color
        }
        xAccelerationLine.setColors(xColors, alpha: 1)
        yAccelerationLine.setColors(yColors, alpha: 1)
        zAccelerationLine.setColors(zColors, alpha: 1)
        lineChart.data?.notifyDataChanged()
        lineChart.notifyDataSetChanged()
    }

}

extension SegmentationViewController {
    @IBAction func cancelToSegmentationViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func finishPickingVideo(_ segue: UIStoryboardSegue) {
        guard let libraryCollectionViewController = segue.source as? LibraryCollectionViewController,
            let chosenVideo = libraryCollectionViewController.chosenVideo else {
                return
        }
        // TODO: play video
    }
}
