//
//  ConnectedDeviceViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/22/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class ConnectedDeviceViewController: UIViewController {
    
    //  Data about the device
    var savedPeripherals: [UUID:SavedPeripheral] = [:]
    var hasUart = false
    var hasDfu = false
    var multiplePeripherals: Bool!
    var connectedDevices: Int!
    
    //  Enum to easily access info about the peripheral
    enum Modes: Int {
        case uart
        case buttons
        case datastream
        case savedData
        case info
        case monitor
    }
    
    //  UI Components
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.delegate = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    //  Notification Variables
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var willDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateRssiObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    
    //  RSSI refresh timer
    fileprivate var rssiRefreshTimer: MSWeakTimer?
    fileprivate static let kRssiRefreshInterval: TimeInterval = 0.3

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Do some initialization
        checkUart()

        //  Configure the view
        UISettings()
        
        //  Register cells for their identifier
        tableView.register(AvailableModulesTableViewCell.self, forCellReuseIdentifier: "AvailableModule")
        tableView.register(ConnectedDeviceTableViewCell.self, forCellReuseIdentifier: "ConnectedDevice")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  See if we are in multi peripheral mode
        connectedDevices = BleManager.shared.connectedPeripherals().count
        multiplePeripherals = connectedDevices > 1
        
        //  Register notifications
        registerNotifications(enabled: true)
        
        //  Add timer to update RSSI
        // Schedule Rssi timer
        rssiRefreshTimer = MSWeakTimer.scheduledTimer(withTimeInterval: ConnectedDeviceViewController.kRssiRefreshInterval, target: self, selector: #selector(rssiRefreshFired), userInfo: nil, repeats: true, dispatchQueue: .global(qos: .background))
        
        //  Reload data
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //  Deactivate notifications
        registerNotifications(enabled: false)
        
        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
    func UISettings(){
        //  Change the page title in the navigation bar
        self.title = "Device Menu"
        
        //  Add table view
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    @objc private func rssiRefreshFired() {
        //  Reread Rssi for connected devices
        for device in BleManager.shared.connectedPeripherals(){
            device.readRssi()
        }
    }
    
    func checkUart(){
        //  Check if uart is available
        hasUart = false
        for device in BleManager.shared.connectedPeripherals() {
            if device.hasUart(){
                hasUart = true
            }
        }
    }
    
    func isInMultiUartMode() -> Bool {
        return BleManager.shared.connectedPeripherals().count > 1
    }
    
    fileprivate func DefineModes() -> [Modes]{
        if hasUart {
            if isInMultiUartMode(){
                return [.uart, .datastream, .savedData, .info, .monitor]
            } else {
                return [.uart, .buttons, .datastream, .savedData, .info, .monitor]
            }
        }
        else{
            //  Does not conform to the requirements... Decide to maybe display some
            //  generic information here
            return [.info]
        }
    }
}

//  MARK: - TableView Data Source
extension ConnectedDeviceViewController: UITableViewDataSource {
    
    //  Use for knowing what section and what information to show
    enum TableSection: Int {
        case device = 0
        case modules = 1
    }
    
    //  Have two sections: Device and Modules
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //  Grab the necessary section header
        var localizationKey: String!
        
        switch TableSection(rawValue: section)! {
        case .device:
            localizationKey = "peripheralmodules_sectiontitle_device_single"
        case .modules:
            localizationKey = "peripheralmodules_sectiontitle_modules"
        }
        
        return LocalizationManager.shared.localizedString(localizationKey)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //  Find out how many modes depending on the section
        switch TableSection(rawValue: section)! {
        case .device:
            //  Display multiple devices
            return BleManager.shared.connectedPeripherals().count
        case .modules:
            //  Only have enough rows for the number of modules available
            return DefineModes().count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Need to choose the right cell to display depending on section
        var identifier: String
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            //  Need to display the device that is selected
            identifier = "ConnectedDevice"
        case .modules:
            identifier = "AvailableModule"
        }
        
        //  Create the cell based on the identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        return cell
    }
    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //  Need to set the height of the cells
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            return 60
        case .modules:
            return 44
        }
    }
}

