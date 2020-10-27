//
//  MonitorBaseViewController.swift
//  PipelineBLE
//
//  Created by Ritesh Misra on 10/26/20.
//  Copyright © 2020 Samuel Peterson. All rights reserved.
//

import Foundation
import UIKit
import UIColor_Hex

class MonitorBaseViewController: UIViewController {
    
    //  UI Components
    private let pageTitle = "UART"
    var comTextView: UITextView = {
        let textView = UITextView()
        textView.returnKeyType = .done
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.backgroundColor = UIColor(white: 1, alpha: 0.2)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    var inputTextField: UARTTextField = {
        let textField = UARTTextField()
        return textField
    }()
    var sendButton: UARTButtons = {
        let button = UARTButtons()
        button.configureVisual(text: "Send")
        return button
    }()
    var clearButton: UARTButtons = {
        let button = UARTButtons()
        button.configureVisual(text: "Clear")
        return button
    }()
    var saveBarButton: UIBarButtonItem!
    var exportButton: UIBarButtonItem!
    var startCommandButton: UIBarButtonItem!
    var sendCountToPeripherals = 0
    
    var originalHeight: CGFloat?
    
    fileprivate static var dataRxFont = UIFont(name: "CourierNewPSMT", size: 18)!
    fileprivate static var dataTxFont = UIFont(name: "CourierNewPS-BoldMT", size: 18)!
    
    weak var blePeripheral: BlePeripheral?
    internal var uartData: UartPacketManagerBase!
    fileprivate var dataManager: UartDataManager!
    fileprivate let timestampDateFormatter = DateFormatter()
    fileprivate var tableCachedDataBuffer: [UartPacket]?
    fileprivate var textCachedBuffer = NSMutableAttributedString()
    
    private let keyboardPositionNotifier = KeyboardPositionNotifier()

    override func viewDidLoad() {
        super.viewDidLoad()
        //  Initialize Uart data manager
        dataManager = UartDataManager(delegate: self, isRxCacheEnabled: true)
        
        
        //  Make self delegate to keyboard and textview
        keyboardPositionNotifier.delegate = self
        inputTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        registerNotifications(enabled: true)
        
        //Set up UI
        originalHeight = view.frame.height
        configureUI()
        
        // UI
        reloadDataUI()
        
        // Enable Uart
        setupUart()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //  Cancel notifications
        registerNotifications(enabled: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //  No need to reload the view
        comTextView.enh_cancelPendingReload()
    }
    
    // MARK: - BLE Notifications
    private weak var didUpdatePreferencesObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdatePreferencesObserver = notificationCenter.addObserver(forName: .didUpdatePreferences, object: nil, queue: .main) { [weak self] _ in
                self?.reloadDataUI()
            }
        } else {
            if let didUpdatePreferencesObserver = didUpdatePreferencesObserver {notificationCenter.removeObserver(didUpdatePreferencesObserver)}
        }
    }
    
    internal func isInMultiUartMode() -> Bool {
        assert(false, "Should be implemented by subclasses")
        return false
    }
    
    internal func setupUart() {
        assert(false, "Should be implemented by subclasses")
    }
    
    // MARK: - UI Updates
    private func reloadDataUI() {
        
        textCachedBuffer.setAttributedString(NSAttributedString())
        let dataPackets = uartData.packetsCache()
        for dataPacket in dataPackets {
            onUartPacketText(dataPacket)
        }
        comTextView.attributedText = textCachedBuffer
        reloadData()
        
        
        //updateBytesUI()
    }
    
    /*  Will eventually use for keeping track of bytes sent
    fileprivate func updateBytesUI() {
        let localizationManager = LocalizationManager.shared
        let sentBytesMessage = String(format: localizationManager.localizedString("uart_sentbytes_format"), arguments: [uartData.sentBytes])
        let receivedBytesMessage = String(format: localizationManager.localizedString("uart_receivedbytes_format"), arguments: [uartData.receivedBytes])
        
        //statsLabel.text = String(format: "%@     %@", arguments: [sentBytesMessage, receivedBytesMessage])
    }*/
    
    // MARK: - Style
    internal func colorForPacket(packet: UartPacket) -> UIColor {
        assert(false, "Should be implemented by subclasses")
        return .black
    }
    
 /*   internal func send(message: String){
        assert(false, "Should be implemented by subclasses")
    }*/
    
    fileprivate func fontForPacket(packet: UartPacket) -> UIFont {
        let font = packet.mode == .tx ? MonitorViewController.dataTxFont : MonitorViewController.dataRxFont
        return font
    }
    
    internal func updateUartReadyUI(isReady: Bool) {
        inputTextField.isEnabled = isReady
        //inputTextField.backgroundColor = isReady ? UIColor.white : UIColor.black.withAlphaComponent(0.1)
        sendButton.isEnabled = isReady
    }

}

//  MARK: - UI Configuration
extension MonitorBaseViewController {
    
