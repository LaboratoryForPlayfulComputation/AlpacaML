//
//  DefineCategoriesViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 2/6/19.
//  Copyright © 2019 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit

class DefineCategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var categoryTableView: UITableView!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let tableCellReuseIdentifier = "CategoryCell"
    
    var categories:[String]!
    var selectedCell:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.categoryTableView.delegate = self
        self.categoryTableView.dataSource = self
        self.categoryTextField.delegate = self
        
        self.deleteButton.isEnabled = false
    }
    
    @IBAction func useDefaultCategories(_ sender: Any) {
        categories = ["Good", "Bad", "None"]
        categoryTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = categories[indexPath.row]
        let cell = categoryTableView.dequeueReusableCell(withIdentifier: tableCellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = category
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentCell = categories[indexPath.row]
        if (selectedCell != currentCell) {
            selectedCell = currentCell
            deleteButton.isEnabled = true
            deleteButton.backgroundColor = UIColor(red: 69/255.0, green: 255/255.0, blue: 190/255.0, alpha: 1.0)
        } else {
            selectedCell = nil
            deleteButton.isEnabled = false
            deleteButton.backgroundColor = UIColor.lightGray
            categoryTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // what does this even do
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedCell = nil
        deleteButton.isEnabled = false
        deleteButton.backgroundColor = UIColor.lightGray
    }
    
    @IBAction func deleteCategoryFromList(_ sender: Any) {
        if (selectedCell != nil) {
            categories.removeAll {$0 == selectedCell}
            categoryTableView.reloadData()
        }
        deleteButton.isEnabled = false
        deleteButton.backgroundColor = UIColor.lightGray
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("Editing soon")
        doneButton.isEnabled = false
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Editing now")
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("Ending editing soon")
        doneButton.isEnabled = true
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        categoryTextField.resignFirstResponder()
        let newCategory = categoryTextField.text
        if (newCategory != nil) {
            categories.append(newCategory ?? "")
        }
        print(newCategory ?? "No category retrieved")
        print(categories.joined(separator: " "))
        categoryTableView.reloadData() // ?
        categoryTextField.text = ""
        return true
    }
}