//  MARK: - TableView Delegate
extension ConnectedDeviceViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //  Will need to display localized strings
        let localizationManager = LocalizationManager.shared
        
        //  Need to take action depending on what type of cell it is
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            //  Make sure that the cell passed is of the right type
            guard let deviceCell = cell as? ConnectedDeviceTableViewCell else { return }
            
            let peripheral = BleManager.shared.connectedPeripherals()[indexPath.row]
            
            //  Will now need to send info about the device so it can be displayed
            deviceCell.deviceName.text = savedPeripherals[peripheral.identifier]?.name! ?? localizationManager.localizedString("scanner_unnamed")
            deviceCell.subtitle.text = peripheral.hasUart() ? localizationManager.localizedString("scanner_uartavailable") : "UART Unavailable"
            deviceCell.signalImage.image = RssiUI.signalImage(for: peripheral.rssi)
            
        case .modules:
            //  Need to make sure that the cell is of the right type
            guard let moduleCell = cell as? AvailableModulesTableViewCell else { return }
            
            //  Create variables to store data that will be passed
            var moduleName: String?
            var moduleIcon: String?
            let availableModules = DefineModes()
            
            //  Now need to see what module and info needs to be passed
            switch availableModules[indexPath.row] {
            case .uart:
                moduleIcon = "UART_Icon"
                moduleName = localizationManager.localizedString("uart_tab_title")
            case .buttons:
                moduleIcon = "Buttons_Icon"
                moduleName = "Buttons"
            case .datastream:
                moduleIcon = "Data_Stream_Icon"
                moduleName = "Data Stream"
            case .savedData:
                moduleIcon = "Saved_Data_ Icon"
                moduleName = "Saved Data"
            case .info:
                moduleIcon = "Info_Icon"
                moduleName = localizationManager.localizedString("info_tab_title")
            case .monitor:
                moduleIcon = "Monitor_Icon"
                moduleName = "Monitor"
            }
            
            //  Now pass the data to the cell
            moduleCell.moduleName.text = moduleName
            moduleCell.moduleImage.image = moduleIcon != nil ? UIImage(named: moduleIcon!) : nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  One of the modules has now been selected
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            //  Don't want anything to happen here, so just return
            return
        case .modules:
            //  Want to go to the selected module
            let modes = DefineModes()
            
            switch modes[indexPath.row]{
            case .uart:
                //  Selected UART, need to open the view controller
                let uartViewController = UARTViewController()
                
                //  Send data depending on multi peripherals
                if multiplePeripherals{
                    self.storyboard?.instantiateViewController(withIdentifier: "UARTViewController")
                }
                else{
                    let peripheral = BleManager.shared.connectedPeripherals().first
                    uartViewController.blePeripheral = peripheral
                }
                uartViewController.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(uartViewController, animated: true)
            case .monitor:
                // Selected monitor
                let monitorViewController = MonitorViewController()
                monitorViewController.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(monitorViewController, animated: true)
                
            case .buttons:
                //  Need to open the buttons view controller
                let buttonsViewController = ButtonsViewController()
                buttonsViewController.hidesBottomBarWhenPushed = true
                let peripheral = BleManager.shared.connectedPeripherals().first
                buttonsViewController.blePeripheral = peripheral
                buttonsViewController.savedPeripheral = savedPeripherals[peripheral!.identifier]
                navigationController?.pushViewController(buttonsViewController, animated: true)
            case .datastream:
                //  Open data stream view controller
                //let dataStreamViewController = DataStreamViewController()
                
                let dataStreamViewController = DataStreamContainerViewController()
                dataStreamViewController.hidesBottomBarWhenPushed = true
//                dataStreamViewController.blePeripheral = selectedPeripheral
                navigationController?.pushViewController(dataStreamViewController, animated: true)
            case .savedData:
                //  Open a certain controller depending on wether we are in multiple mode or not
                if multiplePeripherals {
                    //  Connected to multiple peripherals, so need to select only one of them
                    let savedDataViewController = PeripheralInfoSelectorViewController()
                    savedDataViewController.hidesBottomBarWhenPushed = true
                    savedDataViewController.infoMode = false
                    savedDataViewController.connectedPeripherals = BleManager.shared.connectedPeripherals()
                    savedDataViewController.savedPeripherals = savedPeripherals
                    navigationController?.pushViewController(savedDataViewController, animated: true)
                }
                else{
                    //  Only connected to one, so send data for the single device
                    let peripheral = BleManager.shared.connectedPeripherals().first
                    let savedDataViewController = SavedDataViewController()
                    savedDataViewController.hidesBottomBarWhenPushed = true
                    savedDataViewController.blePeripheral = peripheral
                    navigationController?.pushViewController(savedDataViewController, animated: true)
                }
                
            case .info:
                //  Open a certain controller depending on wether we are in multiple mode or not
                if multiplePeripherals {
                    //  Connected to multiple peripherals, so need to select only one of them
                    let infoViewController = PeripheralInfoSelectorViewController()
                    infoViewController.infoMode = true
                    infoViewController.hidesBottomBarWhenPushed = true
                    infoViewController.connectedPeripherals = BleManager.shared.connectedPeripherals()
                    infoViewController.savedPeripherals = savedPeripherals
                    navigationController?.pushViewController(infoViewController, animated: true)
                }
                else{
                    //  Only connected to one, so send data for the single device
                    let peripheral = BleManager.shared.connectedPeripherals().first
                    let infoViewController = DeviceInfoViewController()
                    infoViewController.hidesBottomBarWhenPushed = true
                    infoViewController.blePeripheral = peripheral
                    infoViewController.savedPeripheral = savedPeripherals[peripheral!.identifier]
                    navigationController?.pushViewController(infoViewController, animated: true)
                } 
            }
        }
        tableView.deselectRow(at: indexPath, animated: indexPath.section == 0)
    }
    
}

