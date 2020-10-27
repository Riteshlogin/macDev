//
//  PlotData+CoreDataProperties.swift
//  
//
//  Created by Samuel Peterson on 10/4/19.
//
//

import Foundation
import CoreData


extension PlotData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlotData> {
        return NSFetchRequest<PlotData>(entityName: "PlotData")
    }
    
    @nonobjc public static func dataToString(data: [[[Double]]]) -> String{
        var dataString = ""
        let plotCount = data.count
        
        //  Grab data points. Format in x,y\nx,y\n...
        for i in 0...plotCount-1{
            let plotData = data[i]
            for d in plotData{
                dataString.append("\(d[0]),\(d[1])\n")
            }
            dataString.append("0\n")
        }
        
        return dataString
    }

    //  This data will be of type: [int][int][int]
    @NSManaged public var data: NSObject

}