    func configureUI(){
        //  Set up the standard UI
        view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
        
        //  Set up the standard UI
        saveBarButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(onClickSave(_:)))
        exportButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onClickExport(_:)))
        startCommandButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onClickStart(_:)))
        
        //  Configure the Navigation control bar buttons
        navigationItem.rightBarButtonItems = [exportButton, saveBarButton]

        //  Add subviews to the main view
        view.addSubview(comTextView)
        view.addSubview(inputTextField)
        view.addSubview(sendButton)
        view.addSubview(clearButton)

        //  Set up constraints for com box
        var textViewConstraint = navigationController?.navigationBar.frame.height ?? 20
        textViewConstraint += 30
        comTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: textViewConstraint).isActive = true
        comTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        comTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        comTextView.bottomAnchor.constraint(equalTo: inputTextField.topAnchor, constant: -5).isActive = true
        //comTextView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7)

        //  Set up constraints for the input text field
        //inputTextField.topAnchor.constraint(equalTo: comTextView.bottomAnchor, constant: 5).isActive = true
        //inputTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        inputTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -5).isActive = true
        //inputTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)

        //  Set up constraints for the send button
        sendButton.topAnchor.constraint(equalTo: comTextView.bottomAnchor, constant: 5).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: inputTextField.trailingAnchor, constant: 5).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -5).isActive = true


        //  Set up constraints for the clear button
        clearButton.topAnchor.constraint(equalTo: comTextView.bottomAnchor, constant: 5).isActive = true
        clearButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        clearButton.leadingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: 5).isActive = true

        //  Changing the size of the input text field
        sendButton.widthAnchor.constraint(equalToConstant: sendButton.intrinsicContentSize.width + 10).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: clearButton.intrinsicContentSize.width + 10).isActive = true
    }
    
    func barButtons(running: Bool){
        //  Change the bar buttons according to whether or not we are running
        if running {
            navigationItem.setRightBarButtonItems([exportButton], animated: true)
        }
        else{
            navigationItem.setRightBarButtonItems([startCommandButton,exportButton], animated: true)
        }
    }
}

extension MonitorBaseViewController {
    //  MARK: - Actions
    @objc func onClickSend(_ sender: AnyObject) {
        //guard let blePeripheral = blePeripheral else { return }
        
        var newText = inputTextField.text ?? ""
        
        // Eol
        if Preferences.uartIsAutomaticEolEnabled {
            newText += Preferences.uartEolCharacters
        }
        
        send(message: newText)
        
        inputTextField.text = ""
        inputTextField.resignFirstResponder()
    }
    
    @objc func onClickClear(_ sender: AnyObject) {
        uartData.clearPacketsCache()
        reloadDataUI()
    }
    
    func onInputTextFieldEdidtingDidEndOnExit(_ sender: UITextField) {
        onClickSend(sender)
    }
    