//  MARK: - Notifications Manager
extension ConnectedDeviceViewController {
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default

        if enabled {
            peripheralDidUpdateRssiObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateRssi, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateRssi(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
        } else {
            if let peripheralDidUpdateRssiObserver = peripheralDidUpdateRssiObserver {notificationCenter.removeObserver(peripheralDidUpdateRssiObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
        }
    }
    
    fileprivate func peripheralDidUpdateRssi(notification: Notification) {
        //  Make sure the device that is disconnecting is one we are connected to
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, savedPeripherals[identifier] != nil else { return }
        
        // Update section
        tableView.reloadSections([TableSection.device.rawValue], with: .none)
    }
    
    private func didDisconnectFromPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, savedPeripherals[identifier] != nil else { return }
        
        let savedPeripheral = savedPeripherals[identifier]

        DLog("detail: peripheral \(savedPeripheral!.name!) didDisconnect")
        
        //  Need to update variables depending on devices that are disconnecting
        if connectedDevices == 1 {
            //  We are not in multi peripheral mode
            //  need to return since we are no longer connected to a device
            savedPeripherals[identifier] = nil
            
            // Disable Rssi timer
            rssiRefreshTimer?.invalidate()
            rssiRefreshTimer = nil
            
            //  Now return
            goBackToPeripheralList()
        }
        else{
            // Still have devices that are connected, need to update
            connectedDevices -= 1
            
            //  Check if we are in single peripheral mode now
            multiplePeripherals = connectedDevices > 1
            
            //  Remove the device from the saved peripherals
            savedPeripherals[identifier] = nil
            
            //  Need to check if we have uart still available
            checkUart()
            
            //  Reload data
            tableView.reloadData()
        }

    }

    private func goBackToPeripheralList() {
        // Back to peripheral list
        navigationController?.popToRootViewController(animated: true)
    }
}
