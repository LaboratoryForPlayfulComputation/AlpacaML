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

private let reuseIdentifier = "VideoCell"

class SegmentReviewViewController: UICollectionViewController {

    let videoStore = Videos()
    var sport: String!
    var action: String!
    var fetchResults:PHFetchResult<PHAsset>?
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    let smallScreen = AVPlayerViewController()
    
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let videos = videoStore.fetch(sport: sport)
        let urls = videos.map({v in v.url})
        fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: urls as! [String], options: fetchOptions)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Move to handle hold
    func prepareToPlay() {
        // get url
        let urlString = videoStore.fetch(sport: sport)[0].url // GIRL
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
    }*/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return fetchResults?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VideoCollectionViewCell
        let videoAsset = fetchResults!.object(at: indexPath.item)
        PHImageManager.default().requestImage(for: videoAsset, targetSize: cell.bounds.size, contentMode: .aspectFill, options: nil) {(image: UIImage?, info: [AnyHashable: Any]?) in
            cell.imageView.image = image
        }
    
        return cell
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
