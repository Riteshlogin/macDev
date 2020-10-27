//
//  PersistentData.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 9/23/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class PersistentData: NSObject, NSCoding {
    
    //  Location to store data
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("persistentData")
    
    //  Data to save
    var data: [SavedData]?
    
    func encode(with coder: NSCoder) {
        //  Prepares classes information to be archived
        coder.encode(data, forKey: "persistentData")
    }
    
    required init?(coder: NSCoder) {
        //  Unarchives data, leave as nil if none
        data = coder.decodeObject(forKey: "persistentData") as? [SavedData] ?? nil
    }
    
    public func saveData(id: String, data: String, peripheral: BlePeripheral){
        //  Add a new element to the saved data
        let newData = SavedData()
        //newData.initialize(id: id, data: data, peripheral: peripheral)
        self.data?.append(newData)
        
        //  Save the new data array
        self.save()
    }
    
    public func save(){
        //  As long as there is some data, archive the data
        if data != nil{
            let successfulSave = try? NSKeyedArchiver.archivedData(withRootObject: data!, requiringSecureCoding: false)
                if successfulSave == nil{
                    DLog("Data saved properly")
                }
                else{
                    DLog("Data not saved properly")
                }
            
        }
        
    }

    
    
}
