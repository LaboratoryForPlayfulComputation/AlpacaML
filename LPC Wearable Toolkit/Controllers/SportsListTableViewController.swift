//
//  SportsListTableViewController.swift
//  LPC Wearable Toolkit
//
//  Created by Abigail Zimmermann-Niefield on 7/17/18.
//  Copyright © 2018 Varun Narayanswamy LPC. All rights reserved.
//

import UIKit
import CoreData

class SportsListTableViewController: UITableViewController {
    
    @IBOutlet var sportsTableView: UITableView!
    var trackedData: TrackedData = TrackedData()
    
    //var sports: [String] = []
    
    let sports: Sports = Sports()
    var selectedSport = Sport()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        title = "Sports"
        sportsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SportCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sports.count()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sport = sports.objectAtIndex(i: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "SportCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = sport.value(forKeyPath: "name") as? String
        cell.detailTextLabel?.text = sport.value(forKeyPath: "notes") as? String
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.selectedSport = self.sports.objectAtIndex(i: indexPath.row) as! Sport
            print(self.selectedSport.name ?? "None retrieved")
            self.performSegue(withIdentifier: "summary", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "summary" ) {
            let navigationViewController = segue.destination as! UINavigationController
            let destinationViewController = navigationViewController.viewControllers[0] as! SportSummaryViewController
            print("Selected sport: \(selectedSport)")
            destinationViewController.sport = selectedSport
        }
    }
}

extension SportsListTableViewController {
    @IBAction func cancelToSportsListTableViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveSportDetail(_ segue: UIStoryboardSegue) {
        guard let sportDetailsViewController = segue.source as? AddSportViewController,
            let sport = sportDetailsViewController.sport else {
                return
        }
        sports.save(name: sport.0, sportDescription: sport.1) // do something with description soon
        // save to core data here
        print("Sport \(sport)")
        let indexPath = IndexPath(row: sports.count() - 1, section: 0)
        sportsTableView.insertRows(at: [indexPath], with: .automatic)
    }
    
}