    @objc func onClickSave(_ sender: AnyObject){
        print("Trying to save data")
        inputTextField.resignFirstResponder()
        //  Need to get an identifier for this data
        let alert = UIAlertController(title: "Save UART Data", message: "This data will be saved for each device. Please enter an identifier for this data:", preferredStyle: .alert)
        alert.addTextField{ (textField) in
            textField.placeholder = "identifier"
        }
        let action = UIAlertAction(title: "Save", style: .default){ (_) in
            //  Save the text that is in the textfield currently
            let id = alert.textFields!.first!.text ?? " "
            
            //  Save to all if in multi peripheral
            if self.isInMultiUartMode(){
                for peripheral in BleManager.shared.connectedPeripherals(){
                    //  Save the data for each peripheral
                    if peripheral.hasUart(){
                        self.save(id: id, peripheral: peripheral)
                    }
                }
            }
            else {
                self.save(id: id, peripheral: self.blePeripheral!)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        //  Add the two actions
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        
        self.present(alert, animated: true, completion: nil)
        
        inputTextField.resignFirstResponder()
        //view.frame.size = CGSize(width: view.frame.width, height: originalHeight!)
    }
    
    func save(id: String, peripheral: BlePeripheral){
        //  Save the data automatically
        let data = UARTData(context: PersistenceService.context)
        data.data = self.comTextView.text
        data.setup(id: id, peripheral: peripheral)
        PersistenceService.saveContext()
    }
    
    @objc func onClickExport(_ export: UIBarButtonItem){
        //  Export button was pressed, call the export button class
        ExportData.exportData(view: self, button: exportButton, data: self.comTextView.text as NSObject)
    }
    
    
    @objc func onClickStart(_ send: UIBarButtonItem){
        //  Send a given command to the device
        let alert = UIAlertController(title: "Start Data Stream", message: "Please enter the necessary information to start the data stream: ", preferredStyle: .alert)
        alert.addTextField{ (textfield) in
            textfield.placeholder = "Sampling Frequency MHz (1, 2, 4, 8)"
        }
        alert.addTextField{ (textfield) in
            textfield.placeholder = "Number of runs"
        }
        alert.addTextField{ (textfield) in
            textfield.placeholder = "Number of samples (default 500)"
        }
        
        //  Add the action to the alert and present to user
        let action = UIAlertAction(title: "Start", style: .default){ (_) in
            let runsText = alert.textFields?.first!.text ?? ""
            let lengthText = alert.textFields?.last!.text ?? "500" //500 by default
            let frequencyText = alert.textFields?.last!.text ?? ""
            
            //  Try to get values as an int
            guard let frequency = Int(frequencyText) else {
                self.invalidInput(message: "Invalid value entered for the frequency. Please try again.")
                return
            }
            
            if frequency != 1 || frequency != 2 || frequency != 4 || frequency != 8 {
                self.invalidInput(message: "Frequency must be 1MHz, 2MHz, 4MHz, or 8MHz. Please try again.")
                return
            }
            
            guard let runs = Int(runsText) else {
                self.invalidInput(message: "Invalid value entered for the number of runs. Please try again.")
                return
            }
            guard let samples = Int(lengthText) else {
                self.invalidInput(message: "Invalid value entered for the number of samples. Please try again.")
                return
            }
            
            //  Alert the devices that are connected
            for peripheral in BleManager.shared.connectedPeripherals(){
                // Will send frequency, samples, then run count
                self.send(message: "s"+String(frequency)+"\n", peripheral: peripheral)
                usleep(500000)
                self.send(message: "t"+String(samples)+"\n", peripheral: peripheral)
                usleep(500000)
                self.send(message: "r"+String(runs)+"\n", peripheral: peripheral)
                
                //  Now let's change the button that is present on the top right
                self.barButtons(running: true)
            }
        }
        
        //  Create action that will do nothing if it is selected
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        //  Present to user
        self.present(alert,animated: true, completion: nil)
        
    }

    func invalidInput(message: String){
        //  Just alert the user that the input is invalid and they will need to retry
        let alert = UIAlertController(title: "Invalid input", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension MonitorBaseViewController: KeyboardPositionNotifierDelegate {
    
    func onKeyboardPositionChanged(keyboardFrame: CGRect, keyboardShown: Bool) {
        if keyboardShown{
            //print("Keyboard shown, changing")
            let spacerHeight = keyboardFrame.height
            view.frame.size = CGSize(width: view.frame.width, height: view.frame.height-spacerHeight)
        }
        else {
            //print("Keyboard closed, changing")
            view.frame.size = CGSize(width: view.frame.width, height: originalHeight!)
        }
    }
}

extension MonitorBaseViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension MonitorBaseViewController: UartDataManagerDelegate{
    func onUartPacket(_ packet: UartPacket) {
        // Check that the view has been initialized before updating UI
        guard isViewLoaded && view.window != nil else { return }
        
        onUartPacketText(packet)
        self.enh_throttledReloadData()      // it will call self.reloadData without overloading the main thread with calls
    }
    
    @objc func reloadData() {
        comTextView.attributedText = textCachedBuffer
            
        let textLength = textCachedBuffer.length
        if textLength > 0 {
            let range = NSMakeRange(textLength - 1, 1)
            comTextView.scrollRangeToVisible(range)
        }
    }
    
    fileprivate func onUartPacketText(_ packet: UartPacket) {
        guard Preferences.uartIsEchoEnabled || packet.mode == .rx else { return }
        
        var color = colorForPacket(packet: packet)
        let font = fontForPacket(packet: packet)
        
        //  Only want to display the sent message once
        if isInMultiUartMode() && sendCountToPeripherals != 0 && packet.mode == .tx {
            return
        }
        else if isInMultiUartMode() && sendCountToPeripherals == 0 && packet.mode == .tx {
            //  Won't want to update the UI for the same message.
            sendCountToPeripherals += 1
            color = .black
        }

        if let attributedString = attributedStringFromData(packet.data, useHexMode: Preferences.uartIsInHexMode, color: color, font: font) {
            textCachedBuffer.append(attributedString)
        }
    }
    
    func send(message: String) {
        guard let dataManager = self.dataManager else { DLog("Error send with invalid uartData class"); return }
        
        print("Sending message: \(message)")
        
        //  Single peripheral mode
        if let blePeripheral = blePeripheral {
            if let data = message.data(using: .utf8) {
                dataManager.send(blePeripheral: blePeripheral, data: data)
            }
        }
    }
    
    func send(message: String, peripheral: BlePeripheral!) {
        guard let dataManager = self.dataManager else { DLog("Error send with invalid uartData class"); return }
        
        print("Sending message: \(message)")
        
        //  Send data to specified peripheral
        if let data = message.data(using: .utf8) {
            dataManager.send(blePeripheral: peripheral, data: data)
        }
    }

    //  What to do when data is received
    func onUartRx(data: Data, peripheralIdentifier: UUID) {
 
    }
    
}
