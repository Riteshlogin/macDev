//
//  SavedData+CoreDataProperties.swift
//  
//
//  Created by Samuel Peterson on 10/4/19.
//
//

import Foundation
import CoreData


extension SavedData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedData> {
        return NSFetchRequest<SavedData>(entityName: "SavedData")
    }

    @NSManaged public var deviceID: UUID
    @NSManaged public var date: String
    @NSManaged public var advertisedName: String
    @NSManaged public var id: String
    @NSManaged public var peripheral: String

    func setup(id: String, peripheral: BlePeripheral) {
        let localizationManager = LocalizationManager.shared
        self.id = id
        self.advertisedName = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        
        //  Keep track of the day the data was saved
        let day = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        date = format.string(from: day)
        
        //  Localize the peripheral name
        self.peripheral = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        
        //  Save the device unique ID
        self.deviceID = peripheral.identifier
    }
}
