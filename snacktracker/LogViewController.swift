//
//  LogViewController.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import Foundation
import UIKit

class LogViewCell: UITableViewCell {
    
}

class LogViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(LogViewCell.self, forCellReuseIdentifier: "LogViewCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FoodLog.shared.enumeratedEntries.count
    }
    
    // Provide a cell object for each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "LogViewCell", for: indexPath) as! LogViewCell
       
        // Configure the cell’s contents.
        if let content = FoodLog.shared.retrieveDetails(forImageAtPath: FoodLog.shared.enumeratedEntries[indexPath.item]) {
            cell.textLabel!.text = content.name
            cell.textLabel?.textAlignment = .center
            
            if let imageData = try? Data(contentsOf: FoodLog.shared.enumeratedEntries[indexPath.item]) {
                cell.imageView?.image = UIImage(data: imageData)
            }
        }
           
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let entryVC = EnterViewController()
        
        entryVC.showLoggedItem(FoodLog.shared.enumeratedEntries[indexPath.item])
        navigationController?.pushViewController(entryVC, animated: true)
    }

}
