//
//  ViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/7/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class SavedDevicesViewController: UITableViewController {
    
    let dummyData = ["One","Two","Three","Four","Five","Six"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  View just appeared, configure the layout
        navigationItem.title = "Saved Devices"
        
        //  The cells will be taken from the saved devices table view cell
        tableView.register(SavedDevicesTableViewCell.self, forCellReuseIdentifier: "SavedDevice")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Create a cell of type SavedDevicesTableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedDevice", for: indexPath) as! SavedDevicesTableViewCell
        
        //  Send the cell the necessary data to configure itself
        cell.deviceName.text = dummyData[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected \(indexPath.row)")
        let connectToDevice = UARTViewController()
        navigationController?.pushViewController(connectToDevice, animated: true)
    }
    
    func ConnectToDevice(){
        //  Use this function to segue from current view controller to UART
        let connectToDevice = UARTViewController()
        navigationController?.pushViewController(connectToDevice, animated: true)
    }


}

