//
//  PeripheralInfoSelectorViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 11/20/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class PeripheralInfoSelectorViewController: UIViewController {
    
    let pageTitle = "Select Peripheral"
    let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    var infoMode: Bool!
    
    //  Data to use
    var savedPeripherals: [UUID:SavedPeripheral]?
    var connectedPeripherals: [BlePeripheral]?

    override func viewDidLoad() {
        super.viewDidLoad()

        //  Set up the UI config
        setupUI()
        
        //  Make self tableview delegate
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupUI(){
        //  Add table view
        view.addSubview(tableView)
        
        //  Add title and background
        navigationItem.title = pageTitle
        
        //  Add constraints to the tableview
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

//  MARK: - TableView Datasource
extension PeripheralInfoSelectorViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Peripherals"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectedPeripherals!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Create cell to show peripherals that are connected
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ConnectedPeripheral")
        
        //  Set the name of the cell
        let peripheral = connectedPeripherals![indexPath.row]
        cell.textLabel!.text = savedPeripherals![peripheral.identifier]?.name!
        
        return cell
    }
}

//  MARK: - TableView Delegate
extension PeripheralInfoSelectorViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Get peripheral that was selected
        let peripheral = connectedPeripherals![indexPath.row]
        
        if infoMode {
            //  Open info view controller
            let infoViewController = DeviceInfoViewController()
            infoViewController.hidesBottomBarWhenPushed = true
            infoViewController.blePeripheral = peripheral
            infoViewController.savedPeripheral = savedPeripherals![peripheral.identifier]
            navigationController?.pushViewController(infoViewController, animated: true)
        }
        else{
            //  Open saved data view controller
            let savedDataViewController = SavedDataViewController()
            savedDataViewController.hidesBottomBarWhenPushed = true
            savedDataViewController.blePeripheral = peripheral
            navigationController?.pushViewController(savedDataViewController, animated: true)
        }
        
        
        //  Deselect the selected row
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
