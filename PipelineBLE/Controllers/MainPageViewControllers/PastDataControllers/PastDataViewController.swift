//
//  PastDataViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/8/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import CoreData

class PastDataViewController: UIViewController {

    var uuids = [UUID]()
    var savedDevices: [UUID : SavedPeripheral] = [:]
    var dirtyDataUUIDs: Bool = true
    var dirtyDataDevices: Bool = true
        
    private let pageTitle = "Past Data"
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
            
        //  Set some initial parameters
        view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
            
        //  Gather data from file
        gatherData()
        
        //  Gather devices from file
        getSavedPeripherals()
            
        //  Set up the UI
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dirtyDataDevices = true
        self.dirtyDataUUIDs = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  Reload data if necessary
        if self.dirtyDataUUIDs || self.dirtyDataDevices {
            self.gatherData()
            self.getSavedPeripherals()
        }
    }
        
    //  Gather data
    func gatherData(){
        //  Reset data
        uuids.removeAll()
        
        let fetchUart = NSFetchRequest<UARTData>(entityName: "UARTData")
        let fetchPlot = NSFetchRequest<PlotData>(entityName: "PlotData")
            
        do {
            //  Get the saved data
            let savedUartData = try PersistenceService.context.fetch(fetchUart)
            let savedPlotData = try PersistenceService.context.fetch(fetchPlot)
                
            //  Add the uuid to the list
            for data in savedUartData {
                if !uuids.contains(data.deviceID) {
                    //  Don't have the uuid, so add it
                    uuids.append(data.deviceID)
                }
            }
            //  Add the data to the savedData data structure
            for data in savedPlotData {
                if !uuids.contains(data.deviceID) {
                    //  Don't have the uuid, so add it
                    uuids.append(data.deviceID)
                }
            }
        } catch {}
        self.dirtyDataUUIDs = false
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
                savedDevices[device.uuid!] = device
            }
        }catch {}
        self.dirtyDataDevices = false
        tableView.reloadData()
    }
        
    //  MARK: - UI Setup
    func setupUI(){
        // Do any additional setup after loading the view.
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
}

extension PastDataViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.dirtyDataUUIDs || self.dirtyDataDevices {
            self.gatherData()
            self.getSavedPeripherals()
        }
        
        return uuids.count == 0 ? 1 : uuids.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Create a cell to display the data that has been saved for that device
        let cell = UITableViewCell(style: .default, reuseIdentifier: "SavedData")
        
        var text = "-- No Data Saved --"
        if uuids.count != 0 {
            let uuid = uuids[indexPath.row]
            
            //  Get the name of the device
            text = String(describing: uuid)
            if savedDevices[uuid] != nil && savedDevices[uuid]!.name != nil {
                text = savedDevices[uuid]!.name!
            }
        }
        
        //  Set the text and return the cell
        cell.textLabel?.text = text
        return cell
    }
        
        
        
}

extension PastDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        //  Create a new saved data controller
        let savedDataController = SavedDataViewController()
        self.storyboard?.instantiateViewController(withIdentifier: "SavedDataViewController")
        
        //  Give the view the data it needs
        savedDataController.deviceUUID = uuids[indexPath.row]
        
        //  Deselect the selected row
        tableView.deselectRow(at: indexPath, animated: true)
        
        //  Finally push the view
        navigationController?.pushViewController(savedDataController, animated: true)
    }
}
