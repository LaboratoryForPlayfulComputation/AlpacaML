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
    var trackedData: TrackedData = TrackedData()
    
    let videoStore = Videos()
    var sport: String!
    var action: String!
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
        
        let videos = videoStore.fetch(sport: sport)
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
        return CGSize(width: 100, height: 100)
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
        smallScreen.view.frame = CGRect (x:0, y:50, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height/2) // -50
        doneButton.isEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // play video
        let video = images[indexPath.item].1
        let url = NSURL(fileURLWithPath: video.url!) as URL
        displayVideo(url)
        
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
        trackedData.save(button: "Done reviewing for video", contextName: "SegmentReview", metadata1: sport, metadata2: action, ts: NSDate().timeIntervalSinceReferenceDate)
    }
    
    // MARK: UITableView stuff
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let segment = segments[indexPath.row]
        let cell = segmentsTableView.dequeueReusableCell(withIdentifier: tableCellReuseIdentifier, for: indexPath)
        print("segment start: \(segment.start_ts), segment stop: \(segment.stop_ts)")
        let range = String(format:"%.1f", segment.start_ts/100.0) + "-" + String(format:"%.1f", segment.stop_ts/100.0)
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
        trackedData.save(button: "Selected table row", contextName: "SegmentReview", metadata1: segment.rating ?? "", metadata2: "\(segment.inTrainingSet)", ts: NSDate().timeIntervalSinceReferenceDate)
    }
    
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let tapLocation = recognizer.location(in: self.segmentsTableView)
        if let tapIndexPath = self.segmentsTableView.indexPathForRow(at: tapLocation) {
            if let tappedCell = self.segmentsTableView.cellForRow(at: tapIndexPath) {
                let segment = self.segments[tapIndexPath.row]
                if recognizer.state == UIGestureRecognizerState.began {
                    let start_ts = segment.start_ts
                    tappedCell.backgroundColor = UIColor.darkGray
                    self.player.seek(to: CMTime(value: CMTimeValue(start_ts/100.0), timescale: 1))
                    self.player.play()
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
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
