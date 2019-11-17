//
//  LibraryCollectionViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 11/3/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import AVKit

private let reuseIdentifier = "libraryVideoCell"

class LibraryCollectionViewController: UICollectionViewController {
    // ^ fix thing
    let videoStore = Videos()
    var model: Model! = nil
    var images:[(UIImage, Video)]!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UINavigationItem!
    
    var chosenVideo:Video!
    var selected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = false
        let videos = videoStore.fetch(model: model)
        print("Number of videos: \(videos.count)")
        images = videos.map({v -> (UIImage, Video) in
            do {
                let urlObject = NSURL(fileURLWithPath: v.url!) as URL
                let asset = AVURLAsset(url: urlObject)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                return (thumbnail, v)
            } catch let error {
                print("Could not get image for thumbnail: \(error.localizedDescription)")
                return (UIImage(), Video())
            }
        }) // what do if no video for entry?
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (selected) {
            chosenVideo = nil
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 0.0
            selected = false
            doneButton.isEnabled = false
        } else {
            chosenVideo = images[indexPath.item].1
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 3.0
            cell?.layer.borderColor = UIColor.blue.cgColor
            selected = true
            doneButton.isEnabled = true
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("c \(images?.count ?? 0)")
        return images?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LibraryVideoCollectionViewCell
        
        cell.imageView.image = images[indexPath.item].0
        return cell
    }

}
