//
//  gesture_menu.swift
//  LPC Wearable Toolkit
//
//  Created by Varun Narayanswamy on 7/11/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import Foundation

class Gesture_menu: UIViewController, UITextFieldDelegate
{
    @IBAction func add(_ sender: UIButton)
    {
        print("here")
        let item = UITableViewCell()
        let alert = UIAlertController(title: "Add a alert", message: "This is an alert.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: text)
    }
    func text(textfield: UITextField!)
    {
        textfield.placeholder = "add a gesture name"
    }
}
