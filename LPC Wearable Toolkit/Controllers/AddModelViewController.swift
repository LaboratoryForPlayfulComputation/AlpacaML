//
//  SportDetailViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/18/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

// TODO: Need to add constraints for screens.
class AddModelViewController: UIViewController {

    
    @IBOutlet weak var modelNameTextField: UITextField!
    @IBOutlet weak var modelDescriptionTextField: UITextField!
    
    
    var model: (String,String)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    // https://stackoverflow.com/questions/46561545/xcode-9-0-bug-cant-drag-drop-to-exit-icon
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "saveModelDetail" {
            // TODO: handle case with no text
            let modelName = modelNameTextField.text
            print("Model name \(String(describing: modelName))")
            let modelDescription = modelDescriptionTextField.text
            print("Model description \(String(describing: modelDescription))")
            model = (modelName, modelDescription) as? (String, String)
        }
     }


}
