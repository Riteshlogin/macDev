//
//  ExportData.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 10/28/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import Foundation

class ExportData {
    
    static let acceptedFormats = ["txt"/*,"csv"*/]
    
    //  Use this method to export string data
    static func exportData(view: UIViewController, button: UIBarButtonItem, data: NSObject){
        //  First, lets get the filename
        var filename = "ExportData"
        
        //  Create an alert to display the options
        let alert = UIAlertController(title: "Export Filename", message: "Choose a name for the file:", preferredStyle: .alert)
        alert.addTextField{(textField) in
            textField.placeholder = "Filename (w/o extension)"
        }
        
        let action = UIAlertAction(title: "Done", style: .default){ (_) in
            filename = alert.textFields!.first!.text ?? filename
            exportData(view: view, button: button, data: data, filename: filename)
        }
            
        //  Need to add a cancel button
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelButton)
        alert.addAction(action)
        
        //  Now present the alert
        view.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    static func exportData(view: UIViewController, button: UIBarButtonItem, data: NSObject, filename: String){
        //  Create an alert to display the options
        let alert = UIAlertController(title: "Export Format", message: "Choose format style:", preferredStyle: .actionSheet)
            
        for format in acceptedFormats{
            let action = UIAlertAction(title: format, style: .default){ (_) in
                //  Get the data string that will be presented
                let exportData = parseData(data: data, type: format)
                    
                //  Now export and display the view
                exportWithView(view: view, exportButton: button, object: exportData, filename: filename, format: format)
            }
                
            //  Finally add action
            alert.addAction(action)
        }
            
        //  Need to add a cancel button
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelButton)
            
        //  Now present the alert
        alert.popoverPresentationController?.barButtonItem = button
        view.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate static func parseData(data: NSObject, type: String) -> String?{
        //  First, find what type of data we are dealing with
        if let data = data as? [[[Double]]] {
            //  We have Plot data, so will have to convert and return
            if type == "txt"{
                return PlotData.dataToString(data: data)
            }
            else {
                //  TODO: - Implement csv and others
            }
        }
        else if let data = data as? String {
            //  We have UART data, so we can just return as string, convert for others
            if type == "txt"{
                return data
            }
            else {
                //  TODO: - Implement csv and others
            }
        }
        else if let dataSets = data as? [UUID : [[[Double]]]]{
            //  Check the formatting to be returned
            if type == "txt"{
                //  Build the string to return
                var deviceNumber = 1
                var output = ""
                for (uuid, dataSet) in dataSets {
                    //  Display what the device is
                    output += "Device \(deviceNumber): \(uuid.uuidString)\n"
                    output += PlotData.dataToString(data: dataSet)
                    
                    //  Increment the device number when done
                    deviceNumber += 1
                }
                return output
            }
        }
        //  All fails, so return nil
        return nil
    }
    
    fileprivate static func exportWithView(view: UIViewController, exportButton: UIBarButtonItem, object: String?, filename: String?, format: String) {
        //  Create the path to save at
        let file = "\(filename ?? "ExportData")."+format
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file)
        do{
            //  Try writing the string to the given file
            try (object ?? "").write(to: path!, atomically: true, encoding: .utf8)
        } catch {
            //  Didn't work for some reason...
        }
        
        let activityViewController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = exportButton
        //activityViewController.popoverPresentationController?.barb = exportButton.bounds
            
        view.navigationController?.present(activityViewController, animated: true, completion: nil)
    }
    
    
}
