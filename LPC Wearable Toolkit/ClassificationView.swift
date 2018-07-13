//
//  ClassificationView.swift
//  LPC Wearable Toolkit
//
//  Created by Bridget Murphy on 7/10/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//
import UIKit
import Foundation
import AVKit
import MobileCoreServices
import CoreBluetooth
import Charts
import CoreML

class ClassificationView: UIViewController, UITextFieldDelegate{

    let small_screen = AVPlayerViewController()
    var player = AVPlayer()
    
    var IsinTrainingMode:Bool = false
    
    let TrainButton = UIButton(type: UIButtonType.system) as UIButton
    let ClassifyButton = UIButton(type: UIButtonType.system) as UIButton
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let train_xPostion:CGFloat = 50
        let yPostion:CGFloat = 400
        let buttonWidth:CGFloat = 150
        let buttonHeight:CGFloat = 45
        
        let classify_xPosition:CGFloat = 250
        
        TrainButton.frame = CGRect(x:train_xPostion, y:yPostion, width:buttonWidth, height:buttonHeight)
        ClassifyButton.frame = CGRect(x:classify_xPosition,y:yPostion, width: buttonWidth, height:buttonHeight)
        
        TrainButton.backgroundColor = UIColor.green
        TrainButton.setTitle("Train", for: UIControlState.normal)
        TrainButton.tintColor = UIColor.black
        //TrainButton.addTarget(self, action: #selector(MicrobitUIController.buttonAction(_:)), for: .touchUpInside)
        
        ClassifyButton.backgroundColor = UIColor.blue
        ClassifyButton.setTitle("Classify", for: UIControlState.normal)
        ClassifyButton.tintColor = UIColor.black
        //ClassifyButton.addTarget(self, action: #selector(MicrobitUIController.buttonAction(_:)), for: .touchUpInside)
        
        self.view.addSubview(TrainButton)
        self.view.addSubview(ClassifyButton)
        
        //TrainButton.isHidden = true
        //BadButton.isHidden = true
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.center = CGPoint(x: 160, y: 500)
        label.textAlignment = .center
        label.text = "UPDATE STATUS"
        self.view.addSubview(label)
    }

    @objc func buttonAction(_ sender:UIButton!){
        if(sender == TrainButton){
           IsinTrainingMode = true
        }
        else if(sender == ClassifyButton){
            IsinTrainingMode = false
        }
        
        //if in training mode send data to array 1 in DTW else array 2
        
        
    }

    //outputURL
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ClassificationView: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerControllerMediaURL] as? NSURL
            else { return }
        player = AVPlayer(url: url as URL)
        small_screen.player = player
        self.addChildViewController(small_screen)
        self.view.addSubview(small_screen.view)
        small_screen.didMove(toParentViewController: self)
    }
}

