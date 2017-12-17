//
//  LibraryViewController.swift
//  Curious Blossom
//
//  Created by Spencer Yang on 12/16/17.
//  Copyright © 2017 Seungho Yang. All rights reserved.
//

import UIKit
import CoreData

class LibraryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var flowers : [Flower] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        //Register FlowerCell.xib
        tableView.register(UINib(nibName: "FlowerCell", bundle: nil), forCellReuseIdentifier: "customCell")
        tableView.rowHeight = 81
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFlowers()
    }
    
    func fetchFlowers() {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<Flower>(entityName: "Flower")
        
        do {
            flowers = try managedContext.fetch(fetchRequest)
            print("Successfully fetched data")
        } catch {
            debugPrint("Could not fetch: " + error.localizedDescription)
        }
    }
}

extension LibraryViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flowers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? CustomCell else {
            return UITableViewCell()
        }
        
        cell.configureCell(flower: flowers[indexPath.row])
        
        return cell
    }
}















