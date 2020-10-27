//
//  AvailableDevicesViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/8/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import CoreData

class AvailableDevicesViewController: UITableViewController {
    
    //  Data for searching for peripheral
    fileprivate var peripheralList: PeripheralList!
    fileprivate var isBaseTableScrolling = false
    fileprivate var isScannerTableWaitingForReload = false
    fileprivate var isBaseTableAnimating = false
    fileprivate var isRowDetailOpenForPeripheral = [UUID: Bool]()
    
    //  System controllers
    fileprivate let refreshController = UIRefreshControl()
    fileprivate var infoAlertController: UIAlertController?
    fileprivate var isMultiConnectEnabled = false
    fileprivate let firmwareUpdater = FirmwareUpdater()
    
    //  Store object protocols
    private weak var didUpdateBleStateObserver: NSObjectProtocol?
    private weak var didDiscoverPeripheralObserver: NSObjectProtocol?
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateNameObserver: NSObjectProtocol?
    
    //  Bar button to go to connected devices page
    var nextPageButton: UIBarButtonItem!
    
    //  Data for when a peripheral has been selected
    weak var selectedPeripheral: BlePeripheral?
    var savedDevices: [UUID: SavedPeripheral] = [:]
    var dirtyData: Bool = true
    
    //  Section off the pages
    enum TableSection: Int {
        case connectedDevices = 0
        case availableDevices = 1
    }
    
    override func viewDidLoad() {
        //  Get saved peripherals
        getSavedPeripherals()
        
        super.viewDidLoad()
        
        //  View just appeared, configure the layout
        navigationItem.title = "Available Devices"
        
        //  Initialize the peripheral list here
        peripheralList = PeripheralList()
        
        //  Control when the table will update
        refreshController.addTarget(self, action: #selector(onTableRefresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshController)
        tableView.sendSubviewToBack(refreshController)
        
        //  Add a bar button to progress to the next page when connected to a device
        nextPageButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextPage(_:)))
        nextPageButton.isEnabled = false
        navigationItem.rightBarButtonItem = nextPageButton
        
        //  The cells will be taken from the available devices table view cell
        tableView.register(AvailableDevicesTableViewCell.self, forCellReuseIdentifier: "AvailableDevice")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Flush any pending state notifications
        didUpdateBleState()
        
        //  Ble Notifications
        registerNotifications(enabled: true)
        DLog("Scanner: Register notifications")
        
        //  Disconnect from all devices
        if BleManager.shared.connectedPeripherals().count != 0 {
            DLog("Disconnecting from previously connected peripherals")
            disconnectAll()
            nextPageButton.isEnabled = false
        }
        
        //  Scan for peripherals
        BleManager.shared.startScan()
        updateScannedPeripherals()
        
        //  Make sure the tab bar is visible
        self.hidesBottomBarWhenPushed = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop scanning
        BleManager.shared.stopScan()
        
        // Ble Notifications
        registerNotifications(enabled: false)
        
        // Clear peripherals
        peripheralList.clear()
        isRowDetailOpenForPeripheral.removeAll()
        
