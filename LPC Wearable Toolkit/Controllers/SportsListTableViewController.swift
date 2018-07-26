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
    
    @IBOutlet weak var sportsTableView: UITableView!
    //var sports: [String] = []
    
    let sports: Sports = Sports()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        title = "Sports"
        sportsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SportCell", for: indexPath)
        cell.textLabel?.text = sport.value(forKeyPath: "name") as? String
        cell.detailTextLabel?.text = sport.value(forKeyPath: "notes") as? String
        return cell
    }
    
    /*override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSport = sports.objectAtIndex(i: indexPath.row)
        
        let destinationViewController = ()
        destinationViewController.sport = selectedSport
        
        destinationViewController.shouldPerformSegue(withIdentifier: "SportSelectedSegue", sender: self)
    }*/

}

extension SportsListTableViewController {
    @IBAction func cancelToSportsListTableViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveSportDetail(_ segue: UIStoryboardSegue) {
        guard let sportDetailsViewController = segue.source as? SportDetailViewController,
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
