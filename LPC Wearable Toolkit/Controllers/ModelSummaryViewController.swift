//
//  SportSummaryViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Development on 9/3/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

class ModelSummaryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var labelPicker: UIPickerView!
    @IBOutlet weak var trainButton: UIButton!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var labelTextField: UITextField!
    
    var numberVideos = 0
    var numberSegments = 0
    var accelerationPoints = 0
    
    var model = Model()
    var modelStore = Models()
    var videoStore = Videos()
    var segmentStore = Segments()
    var accelerationStore = Accelerations()
    var selectedModel: Model!
    var selectedLabel: String!
    
    let NONE_LABEL = "None"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelPicker.delegate = self
        self.labelPicker.dataSource = self
        print(model.name ?? "none")
        self.title = model.name
        doSummarySetup()
        // prepareSummary() fix
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        labelTextField.resignFirstResponder()
        print("Save entered label handler called")
        if (labelTextField.hasText) {
            print("label has text, and it is: \(labelTextField.text!)")
            addNewLabel(newLabel: labelTextField.text!)
        }
        labelTextField.text = ""
        return true
    }
    
    func addNewLabel(newLabel: String) {
        if (model.labels == nil) {
            model.labels = []
        }
        model.labels?.append(newLabel)
        do {
            try model.managedObjectContext?.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        
        print("model.labels: \(model.labels!)")
        labelPicker.reloadAllComponents()
        doSummarySetup()
    }
    
    @IBAction func deleteLabel(_ sender: UIButton) {
        if (model.labels != nil) {
            print("removing: \(self.selectedLabel ?? "")")
            model.labels!.removeAll {$0 == selectedLabel}
            do {
                try model.managedObjectContext?.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
            labelPicker.reloadAllComponents()
            doSummarySetup()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "train") {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! SegmentationViewController
            print("Sport name: \(model.name ?? "no value provided")")
            destinationViewController.model = self.model
        } else if (segue.identifier == "test") {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! ClassificationViewController
            print("Sport name: \(model.name ?? "no value provided")")
            destinationViewController.model = self.model
        } else if (segue.identifier == "review") {
            // you didn't connect the segment yet
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! SegmentReviewViewController
            print("Sport name: \(model.name ?? "no value provided")")
            destinationViewController.model = self.model
        }
    }
    
    func doSummarySetup() {
        if (model.labels == nil) {
            trainButton.isEnabled = false
            testButton.isEnabled = false
            reviewButton.isEnabled = false
            deleteButton.isHidden = true
        } else if ((model.segments == nil) || (model.segments?.count == 0)) {
            trainButton.isEnabled = true
            trainButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            testButton.isEnabled = false
            reviewButton.isEnabled = false
            deleteButton.isHidden = false
        } else {
            trainButton.isEnabled = true
            trainButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            testButton.isEnabled = true
            testButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            reviewButton.isEnabled = true
            reviewButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
            deleteButton.isHidden = true
        }
        accelerationPoints = accelerationStore.countAll(model: model)
        labelTextField.delegate = self
        labelTextField.placeholder = "Start typing to add a label..."
        labelTextField.isEnabled = true
    }
    
    // MARK: Picker View functions
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.model.labels?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.model.labels?[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let curLabel = model.labels?[row] ?? ""
        deleteButton.isHidden = false
        selectedLabel = curLabel
        prepareSummary(label: curLabel)
    }
    
    func prepareSummary(label: String) {
        self.summaryLabel.text? = ""
        self.summaryLabel.text?.append("Model Description: \(model.notes ?? "(none)")\n")
        self.summaryLabel.text?.append("Training segments: \(numberSegments)\n")
        // what are we going to have in here?
    }
}

extension ModelSummaryViewController {
    @IBAction func cancelToModelSummaryViewController(_ segue: UIStoryboardSegue) {
        self.pickerView(labelPicker, didSelectRow: 0, inComponent: 0)
        self.doSummarySetup()
    }
 
}