        dirtyData = true
    }
    
    //  MARK: - Table View Editing
    override func numberOfSections(in tableView: UITableView) -> Int {
        //  Want sections for available/connected devices
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //  Will want to display headers for connected and available devices
        switch TableSection(rawValue: section)! {
        case .connectedDevices:
            return "Connected Devices"
        case .availableDevices:
            return "Available Devices"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //  Calculate the number of cells depending on the section
        switch TableSection(rawValue: section)! {
        case .connectedDevices:
            //  Need to show however many devices are currently connected
            return BleManager.shared.connectedPeripherals().count
        case .availableDevices:
            //  Do as we normally did and return however many peripherals are detected
            if selectedPeripheral == nil {      // Dont update while a peripheral has been selected
                WatchSessionManager.shared.updateApplicationContext(mode: .scan)
            }
            
            //  Get the list of peripherals that are not connected or connecting
            let filteredPeripheralList = peripheralList.filteredPeripherals(forceUpdate: false).filter {$0.state == .disconnected || $0.state == .disconnecting}
            return filteredPeripheralList.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Create a cell of type AvailableDevicesTableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableDevice", for: indexPath) as! AvailableDevicesTableViewCell
        
        //  Generate cells for connected devices and available devices
        var peripheral: BlePeripheral
        switch TableSection(rawValue: indexPath.section)! {
        case .connectedDevices:
            //  Need to show connected devices
            peripheral = BleManager.shared.connectedPeripherals()[indexPath.row]
        case .availableDevices:
            //  Need to show devices that are available
            let filteredPeripheralList = peripheralList.filteredPeripherals(forceUpdate: false).filter {$0.state == .disconnected || $0.state == .disconnecting}
            peripheral = filteredPeripheralList[indexPath.row]
        }
        
        //  Initialize the localization manager
        let localizationManager = LocalizationManager.shared
        
        //  Now need to check if the peripheral has been saved
        let saved = savedDevices[peripheral.identifier] != nil && savedDevices[peripheral.identifier]?.name != nil
        
        //  If it is saved, change the text and set subtitle accordingly
        if saved {
            cell.deviceName.text = savedDevices[peripheral.identifier]?.name!
        }
        else{
            //  Set the device name
            cell.deviceName.text = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        }
        
        //  Send the cell what the subtitle should be and the image
        cell.signalImage.image = RssiUI.signalImage(for: peripheral.rssi)
        cell.setSubtitle(text: peripheral.name ?? localizationManager.localizedString("scanner_unnamed"), saved: saved)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Connected to the device if available, do nothing if already connected
        switch TableSection(rawValue: indexPath.section)! {
        case .connectedDevices:
            //  Don't do anything
            return
        case .availableDevices:
            //  Grab the peripheral that was selected
            let filteredPeripheralList = peripheralList.filteredPeripherals(forceUpdate: false).filter {$0.state == .disconnected || $0.state == .disconnecting}
            let peripheral = filteredPeripheralList[indexPath.row]
            
            //  Display what peripheral was selected
            print("Selected \(peripheral.name ?? "No name available")")
            
            //  Save the peripheral if necessary
            if savedDevices[peripheral.identifier] == nil {
                //  Not currently saved
                savePeripheralPrompt(peripheral: peripheral)
            }
            else{
                //  Connect to the peripheral
                connect(peripheral: peripheral)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //  Allow devices to be deleted from connected devices to disconnect
        switch TableSection(rawValue: indexPath.section)! {
        case .connectedDevices:
            // Allow devices to be disconnected
            return true
        case .availableDevices:
            //  Don't allow editing of available devices
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete){
            //  Want to disconnect from the device
            let peripheral = BleManager.shared.connectedPeripherals()[indexPath.row]
            self.disconnect(peripheral: peripheral)
        }
    }
    
    //  Get saved peripherals
    func getSavedPeripherals(){
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
        
        self.dirtyData = false
    }
    
    @objc func onTableRefresh(_ sender: AnyObject) {
        refreshPeripherals()
        refreshController.endRefreshing()
    }
    
    fileprivate func refreshPeripherals() {
        isRowDetailOpenForPeripheral.removeAll()
        BleManager.shared.refreshPeripherals()
        reloadBaseTable()
    }
    
    private func updateScannedPeripherals() {
        // Reload table
        if isBaseTableScrolling || isBaseTableAnimating {
            isScannerTableWaitingForReload = true
        } else {
            reloadBaseTable()
        }
    }
    
    fileprivate func reloadBaseTable() {
        //  Reload the table of peripherals
        isBaseTableScrolling = false
        isBaseTableAnimating = false
        isScannerTableWaitingForReload = false
        
        //  Get the filtered peripherals (no actual filtering)
        _ = peripheralList.filteredPeripherals(forceUpdate: true)
        
        if self.dirtyData {
            getSavedPeripherals()
        }
        
        tableView.reloadData()
        
        //        print("Filtered: \(peripheralList.filteredPeripherals(forceUpdate: false).count)")
    }
    
    
    
    // MARK: - Navigation
    @objc func nextPage(_ next: UIBarButtonItem?){
        if BleManager.shared.connectedPeripherals().isEmpty {
            //  Not connected to any devices, so don't proceed
            return
        }
        
        //  Need to collect all the saved devices
        var savedPeripherals: [UUID:SavedPeripheral] = [:]
        for device in BleManager.shared.connectedPeripherals() {
            savedPeripherals[device.identifier] = savedDevices[device.identifier]!
        }
        
        //  Need to move to the next page
        let connectToDevice = ConnectedDeviceViewController()
        
        //  Send some initial data
        connectToDevice.savedPeripherals = savedPeripherals
        
        //  Hide the tab bar when pushed and then push the view
        connectToDevice.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(connectToDevice, animated: true)
    }
    
    fileprivate func dismissInfoDialog(completion: (() -> Void)? = nil) {
        guard infoAlertController != nil else {
            completion?()
            return
        }
        
        infoAlertController?.dismiss(animated: true, completion: completion)
        infoAlertController = nil
    }
    
    // MARK: - Check Updates
    private func startUpdatesCheck(peripheral: BlePeripheral) {
        DLog("Check firmware updates")
        // Refresh available updates
        firmwareUpdater.checkUpdatesForPeripheral(peripheral, delegate: self as FirmwareUpdaterDelegate, shouldDiscoverServices: false, shouldRecommendBetaReleases: false, versionToIgnore: Preferences.softwareUpdateIgnoredVersion)
    }
    
    fileprivate func showUpdateAvailableForRelease(_ latestRelease: FirmwareInfo) {
        let localizationManager = LocalizationManager.shared
        let alert = UIAlertController(title: localizationManager.localizedString("autoupdate_title"),
                                      message: String(format: localizationManager.localizedString("autoupdate_description_format"), latestRelease.version),
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: localizationManager.localizedString("autoupdate_ignore"), style: UIAlertAction.Style.cancel, handler: { _ in
            Preferences.softwareUpdateIgnoredVersion = latestRelease.version
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func presentInfoDialog(title: String, peripheral: BlePeripheral) {
        if infoAlertController != nil {
            infoAlertController?.dismiss(animated: true, completion: nil)
        }
        
        infoAlertController = UIAlertController(title: nil, message: title, preferredStyle: .alert)
        infoAlertController!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            BleManager.shared.disconnect(from: peripheral)
            //BleManager.sharedInstance.refreshPeripherals()      // Force refresh because they wont reappear. Check why is this happening
        }))
        present(infoAlertController!, animated: true, completion:nil)
    }
}

//  MARK: UIScrollViewDelegate
extension AvailableDevicesViewController {
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isBaseTableScrolling = true
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isBaseTableScrolling = false
        
        if isScannerTableWaitingForReload {
            reloadBaseTable()
        }
    }
}

//  Mark: Adafruit Bluetooth Connection
extension AvailableDevicesViewController{
    //  Setting up the device
    private func discoverServices(peripheral: BlePeripheral) {
        DLog("Discovering services")
        
        peripheral.discover(serviceUuids: nil) { [weak self] error in
            guard let context = self else { return }
            let localizationManager = LocalizationManager.shared
            
            DispatchQueue.main.async {
                guard error == nil else {
                    DLog("Error initializing peripheral")
                    context.dismiss(animated: true, completion: { [weak self] () -> Void in
                        if let context = self {
                            showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("peripheraldetails_errordiscoveringservices"))
                            BleManager.shared.disconnect(from: peripheral)
                        }
                    })
                    return
                }
                
                if context.isMultiConnectEnabled {
                    context.dismissInfoDialog {
                    }
                } else {
                    // Check updates if needed
                    context.infoAlertController?.message = localizationManager.localizedString("peripheraldetails_checkingupdates")
                    context.startUpdatesCheck(peripheral: peripheral)
                }
            }
        }
    }
    
    // MARK: - BLE Notifications
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateBleStateObserver = notificationCenter.addObserver(forName: .didUpdateBleState, object: nil, queue: .main, using: {[weak self] _ in self?.didUpdateBleState()})
            didDiscoverPeripheralObserver = notificationCenter.addObserver(forName: .didDiscoverPeripheral, object: nil, queue: .main, using: {[weak self] _ in self?.didDiscoverPeripheral()})
            willConnectToPeripheralObserver = notificationCenter.addObserver(forName: .willConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willConnectToPeripheral(notification: notification)})
            didConnectToPeripheralObserver = notificationCenter.addObserver(forName: .didConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didConnectToPeripheral(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
            peripheralDidUpdateNameObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateName, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateName(notification: notification)})
        } else {
            if let didUpdateBleStateObserver = didUpdateBleStateObserver {notificationCenter.removeObserver(didUpdateBleStateObserver)}
            if let didDiscoverPeripheralObserver = didDiscoverPeripheralObserver {notificationCenter.removeObserver(didDiscoverPeripheralObserver)}
            if let willConnectToPeripheralObserver = willConnectToPeripheralObserver {notificationCenter.removeObserver(willConnectToPeripheralObserver)}
            if let didConnectToPeripheralObserver = didConnectToPeripheralObserver {notificationCenter.removeObserver(didConnectToPeripheralObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
            if let peripheralDidUpdateNameObserver = peripheralDidUpdateNameObserver {notificationCenter.removeObserver(peripheralDidUpdateNameObserver)}
        }
    }
    
    private func didUpdateBleState() {
        guard let state = BleManager.shared.centralManager?.state else { return }
        
        // Check if there is any error
        var errorMessageId: String?
        switch state {
        case .unsupported:
            errorMessageId = "bluetooth_unsupported"
        case .unauthorized:
            errorMessageId = "bluetooth_notauthorized"
        case .poweredOff:
            errorMessageId = "bluetooth_poweredoff"
        default:
            errorMessageId = nil
        }
        
        // Show alert if error found
        if let errorMessageId = errorMessageId {
            let localizationManager = LocalizationManager.shared
            let errorMessage = localizationManager.localizedString(errorMessageId)
            DLog("Error: \(errorMessage)")
            
            // Reload peripherals
            refreshPeripherals()
            
            // Show error
            let alertController = UIAlertController(title: localizationManager.localizedString("dialog_error"), message: errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default, handler: { (_) -> Void in
                if let navController = self.splitViewController?.viewControllers[0] as? UINavigationController {
                    navController.popViewController(animated: true)
                }
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func didDiscoverPeripheral(){
        updateScannedPeripherals()
    }
    
    private func willConnectToPeripheral(notification: Notification) {
        guard let peripheral = BleManager.shared.peripheral(from: notification) else { return }
        presentInfoDialog(title: LocalizationManager.shared.localizedString("peripheraldetails_connecting"), peripheral: peripheral)
    }
    
    fileprivate func connect(peripheral: BlePeripheral) {
        //  Connecting to a device, so enable the next button
        nextPageButton.isEnabled = true
        
        //  When we connect, will update the list of connected devices via blemanager
        selectedPeripheral = peripheral
        BleManager.shared.connect(to: peripheral)
        reloadBaseTable()
    }
    
    fileprivate func disconnectAll() {
        //  Disable button
        nextPageButton.isEnabled = false
        
        //  Disconnect from all peripherals
        for peripheral in BleManager.shared.connectedPeripherals(){
            BleManager.shared.disconnect(from: peripheral)
        }
        selectedPeripheral = nil
        reloadBaseTable()
    }
    
    fileprivate func disconnect(peripheral: BlePeripheral){
        //  Disconnect from a single device
        selectedPeripheral = nil
        BleManager.shared.disconnect(from: peripheral)
        reloadBaseTable()
        
        //  Check if next needs to be disabled
        if BleManager.shared.connectedPeripherals().count == 0 {
            nextPageButton.isEnabled = false
        }
    }
    
    private func didConnectToPeripheral(notification: Notification) {
        guard let selectedPeripheral = selectedPeripheral, let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, selectedPeripheral.identifier == identifier else {
            DLog("Connected to an unexpected peripheral")
            return
        }
        
        // Discover services
        infoAlertController?.message = LocalizationManager.shared.localizedString("peripheraldetails_discoveringservices")
        discoverServices(peripheral: selectedPeripheral)
    }
    
    private func didDisconnectFromPeripheral(notification: Notification) {
        let peripheral = BleManager.shared.peripheral(from: notification)
        let currentlyConnectedPeripheralsCount = BleManager.shared.connectedPeripherals().count
        
        guard let selectedPeripheral = selectedPeripheral, selectedPeripheral.identifier == peripheral?.identifier || currentlyConnectedPeripheralsCount == 0 else {        // If selected peripheral is disconnected or if there are no peripherals connected (after a failed dfu update)
            return
        }
        
        // Clear selected peripheral
        self.selectedPeripheral = nil
        
        // Watch
        WatchSessionManager.shared.updateApplicationContext(mode: .scan)
        
        // Dismiss any info open dialogs
        infoAlertController?.dismiss(animated: true, completion: nil)
        infoAlertController = nil
        
        // Reload table
        reloadBaseTable()
    }
    
    private func peripheralDidUpdateName(notification: Notification) {
        let name = notification.userInfo?[BlePeripheral.NotificationUserInfoKey.name.rawValue] as? String
        DLog("centralManager peripheralDidUpdateName: \(name ?? "<unknown>")")
        
        DispatchQueue.main.async {
            // Reload table
            self.reloadBaseTable()
        }
    }
}

// MARK: - FirmwareUpdaterDelegate
extension AvailableDevicesViewController: FirmwareUpdaterDelegate {
    
    func onFirmwareUpdateAvailable(isUpdateAvailable: Bool, latestRelease: FirmwareInfo?, deviceDfuInfo: DeviceDfuInfo?) {
        
        DLog("FirmwareUpdaterDelegate isUpdateAvailable: \(isUpdateAvailable)")
        
        DispatchQueue.main.async {
            self.dismissInfoDialog {
                if isUpdateAvailable, let latestRelease = latestRelease {
                    self.showUpdateAvailableForRelease(latestRelease)
                }
            }
        }
    }
}

//  MARK: - Saving Peripherals
extension AvailableDevicesViewController {
    func savePeripheralPrompt(peripheral: BlePeripheral){
        //  Create localization manager
        let localizationManager = LocalizationManager.shared
        
        //  Create an alert for the user
        let alert = UIAlertController(title: "Save Device", message: "Would you like to save the device under a different name? If yes, please enter the name below.", preferredStyle: .alert)
        alert.addTextField{ (textfield) in
            textfield.placeholder = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        }
        
        //  For right now, the new name will be the current name unless changed
        let newNameAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            //  Got the name, now set up to save
            self.saveAndConnect(peripheral: peripheral, name: alert.textFields!.first!.text ?? " ")
        }
        let sameNameAction = UIAlertAction(title: "No", style: .default){ (_) in
            //  Now save and connect
            self.saveAndConnect(peripheral: peripheral, name: peripheral.name ?? localizationManager.localizedString("scanner_unnamed"))
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        //  Add the actions to the alert
        alert.addAction(newNameAction)
        alert.addAction(sameNameAction)
        alert.addAction(cancelAction)
        
        //  Present to the user
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveAndConnect(peripheral: BlePeripheral, name: String){
        //  Want to save information about the device
        let localizationManager = LocalizationManager.shared
        
        //  Original data to save for the device
        let newPeripheral = SavedPeripheral(context: PersistenceService.context)
        newPeripheral.name = name
        newPeripheral.originalName = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        newPeripheral.uuid = peripheral.identifier
        
        //  Add to the list of peripherals
        savedDevices[newPeripheral.uuid!] = newPeripheral
        
        //  All data is set, save the context
        PersistenceService.saveContext()
        
        //  Make sure to know if data needs to be reloaded
        dirtyData = true
        
        //  Now, connect to the peripheral
        self.connect(peripheral: peripheral)
    }
    
    
    
    
}
