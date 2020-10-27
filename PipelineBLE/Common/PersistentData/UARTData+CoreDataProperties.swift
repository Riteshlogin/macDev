//
//  UARTData+CoreDataProperties.swift
//  
//
//  Created by Samuel Peterson on 10/4/19.
//
//

import Foundation
import CoreData


extension UARTData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTData> {
        return NSFetchRequest<UARTData>(entityName: "UARTData")
    }

    @NSManaged public var data: String

}
