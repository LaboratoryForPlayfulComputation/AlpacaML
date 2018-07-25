//
//  CustomOverlayView.swift
//  LPC Wearable Toolkit
//
//  Created by Varun Narayanswamy on 6/11/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.


import Foundation
import UIKit

public protocol CustomOverlayDelegate{
    func didShoot(overlayView:CustomOverlayView)
    func didCancel(overlayView:CustomOverlayView)
}

public class CustomOverlayView: UIView {
   
    @IBOutlet weak var time: UILabel!
    var seconds:Int = 0
    var minutes:Int = 0
    var pressed = false
    var seconds_string:String = ""
    var video_timer = Timer()
    
    @objc var current_time:Int = 0
    var delegate:CustomOverlayDelegate! = nil
    
    @IBAction func shootButton(sender: UIButton){
        delegate.didShoot(overlayView: self)
        if (pressed == false){
            time.text = "0:00"
            video_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CustomOverlayView.video_time), userInfo: nil, repeats: true)
            pressed = true
        }
        else{
            video_timer.invalidate()
            pressed = false
        }
    }
    @IBAction func cancelButton(_ sender: UIButton) {
        delegate.didCancel(overlayView: self)
    }
    
    @objc func video_time() {
        current_time = current_time + 1
        if (current_time>=60) {
            minutes = current_time/60
            seconds = current_time%60
        } else {
            seconds = current_time
        }
        if (seconds<10) {
            seconds_string = "0\(seconds)"
        } else {
            seconds_string = "\(seconds)"
        }
        time.text = "\(minutes):"+seconds_string
    }
}

