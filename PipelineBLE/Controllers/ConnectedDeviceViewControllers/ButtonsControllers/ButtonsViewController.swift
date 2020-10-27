//
//  ButtonsViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/22/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import CoreData

class ButtonsViewController: UIViewController {

    private let pageTitle = "Buttons"
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    let deviceName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Device Info - This page is currently under development"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var addCommand: UIBarButtonItem!
    
    //  Saving and retrieving data
    weak var blePeripheral: BlePeripheral?
    var savedPeripheral: SavedPeripheral?
    var commands: [[String]] = []
    
    //  UART stuff
    internal var uartData: UartPacketManagerBase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Save the commands
        if let command = savedPeripheral?.commands{
            self.commands = command as! [[String]]
        }
        
        //  Set up the UI
        setupUI()
        
        //  Init Uart data
        uartData = UartPacketManager(delegate: self, isPacketCacheEnabled: true, isMqttEnabled: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  Set up UART
        setupUART()
        
        //  Set up notifications
        registerNotifications(enabled: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //  Need to save the data before we quit
        save()
        
        //  Close notifications
        registerNotifications(enabled: false)
    }
    
    //  MARK: - UI Config
    func setupUI(){
        //  Set up the bar button
        addCommand = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(onClickAdd(_:)))
        
        //  Set some initial parameters
        view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
        navigationItem.rightBarButtonItem = addCommand
        
        // Do any additional setup after loading the view.
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    //  MARK: - UART Setup
    func isInMultiUartMode() -> Bool {
        return BleManager.shared.connectedPeripherals().count > 1
    }
    
    func setupUART(){
        //  Localization manager init
        let localizationManager = LocalizationManager.shared
        
         if isInMultiUartMode() {            // Multiple peripheral mode
             let blePeripherals = BleManager.shared.connectedPeripherals()
             for (_, blePeripheral) in blePeripherals.enumerated() {
                 //  Only want to try to set up uart for devices that have UART available
                 print(blePeripheral.name!)
                 if blePeripheral.hasUart(){
                     print("Setting up uart for: \(blePeripheral.name!)")
                     blePeripheral.uartEnable(uartRxHandler: uartData.rxPacketReceived) { [weak self] error in
                         guard let context = self else { return }
                         
                         let peripheralName = blePeripheral.name ?? blePeripheral.identifier.uuidString
                         DispatchQueue.main.async {
                             guard error == nil else {
                                 DLog("Error initializing uart")
                                 context.dismiss(animated: true, completion: { [weak self] () -> Void in
                                     if let context = self {
                                         showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: String(format: localizationManager.localizedString("uart_error_multipleperiperipheralinit_format"), peripheralName))
                                         
                                         BleManager.shared.disconnect(from: blePeripheral)
                                     }
                                 })
                                 return
                             }
                             
                             // Done
                             DLog("Uart enabled for \(peripheralName)")
                         }
                     }
                 }
             }
        } else if let blePeripheral = blePeripheral {
        blePeripheral.uartEnable(uartRxHandler: uartData.rxPacketReceived) { [weak self] error in
            guard let context = self else { return }
            
            DispatchQueue.main.async {
                guard error == nil else {
                    DLog("Error initializing uart")
                    context.dismiss(animated: true, completion: { [weak self] in
                        if let context = self {
                            showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("uart_error_peripheralinit"))
                            
                            if let blePeripheral = context.blePeripheral {
                                BleManager.shared.disconnect(from: blePeripheral)
                            }
                        }
                    })
                    return
                }
                
                // Done
                DLog("Uart enabled")
                print("UART enabled")
            }
        }
        }
    }
    
    func send(message: String) {
        guard let uartData = self.uartData as? UartPacketManager else { DLog("Error send with invalid uartData class"); return }
        
        print("Sending message(to all): \(message)")
        
        //  Need to send data to the multiple peripherals
        for peripheral in BleManager.shared.connectedPeripherals(){
            if peripheral.isUartEnabled(){
                uartData.send(blePeripheral: peripheral, text: message)
            }
        }
    }
    
    @objc func onClickAdd(_ sender: AnyObject){
        //  Need to get the new command
        let alert = UIAlertController(title: "New Command", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "identifier"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "command"
        }
        
        let action = UIAlertAction(title: "Add Command", style: .default){ (_) in
            let identifier = alert.textFields!.first!.text ?? "-"
            let command = alert.textFields!.last!.text ?? "-"
            
            //  Now need to add the new command to the commands
            self.commands.append([identifier, command])
            self.tableView.reloadData()
        }
        
        //  Add the action to the view
        alert.addAction(action)
        
        //  Finally present the view
        self.present(alert, animated: true, completion: nil)
    }
    
    func save(){
        //  Need to add the data to the saved peripheral and save
        savedPeripheral?.commands = self.commands as NSObject
        PersistenceService.saveContext()
    }
    
    // MARK: - BLE Notifications
    private weak var didUpdatePreferencesObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdatePreferencesObserver = notificationCenter.addObserver(forName: .didUpdatePreferences, object: nil, queue: .main) { [weak self] _ in
                self?.tableView.reloadData()
            }
        } else {
            if let didUpdatePreferencesObserver = didUpdatePreferencesObserver {notificationCenter.removeObserver(didUpdatePreferencesObserver)}
        }
    }
}

//  MARK: - Data Source
extension ButtonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count == 0 ? 1 : commands.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  If no cells, just say no buttons
        if commands.count == 0 {
            let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "Default")
            defaultCell.textLabel?.text = "No Buttons Saved"
            return defaultCell
        }
        
        //  Will need to populate this with each command
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Command")
        
        //  Customize the cell for the command
        cell.textLabel?.text = commands[indexPath.row][0]
        cell.detailTextLabel?.text = commands[indexPath.row][1]
        
        //  Return the cell
        return cell
    }
}

//  MARK: - Delegate
extension ButtonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Only send if available
        if commands.count == 0 { return }
        
        //  Need to send the given message for that command
        var newText = commands[indexPath.row][1]
        
        // Eol
        if Preferences.uartIsAutomaticEolEnabled {
            newText += Preferences.uartEolCharacters
        }
        
        //  Send the data
        send(message: newText)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return commands.count == 0 ? false : true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete){
            //  Need to remove the command at the given location
            commands.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
}

//  MARK: - UART Packet Manager
extension ButtonsViewController: UartPacketManagerDelegate{
    func onUartPacket(_ packet: UartPacket) {
        //  Don't care that we received any data... don't do anything with it now
        return
    }
    
    
    
}
