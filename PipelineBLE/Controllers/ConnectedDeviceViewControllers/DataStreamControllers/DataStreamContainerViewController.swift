//
//  DataStreamContainerViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 11/1/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import Charts

class DataStreamContainerViewController: UIViewController {

    private let pageTitle = "Data Stream"
    var plot: LineChartView = {
        let plot = LineChartView()
        plot.borderLineWidth = 1
        plot.borderColor = .blue
        plot.translatesAutoresizingMaskIntoConstraints = false
        return plot
    }()
    var sliderLabel: UILabel = {
        let label = UILabel()
        label.text = "Width:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var scrollLabel: UILabel = {
        let label = UILabel()
        label.text = "Auto Scroll:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var autoScroll: UISwitch = {
        let scroll = UISwitch()
        scroll.isEnabled = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    var maxEntries: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 5
        slider.maximumValue = 3000
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    var saveButton: UIBarButtonItem!
    var startCommandButton: UIBarButtonItem!
    var stopCommandButton: UIBarButtonItem!
    var exportButton: UIBarButtonItem!
    
    weak var blePeripheral: BlePeripheral?
    fileprivate var dataManager: UartDataManager!
    fileprivate var lineDashForPeripheral = [UUID: [CGFloat]?]()
    fileprivate var startTime: CFAbsoluteTime!
    fileprivate var dataSetForPeripherals = [UUID: [LineChartDataSet]]()
    fileprivate var lastUpdatedData: LineChartDataSet?
    fileprivate var visibleInterval: TimeInterval = 500
    var isAutoScrollEnabled: Bool = true
    var dataCounter: [UUID : Int] = [:]
    var basicDataSet: [UUID:[[[Double]]]] = [ : ]
    var dataSetForPeripheral = [UUID : [LineChartDataSet]]()
    var currentPlot: [UUID : Int] = [:]
    var newestPlot = 0
    var startReading = false
    var plots: PlotPagesView!
    var totalCount = 0
    
    var initialPeripherals: [BlePeripheral] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Set up UI
        configureUI()
        
        //  Initialize Uart data manager
        dataManager = UartDataManager(delegate: self, isRxCacheEnabled: true)
        
        //  Save the initial peripherals
        initialPeripherals = BleManager.shared.connectedPeripherals()
        
        //  Get initial start time
        startTime = CFAbsoluteTimeGetCurrent()
        
        //  Add actions
        maxEntries.addTarget(self, action: #selector(onXScaleValueChanged(_:)), for: .valueChanged)
        autoScroll.addTarget(self, action: #selector(onAutoScrollChanged(_:)), for: .valueChanged)
        
        // UI
        autoScroll.isOn = isAutoScrollEnabled
        plots.isAutoScrollEnabled = isAutoScrollEnabled
        plot.dragEnabled = !isAutoScrollEnabled
        maxEntries.value = Float(visibleInterval)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //  Get UART ready
        setUpUART()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        removeOldDataOnMemoryWarning()
    }
    
    fileprivate func removeOldDataOnMemoryWarning() {
        DLog("removeOldDataOnMemoryWarning")
        for (_, dataSets) in dataSetForPeripherals {
            for dataSet in dataSets {
                dataSet.removeAll(keepingCapacity: false)
            }
        }
        
        //dataSetForPeripheral.removeAll()
    }
    /*
    func testCharts(){
        let data:[[Double]] = [[1,1],[2,3],[4,5]]
        var entries: [ChartDataEntry] = []
        var i = 0
        for d in data{
            
            
            print("Data: x(\(d[0])), y(\(d[1]))")
            entries.append(ChartDataEntry(x: d[0], y: d[1]))
            print("Data: x(\(entries[i].x)), y(\(entries[i].y))")
            i += 1
        }
        let dataSet = LineChartDataSet(entries: entries, label: "Test")
        dataSet.setColor(.red)
        let endData = LineChartData(dataSet: dataSet)
        plot.data = endData
        plot.data?.notifyDataChanged()
        plot.notifyDataSetChanged()
    }*/
    
    //  MARK: - Set up the UI
    func configureUI(){
        //  Initialize the plots
        plots = PlotPagesView()
        plots.translatesAutoresizingMaskIntoConstraints = false
        
        //  Set some initial parameters
        view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
        
        //  Add items to the view
        view.addSubview(plots)
        view.addSubview(scrollLabel)
        view.addSubview(autoScroll)
        view.addSubview(sliderLabel)
        view.addSubview(maxEntries)
        
        //  Add the bar button item
        saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(onClickSave(_:)))
        startCommandButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onClickStart(_:)))
        stopCommandButton = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(onClickStop(_:)))
        exportButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onClickExport(_:)))
        barButtons(running: false)
        
        //  Add plotter view
        var textViewConstraint = navigationController?.navigationBar.frame.height ?? 20
        textViewConstraint += 30
        plots.topAnchor.constraint(equalTo: view.topAnchor, constant: textViewConstraint).isActive = true
        plots.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        plots.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        plots.bottomAnchor.constraint(equalTo: scrollLabel.topAnchor, constant: -5).isActive = true
        
        //  Add scroll label
        genericConstraints(top: plots, middle: scrollLabel, bottom: view, width: false)
        scrollLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        scrollLabel.trailingAnchor.constraint(equalTo: autoScroll.leadingAnchor, constant: -5).isActive = true
        
        //  Add auto scroll slider
        genericConstraints(top: plots, middle: autoScroll, bottom: view, width: false)
        autoScroll.leadingAnchor.constraint(equalTo: scrollLabel.trailingAnchor, constant: 5).isActive = true
        autoScroll.trailingAnchor.constraint(equalTo: sliderLabel.leadingAnchor, constant: -5).isActive = true
        
        //  Add max entries slider label
        genericConstraints(top: plots, middle: sliderLabel, bottom: view, width: true)
        sliderLabel.leadingAnchor.constraint(equalTo: autoScroll.trailingAnchor, constant: 5).isActive = true
        sliderLabel.trailingAnchor.constraint(equalTo: maxEntries.leadingAnchor, constant: -5).isActive = true
        
        //  Add the slider for max entries
        genericConstraints(top: plots, middle: maxEntries, bottom: view, width: false)
        maxEntries.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        maxEntries.leadingAnchor.constraint(equalTo: sliderLabel.trailingAnchor, constant: 5).isActive = true
        
        //  Initialize plots and layout so the constraints are immadiately avaialable
        //plots.setNeedsLayout()
        //plots.layoutIfNeeded()
        //plots.initialize()
    }
    
    func genericConstraints(top: UIView, middle: UIView, bottom: UIView, width: Bool){
        //  Automatically apply generic constraints for top and bottom
        middle.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 5).isActive = true
        middle.bottomAnchor.constraint(equalTo: bottom.bottomAnchor, constant: -10).isActive = true
        if width {
            middle.widthAnchor.constraint(equalToConstant: middle.intrinsicContentSize.width).isActive = true
        }
    }
    
    func barButtons(running: Bool){
        //  Change the bar buttons according to whether or not we are running
        if running {
            navigationItem.setRightBarButtonItems([stopCommandButton,saveButton,exportButton], animated: true)
        }
        else{
            navigationItem.setRightBarButtonItems([startCommandButton,saveButton,exportButton], animated: true)
        }
    }
    
    func setUpChart(){
        //  Initialize the chart
        plot.delegate = self
        //plot.backgroundColor = .white
        plot.chartDescription?.enabled = false
        plot.xAxis.granularityEnabled = true
        plot.xAxis.granularity = 5
        plot.leftAxis.drawZeroLineEnabled = true
        //plot.setExtraOffsets(left: 10, top: 10, right: 10, bottom: 0)
        plot.legend.enabled = false
        plot.noDataText = "No data received"
    }
    
    func isInMultiUartMode() -> Bool {
        return BleManager.shared.connectedPeripherals().count > 1
    }
    
    func setUpUART(){
        //  Assign lines for the peripheral
        let lineDashes = UartStyle.defaultLineDashes()
        lineDashForPeripheral.removeAll()
        
        if isInMultiUartMode() {            // Multiple peripheral mode
            let blePeripherals = BleManager.shared.connectedPeripherals()
            for (i, blePeripheral) in blePeripherals.enumerated() {
                if blePeripheral.hasUart(){
                    lineDashForPeripheral[blePeripheral.identifier] = lineDashes[i % lineDashes.count]
                    blePeripheral.uartEnable(uartRxHandler: dataManager.rxDataReceived) { [weak self] error in
                        guard let context = self else { return }

                        let peripheralName = blePeripheral.name ?? blePeripheral.identifier.uuidString
                        DispatchQueue.main.async {
                            guard error == nil else {
                                DLog("Error initializing uart")
                                context.dismiss(animated: true, completion: { [weak self] () -> Void in
                                    if let context = self {
                                        let localizationManager = LocalizationManager.shared
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
                    //  Initialize the data counter for the peripheral
                    self.dataCounter[blePeripheral.identifier] = 0
                    self.currentPlot[blePeripheral.identifier] = 0
                    self.basicDataSet[blePeripheral.identifier] = [[]]
                }
            }
        } else if let blePeripheral = BleManager.shared.connectedPeripherals().first {
            //  Assign a line for the peripheral
            lineDashForPeripheral[blePeripheral.identifier] = lineDashes.first!
            
            //  Enable UART for the peripheral
            blePeripheral.uartEnable(uartRxHandler: dataManager.rxDataReceived) { [weak self] error in
                guard let context = self else { return }

                DispatchQueue.main.async {
                    guard error == nil else {
                        DLog("Error initializing uart")
                        context.dismiss(animated: true, completion: { [weak self] in
                            guard let context = self else { return }
                            let localizationManager = LocalizationManager.shared
                            showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("uart_error_peripheralinit"))
                            
                            if let blePeripheral = context.blePeripheral {
                                BleManager.shared.disconnect(from: blePeripheral)
                            }
                        })
                        return
                    }

                    // Done
                    DLog("Uart enabled")
                }
            }
            //  Initialize the data counter for the peripheral
            self.dataCounter[blePeripheral.identifier] = 0
            self.currentPlot[blePeripheral.identifier] = 0
            self.basicDataSet[blePeripheral.identifier] = [[]]
        } else{
            //  Provide a warning that uart wasn't enabled
            let alert = UIAlertController(title: "Alert", message: "Unable to initialize UART. Please try again. If the problem persists, please report this issue.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
            //  Log the error
            DLog("Unable to initialize UART")
        }
    }
    
    func addEntry(peripheral: UUID, x: Double, y: Double, index: Int){
        //  Create a new data entry
        let entry = ChartDataEntry(x: x, y: y)
        
        print("Here \(currentPlot), \(basicDataSet.count), \(index), \(dataSetForPeripheral.count)")
        
        //  Make sure that the data set exists
        if let dataSets = dataSetForPeripheral[peripheral], dataSets.count > currentPlot[peripheral]!, index < dataSets.count{
            let dataSet = dataSets[index]
            dataSet.append(entry)
        }
        else{
            //  Data set doesnt exist yet, need to create a new one
            addDataSet(peripheral: peripheral, entry: entry)
            
            //  Send the new data to the plot controller to update
            var allData: [LineChartDataSet]? = []
            for (uuid, _) in dataSetForPeripheral {
                //  Need to get the data set for each peripheral at the given index
                print("Here")
                if let dataSetForPeripheral = dataSetForPeripheral[uuid], index < dataSetForPeripheral.count {
                    //  It has the necessary data, so now need to append it
                    print("Here2")
                    if allData == [] {
                        allData = [dataSetForPeripheral[index]]
                        print("Here3")
                    }
                    else {
                        allData!.append(dataSetForPeripheral[index])
                        print("Here4")
                    }
                }
            }
            
            //let allData = dataSetForPeripheral[peripheral]![index]
            DispatchQueue.main.async {
                self.plots.addDataSet(plotNum: index, allData: allData!)
            }
        }
        
        
        guard index < dataSetForPeripheral[peripheral]!.count else { return }
        let dataSet = dataSetForPeripheral[peripheral]![index]
        
        lastUpdatedData = dataSet
        plots.lastUpdatedData = lastUpdatedData
    }
    
    func addDataSet(peripheral: UUID, entry: ChartDataEntry){
        //  Create a new data set
        let newDataSet = LineChartDataSet(entries: [entry], label: "Values for \(currentPlot) plot]")
        let _ = newDataSet.append(entry)
        
        //  Get an int to use for finding a color
        let colorCount = Int(lineDashForPeripheral[peripheral]!?.first ?? 0)
        
        //  Add some preferences
        newDataSet.drawCirclesEnabled = false
        newDataSet.drawValuesEnabled = false
        newDataSet.lineWidth = 2
        let colors = UartStyle.defaultColors()
        let color = colors[colorCount % colors.count]
        newDataSet.setColor(color)
        newDataSet.lineDashLengths = lineDashForPeripheral[peripheral]!
        DLog("color: \(color.hexString()!)")
        
        //  Add the new data set to current data set
        DLog("Added new dataset for new graph")
        if dataSetForPeripheral[peripheral] != nil {
            dataSetForPeripheral[peripheral]!.append(newDataSet)
        }
        else{
            dataSetForPeripheral[peripheral] = [newDataSet]
        }
    }
    /*
    func addEntry(peripheral: UUID, index: Int, value: Double, timestamp: CFAbsoluteTime){
        //  Create initial entry
        let entry = ChartDataEntry(x: timestamp, y: value)
        
        // See if the data set exists. If it does add, otherwise create new dataset
        if let dataSets = dataSetForPeripherals[peripheral], index < dataSets.count{
            //  We know that the current dataset exists, add the data
            let dataSet = dataSets[index]
            let _ = dataSet.append(entry)
        }
        else{
            self.addDataSet(peripheral: peripheral, index: index, entry: entry)
            
            //  Update the data for the graph
            let allData = dataSetForPeripherals.flatMap {$0.1}
            DispatchQueue.main.async {
                self.plot.data = LineChartData(dataSets: allData)
            }
        }

        
        guard let dataSets = dataSetForPeripherals[peripheral], index < dataSets.count else { return }
        
        lastUpdatedData = dataSets[index]
    }
    
    func addDataSet(peripheral: UUID, index: Int, entry: ChartDataEntry){
        //  Create a new data set and add it to existing data
        let newDataSet = LineChartDataSet(entries: [entry], label: "Values[ \(peripheral.uuidString) : \(index)]")
        let _ = newDataSet.append(entry)
        
        newDataSet.drawCirclesEnabled = false
        newDataSet.drawValuesEnabled = false
        newDataSet.lineWidth = 2
        let colors = UartStyle.defaultColors()
        let color = colors[index % colors.count]
        newDataSet.setColor(color)
        newDataSet.lineDashLengths = lineDashForPeripheral[peripheral]!
        DLog("color: \(color.hexString()!)")
        
        //  Add the new data set to current data set
        if dataSetForPeripherals[peripheral] != nil{
            dataSetForPeripherals[peripheral]?.append(newDataSet)
        }
        else{
            //  No current data set, so just create new for peripheral
            dataSetForPeripherals[peripheral] = [newDataSet]
        }
    }*/
    
    func notifyDataSetChanged(){
        plots.notifyDataSetChanged()
        /*
        //  Signal that the data and the data set changed
        plot.data?.notifyDataChanged()
        plot.notifyDataSetChanged()
        
        
        //  Make sure the visible range is accurate
        plot.setVisibleXRangeMaximum(visibleInterval)
        plot.setVisibleXRangeMinimum(visibleInterval)
        
        guard let dataSet = lastUpdatedData else { return }

        //  Need to adjust view depending on autoscroll
        if isAutoScrollEnabled {
            //let xOffset = Double(dataSet.entryCount) - (context.numEntriesVisible-1)
            let xOffset = (dataSet.entries.last?.x ?? 0) - (visibleInterval-1)
            plot.moveViewToX(xOffset)
        }*/
    }
    
    //  MARK: - UI Actions
    @objc func onXScaleValueChanged(_ sender: UISlider) {
        //  Update our track of the intervale and sent to the plots
        visibleInterval = TimeInterval(sender.value)
        plots.updateSlider(slider: visibleInterval)
        
        //  Make sure we have started reading data before trying to update
        if !startReading {return}
        
        DispatchQueue.main.async {
            self.notifyDataSetChanged()
        }
    }
    
    @objc func onAutoScrollChanged(_ sender: Any) {
        //  Update the autoscroll and send to plots
        isAutoScrollEnabled = !isAutoScrollEnabled
        plot.dragEnabled = !isAutoScrollEnabled
        plots.updateAutoScroll()
        
        DispatchQueue.main.async {
            self.notifyDataSetChanged()
        }
    }
    
    @objc func onClickSave(_ save: UIBarButtonItem){
        //  Create alert and text to display
        let alert = UIAlertController(title: "Save Data Stream", message: "Please enter an identifier for the data:", preferredStyle: .alert)
        alert.addTextField{ (textField) in
            textField.placeholder = "identifier"
        }
        
        //  Create action for when the button is saved
        let action = UIAlertAction(title: "Save", style: .default){ (_) in
            for peripheral in self.initialPeripherals {
                //  Make sure we save data for the peripheral if it was connected
                if let dataSet = self.basicDataSet[peripheral.identifier] {
                    //  Populate data with the dataSet
                    let data = PlotData(context: PersistenceService.context)
                    
                    data.data = dataSet as NSObject
                    let id = alert.textFields!.first!.text ?? ""
                    data.setup(id: id, peripheral: peripheral)
                    PersistenceService.saveContext()
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        //  Add the two actions
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        //  Present the view controller
        self.present(alert, animated: true, completion: nil)
        
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
            
            //  Unlock autoscroll
            self.autoScroll.isEnabled = true
            
            //  Now we we have the number of runs, so set up the graphs
            self.plots.initialize(count: runs)
            
            //  Now we can start reading data in
            self.startReading = true
            
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
    
    @objc func onClickStop(_ stop: UIBarButtonItem){
        //  To warn the user that they are about to stop
        let alert = UIAlertController(title: "Stop Data Stream", message: "Are you sure you want to tell the device to stop sending data?", preferredStyle: .alert)
        let action = UIAlertAction(title: "Yes", style: .default){ (_) in
            //  Need to send the device the message to stop
            for peripheral in BleManager.shared.connectedPeripherals(){
                self.send(message: "s", peripheral: peripheral)
                self.barButtons(running: false)
            }
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(actionCancel)
        self.present(alert, animated: true, completion: nil)
    }

    @objc func onClickExport(_ export: UIBarButtonItem){
        //  Export button was pressed, call the export button class
        ExportData.exportData(view: self, button: exportButton, data: basicDataSet as NSObject)
    }

}

//  MARK: - UARTDataManager Delegate
extension DataStreamContainerViewController: UartDataManagerDelegate{
    //  Byte buffer
    private static let kLineSeparator = Data([10])
    
    //  What to do when data is received
    func onUartRx(data: Data, peripheralIdentifier: UUID) {
        //  Store the data in the byte buffer
        guard let lastSeparatorRange = data.range(of: DataStreamContainerViewController.kLineSeparator, options: [.anchored,.backwards], in: nil) else { return }
        
        //  Make sure that we can start reading in data
        if !startReading {
            dataManager.removeRxCacheFirst(n: lastSeparatorRange.upperBound+1, peripheralIdentifier: peripheralIdentifier)
            return
        }

        let subData = data.subdata(in: 0..<lastSeparatorRange.upperBound)
        if let dataString = String(data: subData, encoding: .utf8) {
            //  Now need to clean the data of the extra characters
            let strings = dataString.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n") // ["100,100,100"],["10,10,10"]...
            
            //  Here we are making current time equal to data counter so all data pts are evenly spread out
            //let currentTime = CFAbsoluteTimeGetCurrent() - startTime
            
            //  Need to look through each line of strings
            DispatchQueue.main.async {
                for line in strings {
                    //  Will need to grab all data from each line
                    let dataPoints = line.components(separatedBy: CharacterSet(charactersIn: ",; "))
                    var i = 0
                    
                    for pt in dataPoints{
                        //  Need to create the new data point and add to set
                        if let val = Double(pt){
                            print("\(i). Value: \(val)")
                            //  Check to see if the point is 0, then we know it is a new plot and increase
                            if let dataSet = self.basicDataSet[peripheralIdentifier], dataSet.count == 0 && val == 0{
                                // Just continue and not do anything
                                print("Nothing here")
                            }
                            else if self.currentPlot[peripheralIdentifier]! >= self.plots.maxPlots{
                                //  Done reading data in, ignore the rest
                                return
                            }
                            else if val != 0{
                                //  Make sure data is even spread
                                let currentTime = self.dataCounter[peripheralIdentifier]!
                                
                                //addEntry(peripheral: peripheralIdentifier, index: i, value: val, timestamp: Double(currentTime))
                                print("Total Count: \(self.totalCount)")
                                self.addEntry(peripheral: peripheralIdentifier, x: Double(currentTime), y: val,index: Int(self.currentPlot[peripheralIdentifier]!))
                                self.totalCount += 1
                                
                                //  Check to see if this is a new dataset we need to add
                                let dataSetCount = self.basicDataSet[peripheralIdentifier] == nil ? 0 : self.basicDataSet[peripheralIdentifier]!.count
                                if dataSetCount == self.currentPlot[peripheralIdentifier]!, self.currentPlot[peripheralIdentifier] != 0{
                                    //  Add the new data to the new plot
                                    self.basicDataSet[peripheralIdentifier]!.append([])
                                self.basicDataSet[peripheralIdentifier]![self.currentPlot[peripheralIdentifier]!].append([Double(currentTime), val])
                                }
                                else{
                                    //  Just add data regularly
                                self.basicDataSet[peripheralIdentifier]![self.currentPlot[peripheralIdentifier]!].append([Double(currentTime), val])
                                }
                                
                                self.dataCounter[peripheralIdentifier]! += 1
                                i = i + 1
                            }
                            else {
                                //  Okay, new data set for the new graph
                                print("Zero")
                                self.currentPlot[peripheralIdentifier]! += 1
                                self.dataCounter[peripheralIdentifier] = 0
                                
                                //  If the new plot is after all the other plots, move to the new page.
                                //  This will prevent moving backwards
                                if self.currentPlot[peripheralIdentifier]! > self.newestPlot {
                                    self.newestPlot = self.currentPlot[peripheralIdentifier]!
                                    DispatchQueue.main.async {
                                        self.plots.changePage(toPage: self.currentPlot[peripheralIdentifier]!)
                                    }
                                }
                            }
                        }
                    }
                    //  Need to update the graph
                    self.enh_throttledReloadData()
                    //DispatchQueue.main.async {
                        //self.notifyDataSetChanged()
                    //}
                }
            }
        }
        
        dataManager.removeRxCacheFirst(n: lastSeparatorRange.upperBound, peripheralIdentifier: peripheralIdentifier)
    }
    
    @objc func reloadData(){
        DispatchQueue.main.async {
            self.notifyDataSetChanged()
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
    
    
}

extension DataStreamContainerViewController: ChartViewDelegate{
    
}
