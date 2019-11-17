//
//  SportsListTableViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/17/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import CoreData

class ModelListTableViewController: UITableViewController {
    
    @IBOutlet var modelsTableView: UITableView!
    var trackedData: TrackedData = TrackedData()
    
    let models: Models = Models()
    var selectedModel = Model()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Models"
        modelsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ModelCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models.objectAtIndex(i: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = model.value(forKeyPath: "name") as? String
        cell.detailTextLabel?.text = model.value(forKeyPath: "notes") as? String
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (models.count() > indexPath.row) {
            DispatchQueue.main.async {
                self.selectedModel = self.models.objectAtIndex(i: indexPath.row) as! Model
                print(self.selectedModel.name ?? "None retrieved")
                self.performSegue(withIdentifier: "summary", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "summary" ) {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! ModelSummaryViewController
            print("Selected model: \(selectedModel)")
            destinationViewController.model = selectedModel
        }
    }
}

extension ModelListTableViewController {
    @IBAction func cancelToModelsListTableViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveModelDetail(_ segue: UIStoryboardSegue) {
        guard let modelDetailsViewController = segue.source as? AddModelViewController,
            let model = modelDetailsViewController.model else {
                return
        }
        models.save(name: model.0, modelDescription: model.1) // do something with description soon
        // save to core data here
        print("Model \(model)")
        let indexPath = IndexPath(row: models.count() - 1, section: 0)
        modelsTableView.insertRows(at: [indexPath], with: .automatic)
    }
    
}
