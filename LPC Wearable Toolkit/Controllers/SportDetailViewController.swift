//
//  SportDetailViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/18/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

class SportDetailViewController: UIViewController {

    @IBOutlet weak var sportNameTextField: UITextField!
    @IBOutlet weak var sportDescriptionTextField: UITextField!
    
    var sport: (String,String)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
  /*  // MARK: - Navigation
    @IBAction func done(segue: UIStoryboardSegue) {
        let sportDetailVC = segue.source as! SportDetailViewController
        var newSport = sportDetailVC.name
        
        //cars.append(newCar) // save here instead
        performSegue(withIdentifier: "doneSegue", sender: self)
    }
    
    @IBAction func cancel(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    */
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    // https://stackoverflow.com/questions/46561545/xcode-9-0-bug-cant-drag-drop-to-exit-icon
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "saveSportDetail" {
            // TODO: handle case with no text
            let sportName = sportNameTextField.text
            print("Sport name \(String(describing: sportName))")
            let sportDescription = sportDescriptionTextField.text
            print("Sport description \(String(describing: sportDescription))")
            sport = (sportName, sportDescription) as? (String, String)
        }
     }


}
