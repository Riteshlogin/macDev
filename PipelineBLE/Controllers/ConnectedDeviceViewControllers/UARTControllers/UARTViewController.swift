//
//  UARTViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/7/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class UARTViewController: UARTBaseViewController {
    
    //  Data
    fileprivate var colorForPeripheral = [UUID: UIColor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //  Init Uart
        uartData = UartPacketManager(delegate: self, isPacketCacheEnabled: true, isMqttEnabled: true)
        
        //  Need to add actions for the buttons
        sendButton.addTarget(self, action: #selector(onClickSend(_:)), for: .touchDown)
        clearButton.addTarget(self, action: #selector(onClickClear(_:)), for: .touchDown)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //  TODO: Need to fix this, causing some issues
        //let disconnectFromDevice = SavedDevicesViewController()
        //navigationController?.pushViewController(disconnectFromDevice, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UART
    override func isInMultiUartMode() -> Bool {
        return BleManager.shared.connectedPeripherals().count > 1
    }
    
    override func setupUart() {
        // Reset colors assigned to peripherals
        let colors = UartStyle.defaultColors()
        colorForPeripheral.removeAll()
        
        // Enable uart
        let localizationManager = LocalizationManager.shared
        if isInMultiUartMode() {            // Multiple peripheral mode
            let blePeripherals = BleManager.shared.connectedPeripherals()
            for (i, blePeripheral) in blePeripherals.enumerated() {
                //  Only want to try to set up uart for devices that have UART available
                print(blePeripheral.name!)
                if blePeripheral.hasUart(){
                    print("Setting up uart for: \(blePeripheral.name!)")
                    colorForPeripheral[blePeripheral.identifier] = colors[i % colors.count]
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
                            
                            if blePeripheral == blePeripherals.last {
                                context.updateUartReadyUI(isReady: true)
                            }
                        }
                    }
                }
            }
        } else if let blePeripheral = blePeripheral {         //  Single peripheral mode
            //  Designate a color for the peripheral
            colorForPeripheral[blePeripheral.identifier] = colors.first
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
                    context.updateUartReadyUI(isReady: true)
                }
            }
        }
    }
    
    override func send(message: String) {
        guard let uartData = self.uartData as? UartPacketManager else { DLog("Error send with invalid uartData class"); return }
        
        print("Sending message: \(message)")
        
        //  Check if in multiPeripheralMode
        if isInMultiUartMode(){
            sendCountToPeripherals = 0
            //  Need to send data to the multiple peripherals
            for peripheral in BleManager.shared.connectedPeripherals(){
                if peripheral.isUartEnabled(){
                    uartData.send(blePeripheral: peripheral, text: message)
                }
            }
        }
        else{
            //  Single peripheral mode, send data
            let peripheral = BleManager.shared.connectedPeripherals().first!
            uartData.send(blePeripheral: peripheral, text: message)
        }
    }
    
    //  Mark: - Style
    override func colorForPacket(packet: UartPacket) -> UIColor {
        var color: UIColor?
        if let peripheralId = packet.peripheralId {
            color = colorForPeripheral[peripheralId]
        }
        return color ?? UIColor.black
    }
    
}
