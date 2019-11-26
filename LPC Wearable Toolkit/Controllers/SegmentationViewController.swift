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
import AVFoundation

class SegmentationViewController: UIViewController, ChartViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CustomOverlayDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var labelPicker: UIPickerView!
    @IBOutlet weak var assignLabelButton: UIButton!
    
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var libraryLabel: UILabel!
    @IBOutlet weak var importLabel: UILabel!
    
    var videoCaptureController: UIImagePickerController!
    var videoStore = Videos()
    var accelerationStore = Accelerations()
    var accelerationObjects: [Acceleration] = []
    var segmentStore = Segments()
    var segmentObjects: [Segment] = []
    var recording = false
    var timer:Timer!
    var editingSegment = false
    var curSegment:Segment!
    
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
    var totalActionsSelected = 0
    
    var hasVideo = false
    var model:Model!
    var labels:Array<String>!
    var selectedLabel = ""
    var savedVideo:Video!
    var videoName = ""
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // Make a user settings variable for sports, or allow user to put it in, or pass it around.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Train \(model.name ?? "")"
        self.importButton.isEnabled = false
        self.assignLabelButton.isEnabled = false
        
        self.labelPicker.delegate = self
        self.labelPicker.dataSource = self
        
        labels = model.labels
        labelPicker.isHidden = true
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        recognizer.numberOfTapsRequired = 2
        lineChart.addGestureRecognizer(recognizer)
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
    
    // need to do something in here for handling sensor disconnected
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "library" ) {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! LibraryCollectionViewController
            print("Selected model: \(model.name ?? "")")
            destinationViewController.model = model
        }
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
                self?.setChartValues(seconds: Double(CMTimeGetSeconds(time))) // seems to round
            }
        }
    }
    
    func stopObservers() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return labels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return labels[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLabel = labels[row]
        if hasVideo {
            if(pointsSelected.count > 0 ) {
                assignLabelButton.isEnabled = true
                assignLabelButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            }
            if (editingSegment) { // nil check
                if (selectedLabel != curSegment.rating) {
                    assignLabelButton.isEnabled = true
                    assignLabelButton.setTitle("Assign", for: .normal)
                    assignLabelButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
                } else {
                    assignLabelButton.isEnabled = true
                    assignLabelButton.setTitle("Delete", for: .normal)
                    assignLabelButton.backgroundColor = UIColor.red
                }
            }
        }
    }
    
    // we may want to rename this eventually
    @IBAction func assignCategoryToSegment(_ sender: UIButton) {
        pointsSelected.sort()
        let last = pointsSelected.count - 1
        let start = round(pointsSelected[0])
        let stop = round(pointsSelected[last])
        if(!editingSegment) {
            print("Text == assign")
            totalActionsSelected = totalActionsSelected + 1
            let curSegment = segmentStore.save(id: Int64(totalActionsSelected), model: model, rating: selectedLabel, start_ts: start, stop_ts: stop, inTrainingSet: true, video: savedVideo)
            segmentObjects.append(curSegment)
            doHighlight(color: UIColor.green, start: Int(start), stop: Int(stop)) // should fix this to hover and it'll tell you what you did? or something.
            pointsSelected = []
            assignLabelButton.isEnabled = false
            assignLabelButton.backgroundColor = UIColor.lightGray
            print("How many actions in databse :\(segmentStore.fetchAll().count)")
        } else if (editingSegment && (selectedLabel == curSegment.rating)) {
            print("Text == delete")
            print("Segment Objects before delete: \(segmentObjects.count)")
            segmentStore.deleteOne(segment: curSegment)
            segmentObjects = savedVideo.segments?.allObjects as! [Segment]
            print("Segment Objects after delete: \(segmentObjects.count)")
            undoHighlight(start: Int(start), stop: Int(stop))
            pointsSelected = []
            assignLabelButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            assignLabelButton.isEnabled = false
            assignLabelButton.setTitle("Assign", for: .normal)
            assignLabelButton.backgroundColor = UIColor.lightGray
            editingSegment = !editingSegment
        } else if (editingSegment && (selectedLabel != curSegment.rating)) {
            print("Text == assign")
            curSegment.rating = selectedLabel
            doHighlight(color: UIColor.green, start: Int(start), stop: Int(stop))
            
            pointsSelected = []
            assignLabelButton.isEnabled = false
            assignLabelButton.setTitle("Assign", for: .normal)
            assignLabelButton.backgroundColor = UIColor.lightGray
            editingSegment = !editingSegment
        }
        self.pickerView(labelPicker, didSelectRow: 0, inComponent: 0)
    }
    
    @IBAction func captureData(_ sender: UIButton) {
        if !BluetoothStore.shared.isMicrobitConnected() {
            let alert = UIAlertController(title: "Bluetooth disconnected", message: "AlpacaML detects that your sensor is no longer connected. Please quit the app to reconnect.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let alert = UIAlertController(title: "Front or Back?", message: "Would you like to use the front-facing camera or the back-facing camera?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Front", style: .default, handler: { action in
                self.videoCaptureController = UIImagePickerController()
                let customViewController = CustomOverlayViewController()
                let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
                customView.frame = self.videoCaptureController.view.frame
                customView.delegate = self
                self.videoCaptureController.sourceType = .camera
                self.videoCaptureController.showsCameraControls = false
                self.videoCaptureController.mediaTypes = [kUTTypeMovie as String]
                self.videoCaptureController.delegate = self
                self.videoCaptureController.videoMaximumDuration = 600.0
                self.videoCaptureController.cameraDevice = UIImagePickerController.CameraDevice.front

                self.present(self.videoCaptureController, animated: true, completion: {self.videoCaptureController.cameraOverlayView = customView})
            }))
            alert.addAction(UIAlertAction(title: "Back", style: .default, handler: { action in
                self.videoCaptureController = UIImagePickerController()
                let customViewController = CustomOverlayViewController()
                let customView:CustomOverlayView = customViewController.view as! CustomOverlayView
                customView.frame = self.videoCaptureController.view.frame
                customView.delegate = self
                self.videoCaptureController.sourceType = .camera
                self.videoCaptureController.showsCameraControls = false
                self.videoCaptureController.mediaTypes = [kUTTypeMovie as String]
                self.videoCaptureController.delegate = self
                self.videoCaptureController.videoMaximumDuration = 600.0
                self.videoCaptureController.cameraDevice = UIImagePickerController.CameraDevice.rear
                
                self.present(self.videoCaptureController, animated: true, completion: {self.videoCaptureController.cameraOverlayView = customView})

            }))
            self.present(alert, animated: true, completion: nil)
            
            
        } else {
            print("Camera is not available")
        }
    }
    
    // tutorial: https://stackoverflow.com/questions/29482738/swift-save-video-from-nsurl-to-user-camera-roll
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL
        var finalURL = ""

        if let url = urlOfVideo {
            do {
                try PHPhotoLibrary.shared().performChangesAndWait({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)
                })
                
            } catch let error {
                let alertController = UIAlertController(title: "Your video was not saved", message: error.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
            PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                let newObj = avurlAsset as! AVURLAsset
                print("Old URL: \(url.absoluteString ?? "")")
                print("New URL: \(newObj.url.absoluteString)")
                finalURL = newObj.url.absoluteString
            })

            videoButton.isHidden = true
            libraryButton.isHidden = true
            importButton.isHidden = true
            videoLabel.isHidden = true
            libraryLabel.isHidden = true
            importLabel.isHidden = true
            labelPicker.isHidden = false
            hasVideo = true
            prepareGraph()
            prepareToPlay(urlString: url.absoluteString!)
            updateGraph()
            startObservers()
        }
        picker.dismiss(animated: true, completion: nil)
        
        let numVideos = self.videoStore.countAll(model: model)
        let alertController = UIAlertController(title: "Your video was successfully saved. Please enter a video name or use the default name.", message: nil, preferredStyle: .alert)
        let defaultName = self.model.name ?? "" + " video " + String(numVideos + 1)
        alertController.addTextField {(textField) in
            textField.text = defaultName
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] (_) in
            let textField = alertController?.textFields![0]
            self.videoName = textField!.text!
            print("video name: \(self.videoName)")
            self.savedVideo = self.videoStore.save(model: self.model, name: self.videoName, url: finalURL, accelerations: self.accelerationObjects)
            
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func didCancel(overlayView: CustomOverlayView) {
        videoCaptureController.cameraOverlayView?.removeFromSuperview()
        videoCaptureController.stopVideoCapture()
        // fails on cancel
        if (timer != nil) {
            timer.invalidate()
        }
        videoCaptureController.dismiss(animated: true, completion: nil)
    }
    
    func didShoot(overlayView: CustomOverlayView) {
        if (recording != true) {
            guard timer == nil else { return }
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
            
            // DEBUG HERE
            let acc_obj = self.accelerationStore.save(x: acceleration.0,y: acceleration.1,z: acceleration.2, model: model, timestamp: NSDate().timeIntervalSinceReferenceDate)
            // print something here
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
            print("time: \(time.seconds)")
            self.player.seek(to: time)
        }
    }
    
    func setChartValues(seconds: Double) {
        print("seconds: \(seconds)") // this seems to be printing out the wrong thing
        let chartIndex = Double(round(seconds*BluetoothStore.shared.ACCELEROMETER_PERIOD))
        print("chart index: \(chartIndex)")
        if Int(chartIndex) < accelerationObjects.count {
            lineChart.highlightValue(x: chartIndex, y: accelerationObjects[Int(chartIndex)].xAcceleration , dataSetIndex: 0, callDelegate: false)
            lineChart.moveViewToX(max(0, chartIndex - BluetoothStore.shared.ACCELEROMETER_PERIOD)) // this moves the window over the chart, not the actual line
        }
    }
    
    // MARK - Gesture recognition functions
    
    // I've decided that if the user tries to select more than 2 points, we'll just keep the first and latest
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let screenCoordinates = recognizer.location(in: lineChart)
        let chartValue: CGPoint = self.lineChart.valueForTouchPoint(point: screenCoordinates, axis: .right)
        print("Chart value: \(chartValue)")
        print("Recognizer state: \(recognizer.state)")
        // check if chart value null
        pointsSelected.append(Double(chartValue.x))
        let currentPoint = Int(floor(chartValue.x))
        xColors[currentPoint] = UIColor.magenta
        yColors[currentPoint] = UIColor.magenta
        zColors[currentPoint] = UIColor.magenta
        
        xAccelerationLine.setColors(xColors, alpha: 1)
        yAccelerationLine.setColors(yColors, alpha: 1)
        zAccelerationLine.setColors(zColors, alpha: 1)
        lineChart.data?.notifyDataChanged()
        lineChart.notifyDataSetChanged()
        AudioServicesPlayAlertSound(SystemSoundID(1105))
        if(recognizer.state == .ended) {
            let start = Int(floor(pointsSelected.min() ?? 0))
            let stop = Int(floor(pointsSelected.max() ?? 0))
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
    
    func undoHighlight(start: Int, stop: Int) {
        for i in start...stop {
            xColors[i] = UIColor.black
            yColors[i] = UIColor.blue
            zColors[i] = UIColor.cyan
        }
        xAccelerationLine.setColors(xColors, alpha: 1)
        yAccelerationLine.setColors(yColors, alpha: 1)
        zAccelerationLine.setColors(zColors, alpha: 1)
        lineChart.data?.notifyDataChanged()
        lineChart.notifyDataSetChanged()
    }
    
    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        print("Recognized a double tap. Points selected: \(pointsSelected.count)")
        if (pointsSelected.count == 0) {
            let tapLocation = recognizer.location(in: self.lineChart)
            let chartValue: CGPoint = self.lineChart.valueForTouchPoint(point: tapLocation, axis: .right)
            let greaterThan = segmentObjects.filter({ (segment) -> Bool in
                return !chartValue.x.isLess(than: CGFloat(segment.start_ts))
            })
            let contained = greaterThan.filter({ (segment) -> Bool in
                return chartValue.x.isLess(than: CGFloat(segment.stop_ts))
            })
            if contained.count == 1 {
                let index = labels.index(of: contained[0].rating!)
                self.pickerView(labelPicker, didSelectRow: index.unsafelyUnwrapped, inComponent: 0)
                if (editingSegment) {
                    assignLabelButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
                    assignLabelButton.isEnabled = false
                    assignLabelButton.setTitle("Assign", for: .normal)
                    curSegment = nil
                    let start = contained[0].start_ts
                    let end = contained[0].stop_ts
                    pointsSelected = []
                    doHighlight(color: UIColor.green, start: Int(start), stop: Int(end))
                } else {
                    assignLabelButton.backgroundColor = UIColor.red
                    assignLabelButton.isEnabled = true
                    assignLabelButton.setTitle("Delete", for: .normal)
                    curSegment = contained[0]
                    let start = contained[0].start_ts
                    let end = contained[0].stop_ts
                    pointsSelected = [start,end] // not sure if need plus 1
                    doHighlight(color: UIColor.magenta, start: Int(start), stop: Int(end))
                }
                editingSegment = !editingSegment
            } else {
                print("contained in \(contained.count) segments.")
            }
        }
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
        videoButton.isHidden = true
        libraryButton.isHidden = true
        importButton.isHidden = true
        videoLabel.isHidden = true
        libraryLabel.isHidden = true
        importLabel.isHidden = true
        labelPicker.isHidden = false
        self.savedVideo = chosenVideo
        hasVideo = true
        prepareGraph()
        prepareToPlay(urlString: chosenVideo.url! )
        accelerationObjects = chosenVideo.accelerations?.allObjects as! [Acceleration]
        segmentObjects = chosenVideo.segments?.allObjects as! [Segment] // we only need to fetch all for video because otherwise there won't be any existing.
        totalActionsSelected = segmentObjects.count
        accelerationObjects.sort(by: {(a1, a2) in
            a1.timestamp < a2.timestamp
        })
        // where should we do the colors?
        updateGraph()
        for segment in segmentObjects {
            doHighlight(color: UIColor.green, start: Int(floor(segment.start_ts)), stop: Int(floor(segment.stop_ts)))
        }
        startObservers()
    }
}
