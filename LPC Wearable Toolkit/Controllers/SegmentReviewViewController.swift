//
//  SegmentReviewViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 10/1/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import AVKit
import Photos

class SegmentReviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    let collectionCellReuseIdentifier = "VideoCell"
    let tableCellReuseIdentifier = "SegmentCell"
    
    let videoStore = Videos()
    var model: Model!
    var images:[(UIImage,Video)]!
    var segments:[Segment] = []
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    let smallScreen = AVPlayerViewController()
    let imageManager = PHImageManager.default()
    
    @IBOutlet weak var videoCollectionView: UICollectionView!
    @IBOutlet weak var segmentsTableView: UITableView!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var videoLabel: UILabel!
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = false
        // Register cell classes
        //self.videoCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.videoCollectionView.delegate = self
        self.videoCollectionView.dataSource = self
        
        self.segmentsTableView.delegate = self
        self.segmentsTableView.dataSource = self
        
        let videos = videoStore.fetch(model: model)
        print("Number of videos: \(videos.count)")
        images = videos.map({v -> (UIImage,Video) in
            do {
                let urlObject = NSURL(fileURLWithPath: v.url!) as URL
                let asset = AVURLAsset(url: urlObject)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                return (thumbnail, v)
            } catch let error {
                print("Could not get image for thumbnail: \(error.localizedDescription)")
                return (UIImage(),Video())
            }
        })
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:)))
        recognizer.delegate = self
        segmentsTableView.addGestureRecognizer(recognizer)
        self.videoCollectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthSize = self.videoCollectionView.frame.width / 4
        let heightSize = self.videoCollectionView.frame.height / 2
        return CGSize(width: widthSize, height: heightSize)
        //return CGSize(width: 100, height: 100)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("c \(images?.count ?? 0)")
        return images?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionCellReuseIdentifier, for: indexPath) as! VideoCollectionViewCell

        cell.imageView.image = images[indexPath.item].0
        cell.imageTitle.text = images[indexPath.item].1.name
        cell.imageTitle.font = UIFont(name:"HelveticaNeue-Bold", size: 12.0)
        return cell
    }
    
    
    func displayVideo(_ url: URL) {
        asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
        player = AVPlayer(playerItem: playerItem)
        
        smallScreen.player = player
        self.addChildViewController(smallScreen)
        self.view.addSubview(smallScreen.view)
        smallScreen.didMove(toParentViewController: self)
        smallScreen.view.frame = CGRect (x:0, y:100, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/3) // -50
        doneButton.isEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // play video
        let video = images[indexPath.item].1
        let url = NSURL(fileURLWithPath: video.url!) as URL
        displayVideo(url)
        videoLabel.text = video.name
        segments = video.segments?.allObjects as! [Segment]
        segments.sort(by: {(s1,s2) in
            s1.start_ts < s2.start_ts
        })
        segmentsTableView.reloadData()
    }
    
    @IBAction func doneReviewingForVideo(_ sender: UIBarButtonItem) {
        player.pause()
        smallScreen.view.removeFromSuperview()
        smallScreen.removeFromParentViewController()
        segments = []
        segmentsTableView.reloadData()
        self.doneButton.isEnabled = false
        videoLabel.text = "Videos"
    }
    
    // MARK: UITableView stuff
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let segment = segments[indexPath.row]
        let cell = segmentsTableView.dequeueReusableCell(withIdentifier: tableCellReuseIdentifier, for: indexPath)
        print("segment start: \(segment.start_ts), segment stop: \(segment.stop_ts)")
        // DEBUG THIS PART 2
        let range = String(format:"%.1f", segment.start_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD) + "-" + String(format:"%.1f", segment.stop_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD)
        cell.textLabel?.text = range
        cell.detailTextLabel?.text = segment.rating
        if segment.inTrainingSet {
            cell.textLabel?.font = UIFont(name:"HelveticaNeue-Bold", size: 17.0)
            cell.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 0.1)
        } else {
            cell.textLabel?.font = UIFont(name:"HelveticaNeue-Regular", size: 17.0)
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segment = segments[indexPath.row]
        segment.inTrainingSet = !segment.inTrainingSet
        segmentsTableView.reloadData()
    }
    
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let tapLocation = recognizer.location(in: self.segmentsTableView)
        if let tapIndexPath = self.segmentsTableView.indexPathForRow(at: tapLocation) {
            if let tappedCell = self.segmentsTableView.cellForRow(at: tapIndexPath) {
                let segment = self.segments[tapIndexPath.row]
                if recognizer.state == UIGestureRecognizerState.began {
                    let start_ts = segment.start_ts
                    let duration_time = segment.stop_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD - start_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD
                    tappedCell.backgroundColor = UIColor.darkGray
                    self.player.seek(to: CMTime(value: CMTimeValue(start_ts/BluetoothStore.shared.ACCELEROMETER_PERIOD), timescale: 1))
                    self.player.play()
                    // solution as seen in:  https://stackoverflow.com/questions/38116574/how-to-stop-avplayer-at-specific-time
                    self.player.perform(#selector(player?.pause), with: nil, afterDelay: duration_time)
                }
                if recognizer.state == UIGestureRecognizerState.ended {
                    self.player.pause()
                    if segment.inTrainingSet {
                        tappedCell.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 0.1)
                    } else {
                        tappedCell.backgroundColor = UIColor.white
                    }
                }
            }
        }
    }

}
