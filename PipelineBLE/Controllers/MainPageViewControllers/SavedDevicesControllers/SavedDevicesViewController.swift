//
//  ViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/7/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

class SavedDevicesViewController: UITableViewController {
    
    private let pageTitle = "Saved Devices"
    
    var savedDevices: [SavedPeripheral] = []
    var dirtyData = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Set some initial parameters
        //view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  Get saved peripherals
        getSavedPeripherals()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  Make sure we reload data on return
        self.dirtyData = true
    }
    
    //  Get saved peripherals
    func getSavedPeripherals(){
        //  Make sure to reset the devices we have
        savedDevices.removeAll()
        
        //  Get ready to get the saved peripherals
        let fetchSavedPeripheral = NSFetchRequest<SavedPeripheral>(entityName: "SavedPeripheral")
        
        do{
            //  Get the saved devices
            let devices = try PersistenceService.context.fetch(fetchSavedPeripheral)
            
            //  Add the uuids to the array
            for device in devices {
                savedDevices.append(device)
            }
        }catch {}
        
        self.dirtyData = false
        tableView.reloadData()
    }
}

//  MARK: - Table View Handling
extension SavedDevicesViewController {
    //  Do table view work here
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedDevices.count == 0 ? 1 : savedDevices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Display the device
        let cell = UITableViewCell(style: .default, reuseIdentifier: "SavedDevice")
        
        //  Check if there are any saved devices
        cell.textLabel?.text = savedDevices.count != 0 ? savedDevices[indexPath.row].name : "-- No Devices Saved --"
        
        //  Return the edited cell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return savedDevices.count != 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete){
            //  Need to get the device to delete
            let device = savedDevices[indexPath.row]
            
            //  Delete the device
            PersistenceService.context.delete(device)
            
            //  Remove the device from the table view and set of devices
            savedDevices.remove(at: indexPath.row)
            //tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            
            //  Save the context of the deleted item
            PersistenceService.saveContext()
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Need to display the info for the given peripheral
        let savedPeripheral = savedDevices[indexPath.row]
        
        //  Open info view controller
        let infoViewController = DeviceInfoViewController()
        infoViewController.hidesBottomBarWhenPushed = true
        infoViewController.savedPeripheral = savedPeripheral
        navigationController?.pushViewController(infoViewController, animated: true)
        
        //  Deselect the selected row
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
