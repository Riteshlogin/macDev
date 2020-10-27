//
//  SavedDevicesTableViewCell.swift
//  PipelineAnalysis
//
//  Created by Samuel Peterson on 7/29/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class SavedDevicesTableViewCell: UITableViewCell {
    
    public let deviceName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Hello World"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //  Set constraints
        SetUpConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func SetUpConstraints(){
        //  Add the label to the cell
        addSubview(deviceName)
        
        //  Add constraints to the label
        deviceName.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        deviceName.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        deviceName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        deviceName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
 
        
    }
    
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }*/

    /*override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }*/

}
