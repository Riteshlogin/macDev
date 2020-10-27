//
//  SavedPeripheral+CoreDataProperties.swift
//  
//
//  Created by Samuel Peterson on 10/17/19.
//
//

import Foundation
import CoreData


extension SavedPeripheral {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedPeripheral> {
        return NSFetchRequest<SavedPeripheral>(entityName: "SavedPeripheral")
    }

    @NSManaged public var name: String?
    @NSManaged public var originalName: String?
    @NSManaged public var uuid: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var commands: NSObject?

}
