//
//  CameraViewControlls.swift
//  LPC Wearable Toolkit
//
//  Created by Varun Narayanswamy on 6/8/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import Foundation
import UIKit

class CameraControls: UIView {
    var record = UIButton()
    override init(frame: CGRect) {
        print("in here")
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        record.setTitle("record", for: .normal)
        record.setTitleColor(UIColor.blue, for: .normal)
        record.frame = CGRect(x: 15, y: -50, width: 100, height: 100)
        record.addTarget(self, action: #selector(CameraControls.record(sender:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    @objc func record(sender: UIButton!) {
        print("made it")
    }
}
